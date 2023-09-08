import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

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

  onObjectDetected(dynamic object, String direction) {
    // TODO: ある大きさ以上の物体(車、人)が検出されたときは「危険です、避けてください」的な内容に分岐させる
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
    Vibration.vibrate(duration: duration);

    speak(message);
  }
}
