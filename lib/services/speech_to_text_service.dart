import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'tts_notifier_service.dart';

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  String _recognizedText = '';

  SpeechToTextService();
  // 消してhomeViewModelで使う予定
  late final TTSNotifier tTSNotifier = TTSNotifier(); // lateを使う

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
    print('--------- SpeechToTextService.startListening1:');
    try {
      if (!_isListening && _speech.isAvailable) {
        print('--------- SpeechToTextService.startListening2:');
        _isListening = true;
        _speech.listen(onResult: _onResult, localeId: 'ja_JP');
      }
    } catch (e) {
      print('--------- SpeechToTextService.startListening3:' + e.toString());
    }
  }

  Future<void> stopListening() async {
    print('--------- SpeechToTextService.stopListening:');
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  String? getRecognizedText() {
    return _recognizedText;
  }

  String? _onResult(SpeechRecognitionResult result) {
    print('--------- _onResult0:');
    _recognizedText = result.recognizedWords;
    print('--------- _onResult1 _recognizedText:' + _recognizedText!);
    final RegExp pattern = RegExp(r'(.+?)を探して');
    final Match? match = pattern.firstMatch(_recognizedText!);
    final supportedKeywords = [
      '椅子',
      '人間',
      '人',
      'キーボード',
    ];

    if (match != null && match.groupCount > 0) {
      String keyword = match.group(1)!; // 抜き出されたキーワード
      print('--------- _onResult2:' + keyword);

      if (supportedKeywords.contains(keyword)) {
        print('--------- _onResult3:' + keyword);
        final message = '$keywordを探します';
        tTSNotifier.speak(message);
        // このキーワードを目標として設定
        return keyword;
      }
    }
    print('--------- _onResult4:');
    return null;
  }

  void _onStatus(String status) {
    _isListening = status == stt.SpeechToText.listeningStatus;
  }

  void _onError(dynamic error) {
    print("Error in speech recognition: $error");
  }
}
