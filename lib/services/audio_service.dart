import 'package:audioplayers/audioplayers.dart';

// TODO: base_view_modelに定義すればここに書かなくて済むかも
bool isLoading = true; // 真 (true)
bool isaudio = false;

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
