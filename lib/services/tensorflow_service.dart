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
    'person': ['人間', Size(640, 360)],
    'chair': ['椅子', Size(300, 150)],
    'keyboard': ['キーボード', Size(40, 70)],
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

  void checkDetectedObjectSize(List<dynamic>? recognitions, int imageWidth,
      int imageHeight, Function noticeFunction, String targetKeyword) {
    for (var obj in recognitions!) {
      var label = obj['detectedClass'];
      if (predefinedObj.containsKey(label)) {
        print(
            '---------------checkDetectedObjectSize recognition: $obj.toString()');
        var predefinedSize = predefinedObj[label]?[1];
        var width = obj['rect']['w'] * imageWidth;
        var height = obj['rect']['h'] * imageHeight;

        if (width > predefinedSize?.width || height > predefinedSize?.height) {
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
          noticeFunction(predefinedObj[label], direction, targetKeyword);
        }
      }
    }
    // 前回の結果と新しい結果を比較
    if (_previousRecognitions != null &&
        recognitions.toString() == _previousRecognitions.toString()) {
      // 前回の結果と同じ場合、何もしない
      duplicateFlag = true;
      return null;
    } else {
      duplicateFlag = false;
    }

    _previousRecognitions = recognitions; // 結果を更新
  }
}
