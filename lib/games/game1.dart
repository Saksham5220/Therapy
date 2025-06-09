import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

class Game1Page extends StatefulWidget {
  final int startLevel;

  const Game1Page({super.key, this.startLevel = 1});

  @override
  State<Game1Page> createState() => _Game1PageState();
}

class _Game1PageState extends State<Game1Page> with TickerProviderStateMixin {
  static const int boardWidth = 19;
  static const int boardHeight = 21;

  List<List<int>> board = [];
  int pacmanX = 9;
  int pacmanY = 15;
  int pacmanDirection = 0; // 0: right, 1: down, 2: left, 3: up
  int nextDirection = 0;

  List<Ghost> ghosts = [];
  Timer? gameTimer;

  int score = 0;
  int level = 1;
  int lives = 3;
  int pellets = 0;
  int totalPellets = 0;
  bool gameRunning = false;
  bool gameOver = false;
  bool levelComplete = false;

  // Frame counters for smoother movement
  int pacmanFrameCounter = 0;
  int ghostFrameCounter = 0;

  // Level completion at 160 points per level
  int get targetScore => level * 160;

  // Game speeds - higher values = slower movement
  int get pacmanMoveInterval =>
      max(2, 5 - level); // Pacman moves every 2-5 frames
  int get ghostMoveInterval =>
      max(3, 7 - level); // Ghosts move every 3-7 frames

  // Gesture detection variables
  Offset? panStart;
  static const double minSwipeDistance = 40.0;

  @override
  void initState() {
    super.initState();
    level = widget.startLevel > 0 ? widget.startLevel : 1; // Ensure valid level
    // Hide system UI for full screen experience - more aggressive approach
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    // Also hide the status bar and navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    initializeBoard();
    initializeGhosts();
    startGame();
  }

  @override
  void dispose() {
    // Restore system UI when leaving the game
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    gameTimer?.cancel();
    super.dispose();
  }

