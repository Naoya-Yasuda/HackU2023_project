import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  String? _recognizedText;

  Future<void> initialize() async {
    bool available = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );
    if (!available) {
      // Handle the error appropriately
    }
  }

  Future<void> startListening() async {
    if (!_isListening) {
      _speech.listen(onResult: _onResult);
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      _speech.stop();
    }
  }

  String? getRecognizedText() {
    return _recognizedText;
  }

  String? _onResult(SpeechRecognitionResult result) {
    _recognizedText = result.recognizedWords;
    final RegExp pattern = RegExp(r'(.+?)を探して');
    final Match? match = pattern.firstMatch(_recognizedText!);
    final supportedKeywords = ['椅子', '人間', 'キーボード'];

    if (match != null && match.groupCount > 0) {
      String keyword = match.group(1)!; // 抜き出されたキーワード

      if (supportedKeywords.contains(keyword)) {
        // このキーワードを目標として設定
        return keyword;
      }
    }
    return null;
  }

  void _onStatus(String status) {
    _isListening = status == stt.SpeechToText.listeningStatus;
  }

  void _onError(dynamic error) {
    // Handle the error appropriately
  }
}
