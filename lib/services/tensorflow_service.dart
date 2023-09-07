import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;

enum ModelType { YOLO, SSDMobileNet, MobileNet, PoseNet }

class TensorFlowService {
  ModelType _type = ModelType.YOLO;

  ModelType get type => _type;

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
}
