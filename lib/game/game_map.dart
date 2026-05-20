import 'dart:math';

class GameMap {
  static const int empty = 0;
  static const int wall = 1;
  static const int block = 2;

  static const int rewardBomb = 3;
  static const int rewardShield = 4;
  static const int rewardRange = 5;
  static const int rewardSpeed = 6;

  static List<List<int>> generate({
    required int rows,
    required int cols,
    required String difficulty,
  }) {
    final random = Random();
    final map = List.generate(rows, (_) => List.filled(cols, empty));

    double blockChance;

    if (difficulty == 'EASY') {
      blockChance = 0.32;
    } else if (difficulty == 'MEDIUM') {
      blockChance = 0.38;
    } else {
      blockChance = 0.44;
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final border = r == 0 || c == 0 || r == rows - 1 || c == cols - 1;
        final fixedWall = r % 2 == 0 && c % 2 == 0;

        if (border || fixedWall) {
          map[r][c] = wall;
        } else {
          final safeSpawn = r <= 2 && c <= 2;

          if (!safeSpawn && random.nextDouble() < blockChance) {
            map[r][c] = block;
          }
        }
      }
    }

    map[1][1] = empty;
    map[1][2] = empty;
    map[2][1] = empty;

    return map;
  }

  static int randomReward(Random random) {
    final chance = random.nextDouble();

    if (chance < 0.45) return rewardBomb;
    if (chance < 0.65) return rewardShield;
    if (chance < 0.85) return rewardRange;
    return rewardSpeed;
  }

  static bool isReward(int tile) {
    return tile == rewardBomb ||
        tile == rewardShield ||
        tile == rewardRange ||
        tile == rewardSpeed;
  }
}
