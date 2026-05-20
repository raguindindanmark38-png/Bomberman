import 'package:audioplayers/audioplayers.dart';

class MusicService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playBgMusic() async {
    if (_isPlaying) return;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('audio/bg_music.mp3'));
    _isPlaying = true;
  }

  static Future<void> pauseBgMusic() async {
    if (!_isPlaying) return;

    await _player.pause();
    _isPlaying = false;
  }

  static Future<void> stopBgMusic() async {
    await _player.stop();
    _isPlaying = false;
  }

  static Future<void> resumeBgMusic() async {
    if (_isPlaying) return;

    await _player.resume();
    _isPlaying = true;
  }
}
