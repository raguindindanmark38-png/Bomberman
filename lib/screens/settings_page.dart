import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool bgMusic = true;
  bool soundEffects = true;

  @override
  void initState() {
    super.initState();

    bgMusic = AudioService.bgMusicEnabled;
    soundEffects = AudioService.sfxEnabled;
  }

  Widget settingsCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white70, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            activeColor: Colors.greenAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF545050),

      appBar: AppBar(
        backgroundColor: const Color(0xFF3F3B3B),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 8),

            settingsCard(
              title: 'BACKGROUND MUSIC',
              subtitle: 'Enable or disable background music',
              value: bgMusic,
              icon: Icons.music_note,
              onChanged: (value) async {
                setState(() {
                  bgMusic = value;
                });

                await AudioService.setBgMusic(value);

                AudioService.playButtonSound();
              },
            ),

            settingsCard(
              title: 'SOUND EFFECTS',
              subtitle: 'Enable or disable game sound effects',
              value: soundEffects,
              icon: Icons.volume_up,
              onChanged: (value) async {
                setState(() {
                  soundEffects = value;
                });

                await AudioService.setSfx(value);

                AudioService.playButtonSound();
              },
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
