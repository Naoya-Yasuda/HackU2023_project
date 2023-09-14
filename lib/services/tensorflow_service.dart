import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;
// import 'tts_notifier_service.dart';
import 'audio_service.dart';

enum ModelType { YOLO, SSDMobileNet, MobileNet, PoseNet }

class TensorFlowService {
  ModelType _type = ModelType.YOLO;
  List<dynamic>? _previousRecognitions; //テスト
  ModelType get type => _type;
  // String _targetKeyword = '';
  // TensorFlowService(String targetKeyword) {
  //   this._targetKeyword = targetKeyword;
  // }

  // late final TTSNotifier ttsNotifier = TTSNotifier(_targetKeyword); // lateを使う

  set type(type) {
    _type = type;
  }

  // 事前に定義された各ラベルのサイズの閾値
  // TODO: resource.dartに移動予定
  Map<String, List<dynamic>> predefinedObj = {
    'car': ['車', Size(640, 360)],
    'person': ['人間', Size(640, 360)],
    'chair': ['椅子', Size(300, 150)],
    'keyboard': ['キーボード', Size(40, 70)],
    'traffic light': ['信号機', Size(40, 70)],
    // 他のラベルとサイズを追加できます
  };

  loadModel(ModelType type) async {
    try {
      Tflite.close();
      String? res;
      switch (type) {
        case ModelType.YOLO:
          res = await Tflite.loadModel(
              model: 'assets/models/yolov2_tiny.tflite',
              labels: 'assets/models/yolov2_tiny.txt');
          break;
        case ModelType.SSDMobileNet:
          res = await Tflite.loadModel(
              model: 'assets/models/ssd_mobilenet.tflite',
              labels: 'assets/models/ssd_mobilenet.txt');
          break;
        case ModelType.MobileNet:
          res = await Tflite.loadModel(
              model: 'assets/models/mobilenet_v1.tflite',
              labels: 'assets/models/mobilenet_v1.txt');
          break;
        case ModelType.PoseNet:
          res = await Tflite.loadModel(
              model: 'assets/models/posenet_mv1_checkpoints.tflite');
          break;
        default:
          res = await Tflite.loadModel(
              model: 'assets/models/yolov2_tiny.tflite',
              labels: 'assets/models/yolov2_tiny.txt');
      }
      print('loadModel: $res - $_type');
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  close() async {
    await Tflite.close();
  }

  Future<List<dynamic>?> runModelOnFrame(CameraImage image) async {
    List<dynamic>? recognitions = <dynamic>[];
    print('runModelOnFrame1:');
    // TODO: ご検知対策
    recognitions = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      model: "YOLO",
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 0,
      imageStd: 255.0,
      threshold: 0.2,
      numResultsPerClass: 1,
    );
    // checkDetectedObjectSize(recognitions, image.width, image.height);
    print('runModelOnFrame2:' + recognitions.toString());
    for (var obj in recognitions!) {
      var label = obj['detectedClass'];
      var confidence = obj['confidenceInClass'];
    }
    return recognitions;
  }

  Uint8List convertCameraImageToUint8List(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    var img = Uint8List(width * height * 3);
    var buffer = img.buffer.asByteData();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int pixelIndex = y * width + x;
        final int bufferIndex = pixelIndex * 3;

        final int r = image.planes[0].bytes[pixelIndex];
        final int g = image.planes[1].bytes[pixelIndex];
        final int b = image.planes[2].bytes[pixelIndex];

        buffer.setUint8(bufferIndex, r);
        buffer.setUint8(bufferIndex + 1, g);
        buffer.setUint8(bufferIndex + 2, b);
      }
    }
    return img;
  }

  Uint8List resizeImage(Uint8List image, int width, int height) {
    img.Image? originalImage = img.decodeImage(image);
    if (originalImage == null) {
      throw Exception("Failed to decode the image.");
    }

    img.Image resizedImg =
        img.copyResize(originalImage, width: width, height: height);
    return Uint8List.fromList(img.encodePng(resizedImg));
  }

  Future<List<dynamic>?> runModelOnImage(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        model: "YOLO",
        threshold: 0.3,
        imageMean: 0.0,
        imageStd: 127.5,
        numResultsPerClass: 1);
    return recognitions;
  }

  Future<bool> checkDetectedObjectSize(
      List<dynamic>? recognitions,
      int imageWidth,
      int imageHeight,
      Function noticeFunction,
      String targetKeyword,
      CameraImage image,
      num frameCount) async {
    var isGoal = false;
    for (var obj in recognitions!) {
      var label = obj['detectedClass'];
      var trafficLightColor = '';

      if (predefinedObj.containsKey(label)) {
        if (label == 'traffic light') {
          print('label == traffic light');
          trafficLightColor = detectTrafficLightColor(image);
        }
        print(
            '---------------checkDetectedObjectSize recognition: $obj.toString()');
        var predefinedSize = predefinedObj[label]?[1];
        var width = obj['rect']['w'] * imageWidth;
        var height = obj['rect']['h'] * imageHeight;

        if (width > predefinedSize?.width ||
            height > predefinedSize?.height ||
            label == 'traffic light') {
          // 検知物体の方向を判定する
          double objectCenterX = obj['rect']['x'] + obj['rect']['w'] / 2;
          String direction;
          if (objectCenterX < 0.25) {
            direction = '左前';
          } else if (objectCenterX > 0.75) {
            direction = '右前';
          } else {
            direction = '目の前';
          }
          var tempGaolFlag = await noticeFunction(predefinedObj[label],
              direction, targetKeyword, trafficLightColor);
          if (!isGoal && tempGaolFlag) {
            isGoal = true;
          }
        }
        // }
      }
    }
    // 前回の結果と新しい結果を比較
    if (_previousRecognitions != null &&
        recognitions.toString() == _previousRecognitions.toString()) {
      // 前回の結果と同じ場合、何もしない
      duplicateFlag = true;
    } else {
      duplicateFlag = false;
      _previousRecognitions = recognitions; // 結果を更新
    }

    return isGoal;
  }

  String detectTrafficLightColor(CameraImage cameraImage) {
    img.Image image = convertYUV420ToImage(cameraImage);

    // 1. 画像を2つの部分に分割
    var topHalf = img.copyCrop(image, 0, 0, image.width, image.height ~/ 2);
    var bottomHalf = img.copyCrop(
        image, 0, image.height ~/ 2, image.width, image.height ~/ 2);

    // 2. 各部分の平均色を取得
    var topColor = getAverageColor(topHalf);
    var bottomColor = getAverageColor(bottomHalf);

    // 3. 平均色の明るさを比較
    double topBrightness = 0.2126 * topColor.red +
        0.7152 * topColor.green +
        0.0722 * topColor.blue;
    double bottomBrightness = 0.2126 * bottomColor.red +
        0.7152 * bottomColor.green +
        0.0722 * bottomColor.blue;

    print("topBrightness" + topBrightness.toString());
    print("bottomBrightness" + bottomBrightness.toString());

    // 4. 色の判定
    if (topBrightness > bottomBrightness) {
      print("赤信号");
      return "赤";
    } else {
      print("青信号");
      return "青";
    }
  }

  img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final img.Image image = img.Image(width, height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = cameraImage.planes[0].bytes[index];
        final up = cameraImage.planes[1].bytes[uvIndex];
        final vp = cameraImage.planes[2].bytes[uvIndex];

        // Convert YUV to RGB
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        image.setPixelRgba(x, y, r, g, b);
      }
    }
    return image;
  }

  Color getAverageColor(img.Image image) {
    int redSum = 0, greenSum = 0, blueSum = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int pixel = image.getPixel(x, y);
        redSum += img.getRed(pixel);
        greenSum += img.getGreen(pixel);
        blueSum += img.getBlue(pixel);
      }
    }

    int pixelCount = image.width * image.height;
    return Color.fromRGBO(redSum ~/ pixelCount, greenSum ~/ pixelCount,
        blueSum ~/ pixelCount, 1.0);
  }
}
