import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_object_detection/app/base/base_view_model.dart';
import '../services/tts_notifier_service.dart';
import '/models/recognition.dart';
import 'package:flutter_realtime_object_detection/services/tensorflow_service.dart';
import 'package:flutter_realtime_object_detection/view_states/home_view_state.dart';
import 'package:flutter_realtime_object_detection/services/speech_to_text_service.dart';

class HomeViewModel extends BaseViewModel<HomeViewState> {
  bool _isDetecting = false;
  bool _isLoadModel = false;
  bool _isListening = false;

  late TensorFlowService _tensorFlowService;
  String _recognizedText = "";
  // String? get recognizedText => targetKeyword;

  late SpeechToTextService _speechService;
  late TTSNotifier _ttsNotifier;

  HomeViewModel(BuildContext context, this._tensorFlowService)
      : _speechService = SpeechToTextService(),
        _ttsNotifier = TTSNotifier(),
        super(context, HomeViewState(_tensorFlowService.type)) {
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    await _speechService.initialize();
  }

  // New methods for speech recognition
  Future<void> startListening() async {
    print('--------- HomeViewModel.startListening:');
    await _speechService.startListening();
  }

  Future<void> stopListening() async {
    print('--------- HomeViewModel.stopListening:');
    _isListening = false;
    await _speechService.stopListening();
    _recognizedText = _speechService.getRecognizedText()!;
    print('_recognizedText:' + _recognizedText!);
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
    print('runModel1:');
    if (_isLoadModel && mounted) {
      print('runModel2:');
      if (!this._isDetecting && mounted) {
        print('runModel3:');
        this._isDetecting = true;
        int startTime = new DateTime.now().millisecondsSinceEpoch;
        var recognitions =
            await this._tensorFlowService.runModelOnFrame(cameraImage);
        final noticeFunction = this._ttsNotifier.onObjectDetected;
        print('runModel targetKeyword:' + targetKeyword);
        this._tensorFlowService.checkDetectedObjectSize(
            recognitions,
            cameraImage.width,
            cameraImage.height,
            noticeFunction,
            targetKeyword);
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
