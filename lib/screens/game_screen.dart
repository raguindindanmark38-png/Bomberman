import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../game/game_map.dart';
import '../game/bot_model.dart';
import '../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  final String difficulty;

  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> maze;

  int playerRow = 1;
  int playerCol = 1;

  int bombCount = 10;
  int score = 0;

  int explosionRange = 2;
  int shieldCount = 0;
  int speedBoostSteps = 0;

  int? bombRow;
  int? bombCol;

  bool isGameFinished = false;
  bool isPaused = false;

  final Set<String> explosionTiles = {};
  final Random random = Random();
  final List<BotModel> bots = [];

  Timer? botTimer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    restartGame(startTimer: false);
    startBotMovement();
  }

  void setupDifficultyStats() {
    explosionRange = 2;
    shieldCount = 0;
    speedBoostSteps = 0;

    if (widget.difficulty == 'EASY') {
      bombCount = 10;
    } else if (widget.difficulty == 'MEDIUM') {
      bombCount = 7;
    } else {
      bombCount = 7;
    }
  }

  int getChaseDistance() {
    if (widget.difficulty == 'EASY') return 4;
    if (widget.difficulty == 'MEDIUM') return 6;
    return 9;
  }

  void restartGame({bool startTimer = true}) {
    botTimer?.cancel();

    setState(() {
      isGameFinished = false;
      isPaused = false;
      playerRow = 1;
      playerCol = 1;
      score = 0;
      bombRow = null;
      bombCol = null;
      explosionTiles.clear();
      bots.clear();

      maze = GameMap.generate(
        rows: 13,
        cols: 25,
        difficulty: widget.difficulty,
      );

      setupDifficultyStats();
      spawnBots();
    });

    if (startTimer) startBotMovement();
  }

  void spawnBots() {
    int count;

    if (widget.difficulty == 'EASY') {
      count = 2;
    } else if (widget.difficulty == 'MEDIUM') {
      count = 4;
    } else {
      count = 7;
    }

    while (bots.length < count) {
      final r = random.nextInt(maze.length - 2) + 1;
      final c = random.nextInt(maze[0].length - 2) + 1;

      final farFromPlayer = (r - playerRow).abs() + (c - playerCol).abs() > 6;

      if (maze[r][c] == GameMap.empty && farFromPlayer) {
        bots.add(BotModel(row: r, col: c));
      }
    }
  }

  void startBotMovement() {
    int speed;

    if (widget.difficulty == 'EASY') {
      speed = 900;
    } else if (widget.difficulty == 'MEDIUM') {
      speed = 650;
    } else {
      speed = 420;
    }

    botTimer = Timer.periodic(Duration(milliseconds: speed), (_) {
      moveBots();
    });
  }

  void moveBots() {
    if (isGameFinished || isPaused) return;

    setState(() {
      for (final bot in bots) {
        if (!bot.alive) continue;

        final nextMove = getSmartBotMove(bot);

        if (nextMove != null) {
          bot.row = nextMove[0];
          bot.col = nextMove[1];
        }

        if (bot.row == playerRow && bot.col == playerCol) {
          Future.microtask(hitPlayer);
        }
      }
    });
  }

  List<int>? getSmartBotMove(BotModel bot) {
    final directions = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    final possibleMoves = <List<int>>[];

    for (final dir in directions) {
      final newRow = bot.row + dir[0];
      final newCol = bot.col + dir[1];

      final blockedByBot = bots.any(
        (b) => b.alive && b != bot && b.row == newRow && b.col == newCol,
      );

      final blockedByBomb = bombRow == newRow && bombCol == newCol;

      final canMove =
          maze[newRow][newCol] == GameMap.empty ||
          GameMap.isReward(maze[newRow][newCol]);

      if (canMove && !blockedByBot && !blockedByBomb) {
        possibleMoves.add([newRow, newCol]);
      }
    }

    if (possibleMoves.isEmpty) return null;

    final distanceToPlayer =
        (bot.row - playerRow).abs() + (bot.col - playerCol).abs();

    if (distanceToPlayer > getChaseDistance()) {
      possibleMoves.shuffle(random);
      return possibleMoves.first;
    }

    possibleMoves.sort((a, b) {
      final distanceA = (a[0] - playerRow).abs() + (a[1] - playerCol).abs();
      final distanceB = (b[0] - playerRow).abs() + (b[1] - playerCol).abs();
      return distanceA.compareTo(distanceB);
    });

    return possibleMoves.first;
  }

  bool hasRemainingObjectives() {
    final remainingBlocks = maze
        .expand((row) => row)
        .any((tile) => tile == GameMap.block);

    final aliveBots = bots.any((bot) => bot.alive);

    return remainingBlocks || aliveBots;
  }

  void hitPlayer() {
    if (isGameFinished) return;

    if (shieldCount > 0) {
      setState(() {
        shieldCount--;
        score += 25;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shield protected you!')));
      return;
    }

    gameOver();
  }

  void movePlayer(int rowChange, int colChange) {
    if (isGameFinished || isPaused) return;

    int steps = speedBoostSteps > 0 ? 2 : 1;

    for (int i = 0; i < steps; i++) {
      final newRow = playerRow + rowChange;
      final newCol = playerCol + colChange;

      if (maze[newRow][newCol] == GameMap.wall) break;
      if (maze[newRow][newCol] == GameMap.block) break;

      final botHere = bots.any(
        (bot) => bot.alive && bot.row == newRow && bot.col == newCol,
      );

      if (botHere) {
        hitPlayer();
        return;
      }

      if (GameMap.isReward(maze[newRow][newCol])) {
        collectReward(maze[newRow][newCol]);
        maze[newRow][newCol] = GameMap.empty;
      }

      playerRow = newRow;
      playerCol = newCol;
    }

    if (speedBoostSteps > 0) speedBoostSteps--;

    setState(() {});
  }

  void collectReward(int reward) {
    AudioService.playPickupSound();
    if (reward == GameMap.rewardBomb) {
      bombCount++;
      score += 50;
      showQuickMessage('+1 Bomb');
    } else if (reward == GameMap.rewardShield) {
      shieldCount++;
      score += 75;
      showQuickMessage('+1 Shield');
    } else if (reward == GameMap.rewardRange) {
      explosionRange++;
      score += 100;
      showQuickMessage('Explosion Range Up');
    } else if (reward == GameMap.rewardSpeed) {
      speedBoostSteps += 8;
      score += 100;
      showQuickMessage('Speed Boost');
    }
  }

  void showQuickMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  void placeBomb() {
    if (isGameFinished || isPaused) return;

    if (bombCount <= 0) {
      if (hasRemainingObjectives()) gameOver();
      return;
    }

    if (bombRow != null && bombCol != null) return;

    setState(() {
      bombCount--;
      AudioService.playBombSound();
      bombRow = playerRow;
      bombCol = playerCol;
    });

    Timer(const Duration(seconds: 2), explodeBomb);
  }

  void explodeBomb() {
    if (isGameFinished) return;
    if (bombRow == null || bombCol == null) return;

    AudioService.playExplosionSound();

    final affected = <String>{};

    void addTile(int r, int c) {
      if (maze[r][c] == GameMap.wall) return;

      affected.add('$r,$c');

      if (maze[r][c] == GameMap.block) {
        maze[r][c] = random.nextDouble() < 0.35
            ? GameMap.randomReward(random)
            : GameMap.empty;
        score += 100;
      }
    }

    addTile(bombRow!, bombCol!);

    final directions = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    for (final dir in directions) {
      for (int power = 1; power <= explosionRange; power++) {
        final r = bombRow! + dir[0] * power;
        final c = bombCol! + dir[1] * power;

        if (maze[r][c] == GameMap.wall) break;

        affected.add('$r,$c');

        if (maze[r][c] == GameMap.block) {
          maze[r][c] = random.nextDouble() < 0.35
              ? GameMap.randomReward(random)
              : GameMap.empty;
          score += 100;
          break;
        }
      }
    }

    for (final bot in bots) {
      if (bot.alive && affected.contains('${bot.row},${bot.col}')) {
        bot.alive = false;
        score += 300;
      }
    }

    if (affected.contains('$playerRow,$playerCol')) {
      setState(() {
        explosionTiles.clear();
        explosionTiles.addAll(affected);
        bombRow = null;
        bombCol = null;
      });

      Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        hitPlayer();
      });
      return;
    }

    setState(() {
      explosionTiles.clear();
      explosionTiles.addAll(affected);
      bombRow = null;
      bombCol = null;
    });

    checkWin();

    if (bombCount <= 0 && hasRemainingObjectives()) {
      gameOver();
    }

    Timer(const Duration(milliseconds: 500), () {
      if (!mounted || isGameFinished) return;

      setState(() {
        explosionTiles.clear();
      });
    });
  }

  Future<void> saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    final fullName = userData?['name'] ?? 'Player';
    final photoUrl = userData?['photoUrl'] ?? '';
    final currentBest = userData?['bestScore'] ?? 0;

    await FirebaseFirestore.instance.collection('leaderboards').add({
      'userId': user.uid,
      'fullName': fullName,
      'email': user.email,
      'photoUrl': photoUrl,
      'score': score,
      'difficulty': widget.difficulty,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (score > currentBest) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'bestScore': score},
      );
    }
  }

  Future<void> gameOver() async {
    if (isGameFinished) return;

    isGameFinished = true;
    isPaused = false;
    botTimer?.cancel();

    await saveScore();

    if (!mounted) return;

    AudioService.playGameOverSound();

    showResultDialog(
      title: 'GAME OVER',
      subtitle: 'You survived but failed the mission.',
      icon: Icons.close,
      iconColor: Colors.red,
      buttonText: 'RESTART',
      onButtonTap: () {
        AudioService.playButtonSound();
        Navigator.pop(context);
        restartGame();
      },
    );
  }

  Future<void> checkWin() async {
    if (isGameFinished) return;

    if (!hasRemainingObjectives()) {
      isGameFinished = true;
      isPaused = false;
      botTimer?.cancel();

      await saveScore();

      if (!mounted) return;

      AudioService.playWinSound();

      showResultDialog(
        title: 'YOU WIN!',
        subtitle: 'All blocks and bots are cleared.',
        icon: Icons.emoji_events,
        iconColor: Colors.amber,
        buttonText: 'PLAY AGAIN',
        onButtonTap: () {
          AudioService.playButtonSound();
          Navigator.pop(context);
          restartGame();
        },
      );
    }
  }

  void showPauseMenu() {
    if (isGameFinished) return;

    setState(() {
      isPaused = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF3F3B3B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle, color: Colors.white, size: 58),
              const SizedBox(height: 12),
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              dialogButton(
                text: 'RESUME',
                color: Colors.green,
                onTap: () {
                  AudioService.playButtonSound();
                  Navigator.pop(context);
                  setState(() {
                    isPaused = false;
                  });
                },
              ),
              dialogButton(
                text: 'RESTART',
                color: Colors.blue,
                onTap: () {
                  AudioService.playButtonSound();
                  Navigator.pop(context);
                  restartGame();
                },
              ),
              dialogButton(
                text: 'BACK HOME',
                color: Colors.red,
                onTap: () {
                  AudioService.playButtonSound();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showResultDialog({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required VoidCallback onButtonTap,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF3F3B3B),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 46),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  'SCORE: $score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                dialogButton(
                  text: buttonText,
                  color: Colors.blue,
                  onTap: onButtonTap,
                ),
                dialogButton(
                  text: 'BACK HOME',
                  color: Colors.red,
                  onTap: () {
                    AudioService.playButtonSound();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dialogButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Color getTileColor(int value, bool isExplosion) {
    if (isExplosion) return Colors.orangeAccent;
    if (value == GameMap.wall) return Colors.grey.shade700;
    if (value == GameMap.block) return Colors.white;
    if (value == GameMap.rewardBomb) return Colors.amber;
    if (value == GameMap.rewardShield) return Colors.lightBlueAccent;
    if (value == GameMap.rewardRange) return Colors.deepOrangeAccent;
    if (value == GameMap.rewardSpeed) return Colors.purpleAccent;
    return const Color(0xFF0E6B2D);
  }

  Widget buildPlayer(String photoUrl) {
    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Icon(Icons.person, color: Colors.white, size: 26);
          },
        ),
      );
    }

    return const Icon(Icons.person, color: Colors.white, size: 26);
  }

  Widget buildBot(String botImageUrl) {
    if (botImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          botImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Icon(Icons.smart_toy, color: Colors.red, size: 26);
          },
        ),
      );
    }

    return const Icon(Icons.smart_toy, color: Colors.red, size: 26);
  }

  Widget buildRewardIcon(int tile) {
    if (tile == GameMap.rewardBomb) {
      return const Icon(Icons.circle, color: Colors.black, size: 20);
    }

    if (tile == GameMap.rewardShield) {
      return const Icon(Icons.shield, color: Colors.blue, size: 22);
    }

    if (tile == GameMap.rewardRange) {
      return const Icon(
        Icons.local_fire_department,
        color: Colors.red,
        size: 22,
      );
    }

    if (tile == GameMap.rewardSpeed) {
      return const Icon(Icons.bolt, color: Colors.white, size: 22);
    }

    return const SizedBox.shrink();
  }

  Widget buildTile(int row, int col, String photoUrl, String botImageUrl) {
    final isPlayer = row == playerRow && col == playerCol;
    final isBomb = row == bombRow && col == bombCol;
    final isExplosion = explosionTiles.contains('$row,$col');
    final tile = maze[row][col];

    final botHere = bots.any(
      (bot) => bot.alive && bot.row == row && bot.col == col,
    );

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: getTileColor(tile, isExplosion),
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Center(
        child: isPlayer
            ? buildPlayer(photoUrl)
            : botHere
            ? buildBot(botImageUrl)
            : isBomb
            ? const Icon(Icons.circle, color: Colors.black, size: 24)
            : GameMap.isReward(tile)
            ? buildRewardIcon(tile)
            : isExplosion
            ? const Icon(Icons.flash_on, color: Colors.red, size: 24)
            : null,
      ),
    );
  }

  Widget gameMap(String photoUrl, String botImageUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellByWidth = constraints.maxWidth / maze[0].length;
        final cellByHeight = constraints.maxHeight / maze.length;
        final cellSize = min(cellByWidth, cellByHeight);

        return Center(
          child: SizedBox(
            width: cellSize * maze[0].length,
            height: cellSize * maze.length,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: maze.length * maze[0].length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: maze[0].length,
              ),
              itemBuilder: (context, index) {
                final row = index ~/ maze[0].length;
                final col = index % maze[0].length;
                return buildTile(row, col, photoUrl, botImageUrl);
              },
            ),
          ),
        );
      },
    );
  }

  Widget controlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 38),
      ),
    );
  }

  Widget bombButton() {
    return GestureDetector(
      onTap: () {
        AudioService.playButtonSound();
        placeBomb();
      },
      child: Container(
        width: 130,
        height: 70,
        decoration: BoxDecoration(
          color: bombCount > 0 ? Colors.red : Colors.grey,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'BOMB $bombCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget controls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        controlButton(Icons.keyboard_arrow_up, () => movePlayer(-1, 0)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            controlButton(Icons.keyboard_arrow_left, () => movePlayer(0, -1)),
            controlButton(Icons.keyboard_arrow_down, () => movePlayer(1, 0)),
            controlButton(Icons.keyboard_arrow_right, () => movePlayer(0, 1)),
          ],
        ),
        const SizedBox(height: 12),
        bombButton(),
      ],
    );
  }

  Widget statChip({required IconData icon, required String text}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget statsBar() {
    return Column(
      children: [
        Text(
          isPaused ? 'PAUSED' : 'SCORE: $score   •   BOMBS: $bombCount',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              statChip(icon: Icons.shield, text: 'SHIELD $shieldCount'),
              statChip(
                icon: Icons.local_fire_department,
                text: 'RANGE $explosionRange',
              ),
              statChip(icon: Icons.bolt, text: 'SPEED $speedBoostSteps'),
              statChip(icon: Icons.radar, text: 'CHASE ${getChaseDistance()}'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    botTimer?.cancel();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF545050),
        body: Center(
          child: Text(
            'No user logged in',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF545050),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F3B3B),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 58,
        leading: IconButton(
          onPressed: showPauseMenu,
          icon: const Icon(Icons.pause, color: Colors.white),
        ),
        title: Text(
          '${widget.difficulty} MODE',
          style: const TextStyle(
            color: Colors.white,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final photoUrl = data?['photoUrl'] ?? '';
          final botImageUrl = data?['botImageUrl'] ?? '';

          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;

          if (isLandscape) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        statsBar(),
                        const SizedBox(height: 6),
                        Expanded(child: gameMap(photoUrl, botImageUrl)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(flex: 3, child: controls()),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                statsBar(),
                const SizedBox(height: 8),
                Expanded(child: gameMap(photoUrl, botImageUrl)),
                const SizedBox(height: 8),
                controls(),
              ],
            ),
          );
        },
      ),
    );
  }
}
