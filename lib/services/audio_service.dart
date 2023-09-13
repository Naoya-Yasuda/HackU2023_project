import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

// TODO: base_view_modelに定義すればここに書かなくて済むかも
bool duplicateFlag = false; // 真 (true)
bool isMp3Playing = false;

class AudioService {
  final player = AudioCache();
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playSound(num type) async {
    Completer<void> completer = Completer();
    AudioPlayer? audioPlayerInstance;

    if (!duplicateFlag) {
      isMp3Playing = true;
      if (type == 0) {
        audioPlayerInstance = await player.play('audios/dog1b.mp3');
      } else if (type == 1) {
        audioPlayerInstance = await player.play('audios/dog2times.mp3');
      }
    }

    audioPlayerInstance?.onPlayerCompletion.listen((event) {
      isMp3Playing = false;
      completer.complete();
    });

    // タイムアウトを設定します。ここでは10秒後にタイムアウトするようにしています。
    return completer.future.timeout(
      Duration(seconds: 5),
      onTimeout: () {
        if (!completer.isCompleted) {
          // タイムアウト時の処理を追加することができます。
          isMp3Playing = false;
          throw TimeoutException('Audio playback took too long to complete.');
        }
      },
    );
  }
}
