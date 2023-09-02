import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    controller = CameraController(camera, ResolutionPreset.medium);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      controller!.startImageStream((image) => _processImage(image));
    });
  }

  _loadModel() async {
    interpreter = await Interpreter.fromAsset(
        'lite-model_imagenet_mobilenet_v3_small_100_224_classification_5_metadata_1.tflite');
  }

  Float32List _convertYUV420ToNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    var nv21 = Uint8List(width * height * 3 ~/ 2);

    var yData = image.planes[0].bytes;
    var uData = image.planes[1].bytes;
    var vData = image.planes[2].bytes;

    int uvIndex = 0;
    int index = width * height;

    for (int i = 0; i < width * height; i++) {
      nv21[i] = yData[i];

      if (i % 2 == 0) {
        nv21[index++] = vData[uvIndex];
        nv21[index++] = uData[uvIndex];
        uvIndex++;
      }
    }

    return nv21.buffer.asFloat32List();
  }

// assets/labels.txtからラベルを取得する関数
  Future<List<String>> getLabelsFromAsset() async {
    String data = await rootBundle.loadString('assets/labels.txt');
    return data.split('\n'); // ラベルは各行に1つずつ存在すると仮定
  }

  _processImage(CameraImage image) async {
    Float32List inputImage = _convertYUV420ToNV21(image);
    Float32List modelInput = Float32List(1 * 224 * 224 * 3);

    for (var i = 0; i < inputImage.length; i++) {
      modelInput[i] = (inputImage[i] - 127.5) / 127.5;
    }

    Float32List outputBuffer = Float32List(1000);

    interpreter!.run(modelInput, outputBuffer);

    final predictedLabelIndex = outputBuffer
        .indexWhere((probability) => probability == outputBuffer.reduce(max));

    List<String> labels = await getLabelsFromAsset(); // ラベルをassetsから取得

    setState(() {
      label = labels[predictedLabelIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(title: Text('Object Classification')),
      body: Stack(
        children: <Widget>[
          CameraPreview(controller!),
          if (label != null) ...[
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
    super.dispose();
  }
}
