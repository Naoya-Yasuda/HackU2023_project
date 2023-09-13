import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'tts_notifier_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  String _recognizedText = '';
  String _target = '';

  SpeechToTextService(String targetKeyword) {
    _target = targetKeyword;
  }

  Function(String)? onKeywordDetected;

  // 消してhomeViewModelで使う予定
  late final TTSNotifier tTSNotifier = TTSNotifier(); // lateを使う

  Future<void> initialize() async {
    print('initialize');
    bool hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      print("Microphone permission was not granted");
      return; // Return early if permission is not granted
    }
    bool available = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
      debugLogging: true,
    );
    if (!available) {
      // Handle the error appropriately
    }
  }

  Future<void> startListening() async {
    print('--------- SpeechToTextService.startListening1:' +
        _isListening.toString());
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

  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus permissionStatus = await Permission.microphone.status;

    if (permissionStatus.isDenied || permissionStatus.isRestricted) {
      permissionStatus = await Permission.microphone.request();
    }

    return permissionStatus.isGranted;
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

  String? getTarget() {
    return _target;
  }

  void setTarget(String target) {
    _target = target;
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
      String extractedText = match.group(1)!; // 抜き出されたテキスト
      print('--------- _onResult2:' + extractedText);

      // 抜き出されたテキストの中に、supportedKeywordsのキーワードが含まれているか確認
      for (var keyword in supportedKeywords) {
        if (extractedText.contains(keyword)) {
          print('--------- _onResult3:' + keyword);
          final message = '$keywordを探します';
          tTSNotifier.speak(message);
          _target = keyword;
          break; // キーワードが見つかったのでループを抜ける
        }
      }
    }
    print('--------- _onResult4:');
    return null;
  }

  void _onStatus(String status) {
    _isListening = status == stt.SpeechToText.listeningStatus;
    print('_onStatus: $_isListening');
  }

  void _onError(dynamic error) {
    print("Error in speech recognition: $error");
  }
}