  // Save completed level to SharedPreferences
  Future<void> _saveCompletedLevel(int completedLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_completed_level', completedLevel);
    } catch (e) {
      print('Error saving completed level: $e');
    }
  }

  void initializeBoard() {
    // Classic Pacman-style maze
    board = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 3, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1],
      [1, 2, 2, 2, 2, 2, 1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 2, 2, 1],
      [1, 1, 1, 1, 1, 2, 1, 1, 0, 1, 0, 1, 1, 2, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 2, 1, 0, 1, 4, 1, 0, 1, 2, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 2, 0, 0, 1, 0, 1, 0, 0, 2, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 2, 1, 0, 1, 1, 1, 0, 1, 2, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 2, 1, 1, 0, 1, 0, 1, 1, 2, 1, 1, 1, 1, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1],
      [1, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 1],
      [1, 1, 1, 2, 1, 2, 1, 2, 1, 1, 1, 2, 1, 2, 1, 2, 1, 1, 1],
      [1, 2, 2, 2, 2, 2, 1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 2, 2, 1],
      [1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];

    // Count total pellets
    pellets = 0;
    for (int y = 0; y < boardHeight; y++) {
      for (int x = 0; x < boardWidth; x++) {
        if (board[y][x] == 2 || board[y][x] == 3) {
          pellets++;
        }
      }
    }
    totalPellets = pellets;
  }

  void initializeGhosts() {
    ghosts = [
      Ghost(9, 9, Colors.red, 0),
      Ghost(8, 9, Colors.pink, 1),
      Ghost(10, 9, Colors.cyan, 2),
      Ghost(9, 10, Colors.orange, 3),
    ];

    // Add more ghosts at higher levels
    if (level > 2 && ghosts.length < 5) {
      ghosts.add(Ghost(8, 10, Colors.purple, 4));
    }
    if (level > 4 && ghosts.length < 6) {
      ghosts.add(Ghost(10, 10, Colors.green, 5));
    }
  }

  void startGame() {
    gameRunning = true;
    gameOver = false;
    levelComplete = false;
    pacmanFrameCounter = 0;
    ghostFrameCounter = 0;

    // 60 FPS game timer for smooth animation
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (gameRunning && mounted) {
        updateGame();
      }
    });
  }

  void updateGame() {
    bool shouldUpdate = false;

    // Update Pacman movement
    pacmanFrameCounter++;
    if (pacmanFrameCounter >= pacmanMoveInterval) {
      pacmanFrameCounter = 0;
      movePacman();
      shouldUpdate = true;
    }

    // Update ghost movement
    ghostFrameCounter++;
    if (ghostFrameCounter >= ghostMoveInterval) {
      ghostFrameCounter = 0;
      moveGhosts();
      shouldUpdate = true;
    }

    // Check game state
    checkCollisions();
    checkWinCondition();

    // Update UI only when needed
    if (shouldUpdate && mounted) {
      setState(() {});
    }
  }

  void movePacman() {
    // Try to change direction if requested
    if (nextDirection != pacmanDirection && canMove(nextDirection)) {
      pacmanDirection = nextDirection;
    }

    // Move in current direction
    if (canMove(pacmanDirection)) {
      int newX = pacmanX;
      int newY = pacmanY;

      switch (pacmanDirection) {
        case 0:
          newX++;
          break; // right
        case 1:
          newY++;
          break; // down
        case 2:
          newX--;
          break; // left
        case 3:
          newY--;
          break; // up
      }

      // Handle tunnel wraparound
      if (newX < 0) newX = boardWidth - 1;
      if (newX >= boardWidth) newX = 0;
      if (newY < 0) newY = boardHeight - 1;
      if (newY >= boardHeight) newY = 0;

      pacmanX = newX;
      pacmanY = newY;

      // Eat pellets
      if (board[pacmanY][pacmanX] == 2) {
        board[pacmanY][pacmanX] = 0;
        score += 10;
        pellets--;
      } else if (board[pacmanY][pacmanX] == 3) {
        board[pacmanY][pacmanX] = 0;
        score += 50;
        pellets--;
        // Power pellet - make ghosts vulnerable
        for (var ghost in ghosts) {
          ghost.vulnerable = true;
          ghost.vulnerableTimer = 240; // 4 seconds at 60 FPS
        }
      }
    }
  }

  bool canMove(int direction) {
    int newX = pacmanX;
    int newY = pacmanY;

    switch (direction) {
      case 0:
        newX++;
        break; // right
      case 1:
        newY++;
        break; // down
      case 2:
        newX--;
        break; // left
      case 3:
        newY--;
        break; // up
    }

    // Handle wraparound
    if (newX < 0) newX = boardWidth - 1;
    if (newX >= boardWidth) newX = 0;
    if (newY < 0) newY = boardHeight - 1;
    if (newY >= boardHeight) newY = 0;

    // Check if position is valid (not a wall)
    return board[newY][newX] != 1;
  }

  void moveGhosts() {
    final random = Random();

    for (var ghost in ghosts) {
      // Update vulnerability timer
      if (ghost.vulnerableTimer > 0) {
        ghost.vulnerableTimer--;
        if (ghost.vulnerableTimer == 0) {
          ghost.vulnerable = false;
        }
      }

      // Find possible moves
      List<int> possibleMoves = [];
      for (int dir = 0; dir < 4; dir++) {
        int newX = ghost.x;
        int newY = ghost.y;

        switch (dir) {
          case 0:
            newX++;
            break;
          case 1:
            newY++;
            break;
          case 2:
            newX--;
            break;
          case 3:
            newY--;
            break;
        }

        // Handle wraparound
        if (newX < 0) newX = boardWidth - 1;
        if (newX >= boardWidth) newX = 0;
        if (newY < 0) newY = boardHeight - 1;
        if (newY >= boardHeight) newY = 0;

        // Check if move is valid
        if (board[newY][newX] != 1) {
          possibleMoves.add(dir);
        }
      }

      if (possibleMoves.isNotEmpty) {
        int chosenDirection;

        if (ghost.vulnerable) {
          // Run away randomly when vulnerable
          chosenDirection = possibleMoves[random.nextInt(possibleMoves.length)];
        } else {
          // AI: chance to chase Pacman increases with level
          double chaseChance = min(0.7, 0.3 + (level * 0.05));

          if (random.nextDouble() < chaseChance) {
            // Chase Pacman - find direction that gets closer
            int bestDirection = possibleMoves[0];
            int bestDistance = 999999;

            for (int dir in possibleMoves) {
              int testX = ghost.x;
              int testY = ghost.y;

              switch (dir) {
                case 0:
                  testX++;
                  break;
                case 1:
                  testY++;
                  break;
                case 2:
                  testX--;
                  break;
                case 3:
                  testY--;
                  break;
              }

              // Handle wraparound for distance calculation
              if (testX < 0) testX = boardWidth - 1;
              if (testX >= boardWidth) testX = 0;
              if (testY < 0) testY = boardHeight - 1;
              if (testY >= boardHeight) testY = 0;

              int distance = (testX - pacmanX).abs() + (testY - pacmanY).abs();
              if (distance < bestDistance) {
                bestDistance = distance;
                bestDirection = dir;
              }
            }
            chosenDirection = bestDirection;
          } else {
            // Random movement
            chosenDirection =
                possibleMoves[random.nextInt(possibleMoves.length)];
          }
        }

        // Execute movement
        switch (chosenDirection) {
          case 0:
            ghost.x++;
            break;
          case 1:
            ghost.y++;
            break;
          case 2:
            ghost.x--;
            break;
          case 3:
            ghost.y--;
            break;
        }

        // Handle wraparound
        if (ghost.x < 0) ghost.x = boardWidth - 1;
        if (ghost.x >= boardWidth) ghost.x = 0;
        if (ghost.y < 0) ghost.y = boardHeight - 1;
        if (ghost.y >= boardHeight) ghost.y = 0;
      }
    }
  }

  void checkCollisions() {
    for (var ghost in ghosts) {
      if (ghost.x == pacmanX && ghost.y == pacmanY) {
        if (ghost.vulnerable) {
          // Eat vulnerable ghost
          score += 200;
          ghost.x = 9;
          ghost.y = 9;
          ghost.vulnerable = false;
          ghost.vulnerableTimer = 0;
        } else {
          // Pacman caught by ghost
          lives--;
          if (lives <= 0) {
            gameOver = true;
            gameRunning = false;
            gameTimer?.cancel();
          } else {
            // Reset positions for next life
            pacmanX = 9;
            pacmanY = 15;
            initializeGhosts();
          }
        }
      }
    }
  }

  void checkWinCondition() {
    // Win level when reaching target score
    if (score >= targetScore) {
      levelComplete = true;
      gameRunning = false;
      gameTimer?.cancel();

      // Save completed level
      _saveCompletedLevel(level);

      // Show level complete after frame finishes
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  backgroundColor: Colors.black.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.yellow, width: 2),
                  ),
                  title: const Text(
                    'LEVEL COMPLETE!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Level $level Finished!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Next: Level ${level + 1}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context).pop(); // Return to home
                          },
                          child: const Text('HOME'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onPressed: nextLevel,
                          child: const Text(
                            'CONTINUE',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          );
        }
      });
    }
  }

  void nextLevel() {
    Navigator.of(context).pop(); // Close dialog

    level++;
    lives++; // Bonus life per level

    // Reset for next level
    pacmanX = 9;
    pacmanY = 15;
    pacmanDirection = 0;
    nextDirection = 0;
    levelComplete = false;

    initializeBoard();
    initializeGhosts();
    startGame();
    setState(() {});
  }

  void changeDirection(int direction) {
    if (gameRunning && !gameOver && !levelComplete) {
      nextDirection = direction;
    }
  }

  void handlePanStart(DragStartDetails details) {
    panStart = details.localPosition;
  }

  void handlePanEnd(DragEndDetails details) {
    if (panStart == null) return;

    final Offset panEnd = details.localPosition;
    final Offset difference = panEnd - panStart!;

    // Check minimum swipe distance
    if (difference.distance < minSwipeDistance) return;

    // Determine direction based on largest component
    if (difference.dx.abs() > difference.dy.abs()) {
      // Horizontal swipe
      changeDirection(difference.dx > 0 ? 0 : 2); // Right or Left
    } else {
      // Vertical swipe
      changeDirection(difference.dy > 0 ? 1 : 3); // Down or Up
    }

    panStart = null;
  }

  void resetGame() {
    gameTimer?.cancel();

    score = 0;
    level =
        widget.startLevel > 0
            ? widget.startLevel
            : 1; // Reset to starting level with validation
    lives = 3;
    pacmanX = 9;
    pacmanY = 15;
    pacmanDirection = 0;
    nextDirection = 0;
    gameOver = false;
    levelComplete = false;

    initializeBoard();
    initializeGhosts();
    startGame();
    setState(() {});
  }

  Widget buildCell(int x, int y) {
    int cellType = board[y][x];

    // Pacman character
    if (pacmanX == x && pacmanY == y) {
      String pacmanChar = '●';
      switch (pacmanDirection) {
        case 0:
          pacmanChar = '▶';
          break; // right
        case 1:
          pacmanChar = '▼';
          break; // down
        case 2:
          pacmanChar = '◀';
          break; // left
        case 3:
          pacmanChar = '▲';
          break; // up
      }

      return Container(
        margin: const EdgeInsets.all(0.5),
        decoration: const BoxDecoration(
          color: Colors.yellow,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FittedBox(
            child: Text(
              pacmanChar,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // Ghost characters
    for (var ghost in ghosts) {
      if (ghost.x == x && ghost.y == y) {
        return Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: ghost.vulnerable ? Colors.blue.shade700 : ghost.color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FittedBox(
              child: Text(
                ghost.vulnerable ? '💙' : '👻',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      }
    }

    // Maze elements
    switch (cellType) {
      case 1: // Wall
        return Container(
          margin: const EdgeInsets.all(0.2),
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      case 2: // Small pellet
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircleAvatar(radius: 1.5, backgroundColor: Colors.white),
          ),
        );
      case 3: // Power pellet
        return Container(
          color: Colors.black,
          child: Center(
            child: CircleAvatar(
              radius: 4,
              backgroundColor: Colors.yellow,
              child: const CircleAvatar(
                radius: 2.5,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        );
      case 4: // Ghost house
        return Container(color: Colors.grey.shade600);
      default: // Empty space
        return Container(color: Colors.black);
    }
  }

  Widget buildFloatingStats() {
    return Stack(
      children: [
        // Back Button - Top Left
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ),

        // Score - Top Center Left
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 80,
          child: _buildStatTile('SCORE', '$score', Colors.yellow),
        ),

        // Level - Top Center
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: MediaQuery.of(context).size.width / 2 - 35,
          child: _buildStatTile('LEVEL', '$level', Colors.green),
        ),

        // Lives - Top Right
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 20,
          child: _buildStatTile('LIVES', '$lives', Colors.red),
        ),

        // Pellets Progress - Bottom Left
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 50,
          left: 20,
          child: _buildStatTile(
            'EATEN',
            '${totalPellets - pellets}/$totalPellets',
            Colors.cyan,
          ),
        ),

        // Target - Bottom Right
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 50,
          right: 20,
          child: _buildStatTile('TARGET', '$targetScore', Colors.orange),
        ),

        // Swipe Instructions - Bottom Center
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Text(
              'SWIPE TO MOVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Game Over Overlay
        if (gameOver)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Final Score: $score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Reached Level: $level',
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'HOME',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: resetGame,
                          child: const Text(
                            'PLAY AGAIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game Board - True Full Screen (no SafeArea constraints)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: handlePanStart,
              onPanEnd: handlePanEnd,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: boardWidth,
                    childAspectRatio:
                        MediaQuery.of(context).size.width /
                        MediaQuery.of(context).size.height *
                        boardHeight /
                        boardWidth,
                  ),
                  itemCount: boardWidth * boardHeight,
                  itemBuilder: (context, index) {
                    int x = index % boardWidth;
                    int y = index ~/ boardWidth;
                    return buildCell(x, y);
                  },
                ),
              ),
            ),
          ),

          // Floating Stats Overlay
          buildFloatingStats(),
        ],
      ),
    );
  }
}

class Ghost {
  int x, y;
  Color color;
  int id;
  bool vulnerable = false;
  int vulnerableTimer = 0;

  Ghost(this.x, this.y, this.color, this.id);
}
