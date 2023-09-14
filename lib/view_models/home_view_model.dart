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

  late TensorFlowService _tensorFlowService;
  String _recognizedText = "";
  String? get _targetKeyword => targetKeyword;

  late SpeechToTextService _speechService;
  late TTSNotifier _ttsNotifier;

  HomeViewModel(BuildContext context, this._tensorFlowService)
      : _ttsNotifier = TTSNotifier(),
        super(context, HomeViewState(_tensorFlowService.type)) {
    _speechService = SpeechToTextService(targetKeyword);
    _speechService.onKeywordDetected = (keyword) {
      targetKeyword = keyword; // BaseViewModelのtargetKeywordにセット
      notifyListeners(); // UIの更新
    };
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    await _speechService.initialize();
  }

  // New methods for speech recognition
  Future<void> startListening() async {
    await _speechService.startListening();
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
    _recognizedText = _speechService.getRecognizedText()!;
    print('stopListening _recognizedText:' + _recognizedText);
    notifyListeners(); // To update the UI if needed
  }

  Future switchCamera() async {
    state.cameraIndex = state.cameraIndex == 0 ? 1 : 0;
    this.notifyListeners();
  }

  Future<void> loadModel(ModelType type) async {
    state.type = type;
    await this._tensorFlowService.loadModel(type);
    this._isLoadModel = true;
  }

  Future<void> runModel(CameraImage cameraImage) async {
    if (_isLoadModel && mounted) {
      if (!this._isDetecting && mounted) {
        this._isDetecting = true;
        int startTime = new DateTime.now().millisecondsSinceEpoch;

        // 物体検知の実行
        var recognitions =
            await this._tensorFlowService.runModelOnFrame(cameraImage);

        // 関数に渡す用の通知用関数
        final noticeFunction = this._ttsNotifier.onObjectDetected;
        // 目標キーワードを取得
        final target = this._speechService.getTarget();

        print('runModel targetKeyword:' + target!);

        // 検知したオブジェクトのサイズをチェックし通知・警告する
        var isGoal = await this._tensorFlowService.checkDetectedObjectSize(
            cameraImage.width,
            cameraImage.height,
            noticeFunction,
            target,
            cameraImage);

        // 目標に到達したらtargetKeywordを初期化する
        if (isGoal) {
          this._speechService.setTarget('');
        }
        // 計測終了しログ出力
        int endTime = new DateTime.now().millisecondsSinceEpoch;
        print('Time detection: ${endTime - startTime}');

        // UI更新用に認識結果をセット
        if (recognitions != null && mounted) {
          state.recognitions = List<Recognition>.from(
              recognitions.map((model) => Recognition.fromJson(model)));
          state.widthImage = cameraImage.width;
          state.heightImage = cameraImage.height;
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
