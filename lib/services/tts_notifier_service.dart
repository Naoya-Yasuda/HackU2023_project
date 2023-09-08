import 'package:flutter_tts/flutter_tts.dart';

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
    print('speak1: $message');
    if (!isCurrentlySpeaking) {
      isCurrentlySpeaking = true;
      print('speak2');
      await flutterTts.speak(message);
    }
  }

  onObjectDetected(String objectName, String direction) {
    // TODO: ラベルが英語なので、日本語に変換するメソッドを作成する
    // TODO: ある大きさ以上の物体(車、人)が検出されたときは「危険です、避けてください」的な内容に分岐させる
    String message = "$objectNameが$directionの方向にあります。";
    speak(message);
  }
}
