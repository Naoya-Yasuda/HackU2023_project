import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'audio_service.dart';

class TTSNotifier {
  final FlutterTts flutterTts = FlutterTts();
  bool isCurrentlySpeaking = false;
  bool goalFlag = false;

  TTSNotifier() {
    flutterTts.setLanguage("ja-JP");
    flutterTts.setPitch(1.0);
    flutterTts.setVolume(1.0);
    flutterTts.setCompletionHandler(() {
      isCurrentlySpeaking = false;
    });
  }

  speak(String message) async {
    // if (!isCurrentlySpeaking) {
    if (message != '') {
      isCurrentlySpeaking = true;
      await flutterTts.speak(message);
    }
    // }
  }

  Future<bool> onObjectDetected(dynamic object, String direction,
      String targetKeyword, String color) async {
    print('onObjectDetected start');
    final audioService = AudioService();
    var objJpLabel = object[0];
    var objSize = object[1];
    String message;
    var duration;
    print('objJpLabel:$objJpLabel targetKeyword: $targetKeyword');
    //目標検知モードかつ検知したオブジェクトが目標の場合
    if (objJpLabel == targetKeyword) {
      print('objJpLabel2:$objJpLabel targetKeyword2: $targetKeyword');
      message = "目標に到達しました。$objJpLabelが$directionの方向にあります。";
      duration = 3000;
      goalFlag = true;
    } else if (color != '') {
      if (color == '赤') {
        message = "信号機が$directionの方向にあります。赤信号なので渡らないでください。";
      } else {
        message = "信号機が$directionの方向にあります。青信号なので渡ることができます。";
      }
      duration = 1000;
    } else {
      print('else onObjectDetected');
      if (objSize["width"] > 500 && objSize["height"] > 300) {
        message = "危険です。$objJpLabelが$directionの方向にあります。避けて下さい。";
        duration = 5000;
      } else if (objSize["width"] >= 300 && objSize["height"] >= 150) {
        message = "$objJpLabelが$directionの方向にあります。気を付けて下さい。";
        duration = 3000;
      } else {
        message = "$objJpLabelが$directionの方向にあります。";
        duration = 1000;
      }
    }
    print('isCurrentlySpeaking:' + isCurrentlySpeaking.toString());
    if ((!isCurrentlySpeaking && !isMp3Playing) || goalFlag) {
      print('goalFlag:' + goalFlag.toString());
      Vibration.vibrate(duration: duration);
      await audioService.playSound(0);
    }
    print('isMp3Playing:' + isMp3Playing.toString());
    if ((!isCurrentlySpeaking && !isMp3Playing) || goalFlag) {
      await speak(message);
    }
    if (goalFlag) {
      goalFlag = false;
      return true;
    }
    return false;
  }
}
