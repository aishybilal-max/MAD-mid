import 'package:audioplayers/audioplayers.dart';

/// In-app alarm sound (works in Chrome and on phones while the app is open).
class Alarm {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play(String sound) async {
    if (sound == 'silent') return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/dragon_alert.mp3'));
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}
