import 'package:flutter/widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'tts_notifier_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;
import 'package:html/parser.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

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

  Timer? _timer;

  String? _directions;

  //final _destinationController = TextEditingController();
  String destination = '';

  bool guideFrag = false;

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
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      loadGuide();
    });
  }

  String convertHtmlToPlainText(String htmlString) {
    final document = parse(htmlString);
    final String parsedString =
        parse(document.body!.text).documentElement!.text;
    return parsedString;
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

  Future<String?> _onResult(SpeechRecognitionResult result) async {
    print('--------- _onResult0:');
    _recognizedText = result.recognizedWords;
    print('--------- _onResult1 _recognizedText:' + _recognizedText!);

    final RegExp pattern = RegExp(r'(.+?)を探して');
    final Match? match = pattern.firstMatch(_recognizedText!);
    final RegExp pattern2 = RegExp(r'(.+?)まで案内して');
    final Match? match2 = pattern2.firstMatch(_recognizedText!);
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
    } else if (match2 != null) {
      //道案内の場合
      guideFrag = true;
      destination = match2.group(1)!; // 抜き出されたテキスト
      print('道案内のテキスト：$destination');
      await tTSNotifier.speak('$destinationまでの道案内を開始します。');
      await Future.delayed(Duration(milliseconds: 2000)); // 1.5秒待機
      loadGuide();
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

  Future<void> loadGuide() async {
    if (!guideFrag) {
      return;
    }
    final apiKey = 'AIzaSyA-3ZfIrqxoICutfetO0GujoL5_Q0mW5OI';
    var currentLocation = await getCurrentLocation();
    print('currentLocation:${currentLocation.toString()}');
    var userLocationParam = '${currentLocation[0]},${currentLocation[1]}';
    var goalFlag = false;
    String _directions = '';
    while (!goalFlag) {
      final result =
          await fetchDirections(apiKey, userLocationParam, destination);

      String htmlDirections =
          result['routes'][0]['legs'][0]['steps'][0]['html_instructions'];
      _directions = convertHtmlToPlainText(htmlDirections);
      // ルート情報を取得します
      List<dynamic> routes = result['routes'];
      if (routes != null && routes.isNotEmpty) {
        // 最初のルートを取得します
        Map<String, dynamic> route = routes[0];

        // ルートのレッグ情報を取得します
        List<dynamic> legs = route['legs'];

        if (legs != null && legs.isNotEmpty) {
          // 最後のレッグを取得します
          Map<String, dynamic> lastLeg = legs.last;

          // レッグのステップ情報を取得します
          List<dynamic> steps = lastLeg['steps'];

          if (steps != null && steps.isNotEmpty) {
            // 最後のステップを取得します
            Map<String, dynamic> lastStep = steps.last;

            // 最後のステップの終了地点情報を取得します
            Map<String, dynamic> endLocation = lastStep['end_location'];

            if (endLocation != null) {
              // 終了地点とユーザーの現在地が一致しているか確認します
              double lat1 = endLocation['lat'];
              double lng1 = endLocation['lng'];
              double lat2 = currentLocation[0];
              double lng2 = currentLocation[1];

              // 緯度経度をラジアンに変換します
              double dLat = _degreesToRadians(lat2 - lat1);
              double dLng = _degreesToRadians(lng2 - lng1);

              // ハバーサイン公式を使用して2点間の距離を計算します
              double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
                  math.cos(_degreesToRadians(lat1)) *
                      math.cos(_degreesToRadians(lat2)) *
                      math.sin(dLng / 2) *
                      math.sin(dLng / 2);
              double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
              // 地球の半径（メートル）
              const double earthRadius = 6371000;

              // 誤差許容範囲（メートル）
              const double tolerance = 10;
              double distance = earthRadius * c;

              if (distance <= tolerance) {
                print("目的地に到着しました！$endLocation");
                goalFlag = true;
                guideFrag = false;
                _timer?.cancel();
              } else {
                print("まだ目的地に到着していません。");
              }
            }
          } else {
            print("ステップ情報が見つかりませんでした。");
          }
        } else {
          print("レッグ情報が見つかりませんでした。");
        }
      } else {
        print("ルート情報が見つかりませんでした。");
        _directions = "経路が見つかりませんでした";
      }

      tTSNotifier.speak(_directions);

      //await Future.delayed(Duration(seconds: 10));
      print('directions:$_directions');
    }
  }

  Future<List<dynamic>> getCurrentLocation() async {
    final location = loc.Location();
    final hasPermission = await location.hasPermission();
    if (hasPermission == PermissionStatus.denied) {
      await location.requestPermission();
    }
    final currentLocation = await location.getLocation();
    return [currentLocation.latitude, currentLocation.longitude];
    // return '${currentLocation.latitude},${currentLocation.longitude}';
  }

  Future<Map<String, dynamic>> fetchDirections(
      String apiKey, String origin, String destination) async {
    const endpointUrl = 'https://maps.googleapis.com/maps/api/directions/json';
    final queryParameters = {
      'origin': origin,
      'destination': destination,
      'key': apiKey,
      'language': 'ja'
    };

    final uri =
        Uri.parse(endpointUrl).replace(queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch directions');
    }
  }

  // 度数法からラジアンへの変換関数
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
