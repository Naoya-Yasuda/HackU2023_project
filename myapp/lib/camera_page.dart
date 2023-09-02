import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
        _cameras![_selectedCameraIndex], ResolutionPreset.high);
    _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: CameraPreview(_controller!),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.switch_camera),
        onPressed: _switchCamera,
      ),
    );
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;

    CameraDescription selectedCamera = _cameras![_selectedCameraIndex];
    _controller = CameraController(selectedCamera, ResolutionPreset.high);

    _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
