import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final player = AudioCache();

  Future<void> playSound() async {
    await player.play('audio/dog1b.mp3');
  }
}
