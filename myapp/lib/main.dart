import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Object Classification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  Interpreter? interpreter;
  String? label;
  List<String>? labels; // ラベルリストをクラス変数として追加

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;
      controller = CameraController(camera, ResolutionPreset.medium,
          imageFormatGroup: ImageFormatGroup.yuv420);
      await controller!.initialize();
      if (!mounted) {
        print('not mounted');
        return;
      }
      setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  _loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(
          'lite-model_imagenet_mobilenet_v3_small_100_224_classification_5_metadata_1.tflite');
      labels = await getLabelsFromAsset(); // モデルの読み込みと同時にラベルも読み込む
      _startCameraStream();
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  _startCameraStream() {
    try {
      if (controller != null && controller!.value.isInitialized) {
        controller!.startImageStream((image) => _processImage(image));
      } else {
        print('Camera controller is not initialized');
      }
    } catch (e) {
      print("Error starting camera stream: $e");
    }
  }

  // assets/labels.txtからラベルを取得する関数
  Future<List<String>> getLabelsFromAsset() async {
    try {
      String data = await rootBundle.loadString('assets/labels.txt');
      return data.split('\n');
    } catch (e) {
      print("Error loading labels: $e");
      return [];
    }
  }

  _processImage(CameraImage image) async {
    print('_processImage start');
    try {
      if (interpreter == null) {
        print('Interpreter is not initialized');
        return;
      }

      img.Image rgbImage = _convertYUV420ToRGB(image);
      img.Image resizedImage =
          img.copyResize(rgbImage, width: 224, height: 224);
      Float32List modelInput = _imageToFloat32List(resizedImage);

      Float32List outputBuffer = Float32List(1000);
      interpreter!.run(modelInput, outputBuffer);

      final predictedLabelIndex = outputBuffer
          .indexWhere((probability) => probability == outputBuffer.reduce(max));

      List<String> labels = await getLabelsFromAsset();

      setState(() {
        label = labels[predictedLabelIndex];
        print('Detected label: $label');
      });
    } catch (e) {
      print("Error processing image: $e");
    }
  }

  img.Image _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerRow ~/ width;

    var imageBuffer = img.Image(width, height); // Create Image buffer
    print('imageBuffer:$imageBuffer');

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        // Convert yuv pixel to rgb
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        // Set pixel color
        imageBuffer.setPixel(x, y, img.getColor(r, g, b));
      }
    }
    print('imageBuffer:$imageBuffer');
    return imageBuffer;
  }

  Float32List _imageToFloat32List(img.Image image) {
    print('image:$image');
    var convertedBytes = Float32List(1 * 224 * 224 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = (img.getRed(pixel) - 127.5) / 127.5;
        buffer[pixelIndex++] = (img.getGreen(pixel) - 127.5) / 127.5;
        buffer[pixelIndex++] = (img.getBlue(pixel) - 127.5) / 127.5;
      }
    }
    print('_imageToFloat32List buffer:$buffer');
    return buffer;
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      print('controller not isInitialized in build');
      return Container();
    }
    return Scaffold(
      appBar: AppBar(title: Text('Object Classification')),
      body: Stack(
        children: <Widget>[
          CameraPreview(controller!),
          if (label != null && label!.isNotEmpty) ...[
            Positioned(
              bottom: 10,
              child: Text('Detected: $label',
                  style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    controller?.stopImageStream(); // カメラストリームを停止
    super.dispose();
  }
}
