import 'package:flutter_tts/flutter_tts.dart';

class TTSNotifier {
  final FlutterTts flutterTts = FlutterTts();

  TTSNotifier() {
    flutterTts.setLanguage("en-US"); // 言語を設定します
    flutterTts.setPitch(1.0); // ピッチを設定します
    flutterTts.setVolume(1.0); // ボリュームを設定します
  }

  speak(String message) async {
    await flutterTts.speak(message);
  }

// 物体が検知された場合の処理
  onObjectDetected(String objectName, String direction) {
    String message = "Warning! $objectName detected on your $direction.";
    speak(message);
  }
}
