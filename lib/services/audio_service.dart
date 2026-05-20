import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioPlayer bgPlayer = AudioPlayer();
  static final AudioPlayer sfxPlayer = AudioPlayer();

  static bool bgMusicEnabled = true;
  static bool sfxEnabled = true;

  // =========================
  // LOAD SETTINGS
  // =========================

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    bgMusicEnabled = prefs.getBool('bg_music') ?? true;
    sfxEnabled = prefs.getBool('sfx') ?? true;
  }

  // =========================
  // SAVE SETTINGS
  // =========================

  static Future<void> setBgMusic(bool value) async {
    bgMusicEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bg_music', value);

    if (value) {
      playBgMusic();
    } else {
      stopBgMusic();
    }
  }

  static Future<void> setSfx(bool value) async {
    sfxEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx', value);
  }

  // =========================
  // BACKGROUND MUSIC
  // =========================

  static Future<void> playBgMusic() async {
    if (!bgMusicEnabled) return;

    await bgPlayer.stop();

    await bgPlayer.setReleaseMode(ReleaseMode.loop);

    await bgPlayer.play(AssetSource('audio/bg_music.mp3'), volume: 0.4);
  }

  static Future<void> stopBgMusic() async {
    await bgPlayer.stop();
  }

  // =========================
  // SOUND EFFECTS
  // =========================

  static Future<void> playBombSound() async {
    if (!sfxEnabled) return;

    await sfxPlayer.play(AssetSource('audio/bomb.mp3'), volume: 1);
  }

  static Future<void> playExplosionSound() async {
    if (!sfxEnabled) return;

    await sfxPlayer.play(AssetSource('audio/explosion.mp3'), volume: 1);
  }

  static Future<void> playPickupSound() async {
    if (!sfxEnabled) return;

    await sfxPlayer.play(AssetSource('audio/pickup.mp3'), volume: 1);
  }

  static Future<void> playButtonSound() async {
    if (!sfxEnabled) return;

    await sfxPlayer.play(AssetSource('audio/button.mp3'), volume: 0.8);
  }

  static Future<void> playGameOverSound() async {
    if (!sfxEnabled) return;

    await sfxPlayer.play(AssetSource('audio/gameover.mp3'), volume: 1);
  }

  static Future<void> playWinSound() async {
    if (!sfxEnabled) return;

    await sfxPlayer.play(AssetSource('audio/win.mp3'), volume: 1);
  }
}
