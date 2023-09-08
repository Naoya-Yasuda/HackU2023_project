import 'package:flutter_tts/flutter_tts.dart';

class TTSNotifier {
  final FlutterTts flutterTts = FlutterTts();

  TTSNotifier() {
    flutterTts.setLanguage("ja-JP"); // 言語を設定します
    flutterTts.setPitch(1.0); // ピッチを設定します
    flutterTts.setVolume(1.0); // ボリュームを設定します
  }

  speak(String message) async {
    await flutterTts.speak(message);
  }

// 物体が検知された場合の処理
  onObjectDetected(String objectName, String direction) {
    String message = "$objectNameが$directionの方向にあります。";
    speak(message);
  }
}
