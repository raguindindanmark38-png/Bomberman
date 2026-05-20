import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_page.dart';
import 'settings_page.dart';
import 'leaderboard_page.dart';
import 'game_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum Difficulty { easy, medium, hard }

class _HomePageState extends State<HomePage> {
  Difficulty selectedDifficulty = Difficulty.easy;

  String get difficultyText {
    switch (selectedDifficulty) {
      case Difficulty.easy:
        return 'EASY';
      case Difficulty.medium:
        return 'MEDIUM';
      case Difficulty.hard:
        return 'HARD';
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF545050),
          title: const Text(
            'SELECT DIFFICULTY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              difficultyButton('EASY', Difficulty.easy),
              difficultyButton('MEDIUM', Difficulty.medium),
              difficultyButton('HARD', Difficulty.hard),
            ],
          ),
        );
      },
    );
  }

  Widget difficultyButton(String text, Difficulty difficulty) {
    final bool selected = selectedDifficulty == difficulty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedDifficulty = difficulty;
          });
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Colors.blue : const Color(0xFF3F3B3B),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
        ),
        child: Text(text),
      ),
    );
  }

  Widget profileButton() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const CircleAvatar(
        radius: 22,
        backgroundColor: Colors.black,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final photoUrl = data?['photoUrl'] ?? '';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
          child: CircleAvatar(
            radius: 23,
            backgroundColor: Colors.black,
            backgroundImage: photoUrl.toString().isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.toString().isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
        );
      },
    );
  }

  Widget menuButton({
    required String text,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 245,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget difficultyInfo() {
    String info;

    if (difficultyText == 'EASY') {
      info = '2 BOTS • 10 BOMBS';
    } else if (difficultyText == 'MEDIUM') {
      info = '4 BOTS • 7 BOMBS';
    } else {
      info = '7 BOTS • 7 BOMBS';
    }

    return Text(
      info,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
        letterSpacing: 1,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF545050),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 15, right: 15, child: profileButton()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/LOGO.png', width: 260),
                    const SizedBox(height: 35),
                    difficultyInfo(),
                    const SizedBox(height: 12),
                    menuButton(
                      text: 'START GAME',
                      icon: Icons.play_arrow,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GameScreen(difficulty: difficultyText),
                          ),
                        );
                      },
                    ),
                    menuButton(
                      text: 'DIFFICULTY: $difficultyText',
                      icon: Icons.tune,
                      onTap: showDifficultyDialog,
                    ),
                    menuButton(
                      text: 'LEADERBOARD',
                      icon: Icons.leaderboard,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardPage(),
                          ),
                        );
                      },
                    ),
                    menuButton(
                      text: 'SETTINGS',
                      icon: Icons.settings,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
