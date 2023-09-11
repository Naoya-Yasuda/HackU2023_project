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

    // この行で、音声の再生が終了するのを待ちます。
    await completer.future;
  }
}
