import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final player = AudioCache();
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playSound(num type) async {
    if (type == 0) {
      await player.play('audios/dog1b.mp3');
    } else if (type == 1) {
      await player.play('audios/dog2times.mp3');
    }
    await audioPlayer.onPlayerCompletion.first;
  }
}
