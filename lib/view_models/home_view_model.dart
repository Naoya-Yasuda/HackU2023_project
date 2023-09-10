import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_object_detection/app/base/base_view_model.dart';
import '/models/recognition.dart';
import 'package:flutter_realtime_object_detection/services/tensorflow_service.dart';
import 'package:flutter_realtime_object_detection/view_states/home_view_state.dart';
import 'package:flutter_realtime_object_detection/services/speech_to_text_service.dart';

class HomeViewModel extends BaseViewModel<HomeViewState> {
  bool _isDetecting = false;
  bool _isLoadModel = false;
  bool _isListening = false;

  late TensorFlowService _tensorFlowService;

  final SpeechToTextService _speechService = SpeechToTextService();

  String? _targetKeyword;

  String? get recognizedText => _targetKeyword;
  HomeViewModel(BuildContext context, this._tensorFlowService)
      : super(context, HomeViewState(_tensorFlowService.type));

  // New methods for speech recognition
  Future<void> startListening() async {
    _isListening = true;
    await _speechService.startListening();
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speechService.stopListening();
    _targetKeyword = _speechService.getRecognizedText();
    print(_targetKeyword);
    // TODO: 目標が検知されたら、音声を再生する
    notifyListeners(); // To update the UI if needed
  }

  Future switchCamera() async {
    state.cameraIndex = state.cameraIndex == 0 ? 1 : 0;
    this.notifyListeners();
  }

  Future<void> loadModel(ModelType type) async {
    state.type = type;
    //if (type != this._tensorFlowService.type) {
    await this._tensorFlowService.loadModel(type);
    //}
    this._isLoadModel = true;
  }

  Future<void> runModel(CameraImage cameraImage) async {
    print('---- cameraImage -----:' + cameraImage.toString());
    if (_isLoadModel && mounted) {
      if (!this._isDetecting && mounted) {
        this._isDetecting = true;
        int startTime = new DateTime.now().millisecondsSinceEpoch;
        var recognitions =
            await this._tensorFlowService.runModelOnFrame(cameraImage);
        int endTime = new DateTime.now().millisecondsSinceEpoch;
        print('Time detection: ${endTime - startTime}');
        if (recognitions != null && mounted) {
          state.recognitions = List<Recognition>.from(
              recognitions.map((model) => Recognition.fromJson(model)));
          state.widthImage = cameraImage.width;
          state.heightImage = cameraImage.height;
          print('---- state -----:' + recognitions.toString());
          notifyListeners();
        }
        this._isDetecting = false;
      }
    } else {
      print(
          'Please run `loadModel(type)` before running `runModel(cameraImage)`');
    }
  }

  Future<void> close() async {
    await this._tensorFlowService.close();
  }

  void updateTypeTfLite(ModelType item) {
    this._tensorFlowService.type = item;
  }
}
