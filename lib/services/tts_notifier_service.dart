import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'audio_service.dart';

class TTSNotifier {
  final FlutterTts flutterTts = FlutterTts();
  bool isCurrentlySpeaking = false;
  String _targetKeyword = '';

  TTSNotifier(String targetKeyword) {
    this._targetKeyword = targetKeyword;
    flutterTts.setLanguage("ja-JP");
    flutterTts.setPitch(1.0);
    flutterTts.setVolume(1.0);
    flutterTts.setCompletionHandler(() {
      isCurrentlySpeaking = false;
    });
  }

  speak(String message) async {
    if (!isCurrentlySpeaking) {
      isCurrentlySpeaking = true;
      await flutterTts.speak(message);
    }
  }

  Future<void> onObjectDetected(dynamic object, String direction) async {
    print('onObjectDetected start');
    final audioService = AudioService();
    var objJpLabel = object[0];
    var objSize = object[1];
    String message;
    var duration;
    print('objJpLabel:$objJpLabel _targetKeyword: $_targetKeyword');
    //目標検知モードかつ検知したオブジェクトが目標の場合
    if (objJpLabel == _targetKeyword) {
      print('objJpLabel2:$objJpLabel _targetKeyword2: $_targetKeyword');
      message = "目標に到達しました。$objJpLabelが$directionの方向にあります。";
    } else {
      print('else onObjectDetected');
      if (objSize.width > 500 && objSize.height > 300) {
        message = "危険です。$objJpLabelが$directionの方向にあります。避けて下さい。";
        duration = 5000;
      } else if (objSize.width >= 300 && objSize.height >= 150) {
        message = "$objJpLabelが$directionの方向にあります。気を付けて下さい。";
        duration = 3000;
      } else {
        message = "$objJpLabelが$directionの方向にあります。";
        duration = 1000;
      }
    }
    print('isCurrentlySpeaking:' + isCurrentlySpeaking.toString());
    if (!isCurrentlySpeaking) {
      Vibration.vibrate(duration: duration);
      await audioService.playSound(0);
    }
    print('isaudio:' + isaudio.toString());
    if (isaudio) {
      speak(message);
      isaudio = false;
    }
  }
}
