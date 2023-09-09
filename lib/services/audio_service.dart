import 'package:audioplayers/audioplayers.dart';

/*class AudioService {
  final player = AudioCache();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isCurrentlyPlaying = false;
  Future<void> playSound(num type) async {
    if (isCurrentlyPlaying) {
      return;
    }
    isCurrentlyPlaying = true;
    if (type == 0) {
      await player.play('audios/dog1b.mp3');
    } else if (type == 1) {
      await player.play('audios/dog2times.mp3');
    }
    await audioPlayer.onPlayerCompletion.first;
    isCurrentlyPlaying = false;
  }
}*/

//テストコード
class AudioService {
  final player = AudioCache();
  final AudioPlayer audioPlayer = AudioPlayer();
  Future<void> playSound(num type) async {
    if (type == 0 && isLoading) {
      await player.play('audios/dog1b.mp3');
      await Future.delayed(Duration(milliseconds: 1300), () {
        // ここに1秒後に実行する処理を記述します
        isaudio = true;
      });
    } else if (type == 1 && isLoading) {
      await player.play('audios/dog2times.mp3');
      await Future.delayed(Duration(milliseconds: 1300), () {
        // ここに1秒後に実行する処理を記述します
        isaudio = true;
      });
    }
  }
}
//テストコード