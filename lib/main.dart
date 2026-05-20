import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/music_service.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AudioService.loadSettings();

  runApp(const BombermanApp());
}

class BombermanApp extends StatefulWidget {
  const BombermanApp({super.key});

  @override
  State<BombermanApp> createState() => _BombermanAppState();
}

class _BombermanAppState extends State<BombermanApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startMusicIfEnabled();
  }

  Future<void> _startMusicIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final bgMusic = prefs.getBool('bgMusic') ?? false;

    if (bgMusic) {
      await MusicService.playBgMusic();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    final bgMusic = prefs.getBool('bgMusic') ?? false;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      await MusicService.pauseBgMusic();
    }

    if (state == AppLifecycleState.resumed && bgMusic) {
      await MusicService.resumeBgMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MusicService.stopBgMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bomberman',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'monospace',
        scaffoldBackgroundColor: const Color(0xFF545050),
      ),
      home: const SplashScreen(),
    );
  }
}
