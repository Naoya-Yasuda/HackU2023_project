import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_object_detection/app/base/base_view_model.dart';
import 'package:vibration/vibration.dart';
import '/models/recognition.dart';
import 'package:flutter_realtime_object_detection/view_states/home_view_state.dart';
import 'package:flutter_realtime_object_detection/services/tensorflow_service.dart';
import 'package:flutter_realtime_object_detection/services/speech_to_text_service.dart';
import 'package:flutter_realtime_object_detection/services/audio_service.dart';
import 'package:flutter_realtime_object_detection/services/tts_notifier_service.dart';

class HomeViewModel extends BaseViewModel<HomeViewState> {
  bool _isDetecting = false;
  bool _isLoadModel = false;
  bool _isListening = false;

  late TensorFlowService _tensorFlowService;

  final SpeechToTextService _speechService = SpeechToTextService();
  final AudioService audioService = AudioService();
  final TTSNotifier ttsNotifier = TTSNotifier();
  String? _recognizedText;

  String? get recognizedText => _recognizedText;
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
    _recognizedText = _speechService.getRecognizedText();

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
        List? list = this._tensorFlowService.checkDetectedObjectSize(
            recognitions, cameraImage.width, cameraImage.height);
        onObjectDetected(list![0], list[1]);
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

  Future<void> onObjectDetected(dynamic object, String direction) async {
    var objSize = object[1];
    String message;
    var duration;
    if (objSize.width > 500 && objSize.height > 300) {
      message = "危険です。${object[0]}が$directionの方向にあります。避けて下さい。";
      duration = 5000;
    } else if (objSize.width >= 300 && objSize.height >= 150) {
      message = "${object[0]}が$directionの方向にあります。気を付けて下さい。";
      duration = 3000;
    } else {
      message = "${object[0]}が$directionの方向にあります。";
      duration = 1000;
    }
    if (!state.isCurrentlyPlaying) {
      print("=================audio success");
      Vibration.vibrate(duration: duration);
      await audioService.playSound(0);
      print("===============after audio success");
    }
    print("~~~~~~~~~~~~~~~speak success");
    ttsNotifier.speak(message);
    print("~~~~~~~~~~~~~~~after speak success");
  }
}
