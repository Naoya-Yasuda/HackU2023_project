import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';

enum ModelType { YOLO, SSDMobileNet, MobileNet, PoseNet }

class TensorFlowService {
  ModelType _type = ModelType.YOLO;
  List<dynamic>? _previousRecognitions; //テスト
  ModelType get type => _type;
  Map<String, List<dynamic>> recognitions10times = {};
  num frameCount = 0;
  Map<String, dynamic>? predefinedObj;

  Future<Map<String, dynamic>> loadPredefinedObj() async {
    final jsonString = await rootBundle.loadString('assets/data.json');
    print(jsonString);
    return json.decode(jsonString)['predefinedObj'];
  }

  Future<void> initialize() async {
    predefinedObj = await loadPredefinedObj();
    print('predefinedObj:' + predefinedObj.toString());
  }

  set type(type) {
    _type = type;
  }

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
    for (var obj in recognitions!) {
      var label = obj['detectedClass'];
      var confidence = obj['confidenceInClass'];

      if (confidence >= 0.27) {
        if (recognitions10times.containsKey(label)) {
          recognitions10times[label]!.add(obj);
        } else {
          recognitions10times[label] = [obj];
        }
      }
    }
    print('runModelOnFrame2 recognitions10times:' +
        recognitions10times.toString());
    frameCount++;
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

  Future<bool> checkDetectedObjectSize(int imageWidth, int imageHeight,
      Function noticeFunction, String targetKeyword, CameraImage image) async {
    var isGoal = false;
    if (frameCount > 8) {
      for (var item in recognitions10times.entries) {
        var label = item.key;
        var list = recognitions10times[label];

        // 各信頼度を10倍したものを足し、都度乗算したものをスコアとする
        var score = 0.0;
        for (var obj in list!) {
          print('obj in list :' + obj.toString());
          score += obj['confidenceInClass'] * 10;
          score *= score;
        }
        print('score :' + score.toString());

        // スコアから成功判定
        if (score >= 14.0) {
          // 一番新しい物体情報を取得
          var lastObj = list.last;
          var trafficLightColor = '';
          if (predefinedObj!.containsKey(label)) {
            if (label == 'traffic light') {
              print('label == traffic light');
              trafficLightColor = detectTrafficLightColor(image);
            }
            print(
                '---------------checkDetectedObjectSize recognition: $lastObj');
            print(
                '---------------checkDetectedObjectSize recognition2: ${predefinedObj![label].toString()}');
            var predefinedSize = predefinedObj![label]?[1];
            var width = lastObj['rect']['w'] * imageWidth;
            var height = lastObj['rect']['h'] * imageHeight;

            if (width > predefinedSize?["width"] ||
                height > predefinedSize?["height"] ||
                label == 'traffic light') {
              // 検知物体の方向を判定する
              double objectCenterX =
                  lastObj['rect']['x'] + lastObj['rect']['w'] / 2;
              String direction;
              if (objectCenterX < 0.35) {
                direction = '左前';
              } else if (objectCenterX > 0.65) {
                direction = '右前';
              } else {
                direction = '目の前';
              }
              // 目標到達の場合はフラグを立てる
              isGoal = !await noticeFunction(predefinedObj![label], direction,
                  targetKeyword, trafficLightColor);
            }
          }
        }
      }
      // リセット
      frameCount = 0;
      recognitions10times = {};
    }
    // // 前回の結果と新しい結果を比較
    // if (_previousRecognitions != null &&
    //     recognitions.toString() == _previousRecognitions.toString()) {
    //   // 前回の結果と同じ場合、何もしない
    //   duplicateFlag = true;
    // } else {
    //   duplicateFlag = false;
    //   _previousRecognitions = recognitions; // 結果を更新
    // }

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
