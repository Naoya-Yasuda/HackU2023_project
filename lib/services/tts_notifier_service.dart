import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'audio_service.dart';

class TTSNotifier {
  final FlutterTts flutterTts = FlutterTts();
  bool isCurrentlySpeaking = false;

  TTSNotifier() {
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

  Future<void> onObjectDetected(
      dynamic object, String direction, String targetKeyword) async {
    print('onObjectDetected start');
    final audioService = AudioService();
    var objJpLabel = object[0];
    var objSize = object[1];
    String message;
    var duration;
    print('objJpLabel:$objJpLabel targetKeyword: $targetKeyword');
    //目標検知モードかつ検知したオブジェクトが目標の場合
    if (objJpLabel == targetKeyword) {
      // TODO: 目標が通知された時にtargetを初期化する
      // TODO: 目標到達の通知はスキップされないようにする
      print('objJpLabel2:$objJpLabel targetKeyword2: $targetKeyword');
      message = "目標に到達しました。$objJpLabelが$directionの方向にあります。";
      duration = 3000;
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
    if (!isCurrentlySpeaking && !isMp3Playing) {
      Vibration.vibrate(duration: duration);
      await audioService.playSound(0);
    }
    print('isMp3Playing:' + isMp3Playing.toString());
    if (!isMp3Playing) {
      await speak(message);
    }
  }
}
