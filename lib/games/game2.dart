import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

class Game2Page extends StatefulWidget {
  const Game2Page({super.key});

  @override
  State<Game2Page> createState() => _Game2PageState();
}

class _Game2PageState extends State<Game2Page> with TickerProviderStateMixin {
  static const int boardWidth = 10;
  static const int boardHeight = 20;
  static const int previewSize = 4;

  // Game state
  List<List<int>> board = [];
  List<List<int>> currentPiece = [];
  List<List<int>> nextPiece = [];
  int currentX = 0;
  int currentY = 0;
  int score = 0;
  int level = 1;
  int linesCleared = 0;
  bool gameOver = false;
  bool isPaused = false;
  Timer? gameTimer;

  // Swipe control variables
  bool _hasProcessedHorizontalSwipe = false;
  bool _hasProcessedVerticalSwipe = false;
  double _initialSwipeX = 0.0;
  double _initialSwipeY = 0.0;

  // Game speed (milliseconds between drops)
  int get dropSpeed {
    switch (level) {
      case 1:
        return 800;
      case 2:
        return 700;
      case 3:
        return 600;
      case 4:
        return 500;
      case 5:
        return 400;
      case 6:
        return 350;
      case 7:
        return 300;
      case 8:
        return 250;
      case 9:
        return 200;
      case 10:
        return 150;
      default:
        return 100;
    }
  }

  // Tetris pieces (I, O, T, S, Z, J, L)
  static const List<List<List<List<int>>>> pieces = [
    // I piece
    [
      [
        [1, 1, 1, 1],
      ],
      [
        [1],
        [1],
        [1],
        [1],
      ],
    ],
    // O piece
    [
      [
        [1, 1],
        [1, 1],
      ],
    ],
    // T piece
    [
      [
        [0, 1, 0],
        [1, 1, 1],
      ],
      [
        [1, 0],
        [1, 1],
        [1, 0],
      ],
      [
        [1, 1, 1],
        [0, 1, 0],
      ],
      [
        [0, 1],
        [1, 1],
        [0, 1],
      ],
    ],
    // S piece
    [
      [
        [0, 1, 1],
        [1, 1, 0],
      ],
      [
        [1, 0],
        [1, 1],
        [0, 1],
      ],
    ],
    // Z piece
    [
      [
        [1, 1, 0],
        [0, 1, 1],
      ],
      [
        [0, 1],
        [1, 1],
        [1, 0],
      ],
    ],
    // J piece
    [
      [
        [1, 0, 0],
        [1, 1, 1],
      ],
      [
        [1, 1],
        [1, 0],
        [1, 0],
      ],
      [
        [1, 1, 1],
        [0, 0, 1],
      ],
      [
        [0, 1],
        [0, 1],
        [1, 1],
      ],
    ],
    // L piece
    [
      [
        [0, 0, 1],
        [1, 1, 1],
      ],
      [
        [1, 0],
        [1, 0],
        [1, 1],
      ],
      [
        [1, 1, 1],
        [1, 0, 0],
      ],
      [
        [1, 1],
        [0, 1],
        [0, 1],
      ],
    ],
  ];

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    initializeGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void initializeGame() {
    // Initialize board
    board = List.generate(boardHeight, (i) => List.filled(boardWidth, 0));

    // Generate first pieces
    generateNewPiece();
    generateNextPiece();

    // Start game loop
    startGameLoop();
  }

  void startGameLoop() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(milliseconds: dropSpeed), (timer) {
      if (!isPaused && !gameOver) {
        movePieceDown();
      }
    });
  }

  void generateNewPiece() {
    if (nextPiece.isEmpty) {
      generateNextPiece();
    }

    currentPiece = List.from(nextPiece);
    currentX = boardWidth ~/ 2 - currentPiece[0].length ~/ 2;
    currentY = 0;

    generateNextPiece();

    // Check for game over
    if (!canPlacePiece(currentPiece, currentX, currentY)) {
      gameOver = true;
      gameTimer?.cancel();
    }
  }

  void generateNextPiece() {
    int pieceIndex = random.nextInt(pieces.length);
    int rotationIndex = random.nextInt(pieces[pieceIndex].length);
    nextPiece =
        pieces[pieceIndex][rotationIndex]
            .map((row) => List<int>.from(row))
            .toList();
  }

  bool canPlacePiece(List<List<int>> piece, int x, int y) {
    for (int row = 0; row < piece.length; row++) {
      for (int col = 0; col < piece[row].length; col++) {
        if (piece[row][col] == 1) {
          int boardX = x + col;
          int boardY = y + row;

          // Check boundaries and existing pieces
          if (boardX < 0 ||
              boardX >= boardWidth ||
              boardY >= boardHeight ||
              (boardY >= 0 &&
                  boardY < boardHeight &&
                  board[boardY][boardX] != 0)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void placePiece() {
    for (int row = 0; row < currentPiece.length; row++) {
      for (int col = 0; col < currentPiece[row].length; col++) {
        if (currentPiece[row][col] == 1) {
          int boardX = currentX + col;
          int boardY = currentY + row;
          // Only place pieces within the visible board area
          if (boardY >= 0 &&
              boardY < boardHeight &&
              boardX >= 0 &&
              boardX < boardWidth) {
            board[boardY][boardX] = 1;
          }
        }
      }
    }
  }

  void movePieceDown() {
    if (canPlacePiece(currentPiece, currentX, currentY + 1)) {
      setState(() {
        currentY++;
      });
    } else {
      // Piece has hit bottom or another piece
      placePiece();
      clearLines();
      generateNewPiece();
      setState(() {});
    }
  }

  void movePieceLeft() {
    if (canPlacePiece(currentPiece, currentX - 1, currentY)) {
      setState(() {
        currentX--;
      });
    }
  }

  void movePieceRight() {
    if (canPlacePiece(currentPiece, currentX + 1, currentY)) {
      setState(() {
        currentX++;
      });
    }
  }

  void rotatePiece() {
    List<List<int>> rotated = List.generate(
      currentPiece[0].length,
      (i) => List.generate(
        currentPiece.length,
        (j) => currentPiece[currentPiece.length - 1 - j][i],
      ),
    );

    if (canPlacePiece(rotated, currentX, currentY)) {
      setState(() {
        currentPiece = rotated;
      });
    }
  }

  void dropPiece() {
    while (canPlacePiece(currentPiece, currentX, currentY + 1)) {
      currentY++;
    }
    // After dropping, place the piece immediately
    placePiece();
    clearLines();
    generateNewPiece();
    setState(() {});
  }

  void clearLines() {
    int linesCleared = 0;

    for (int row = boardHeight - 1; row >= 0; row--) {
      bool isLineFull = true;
      for (int col = 0; col < boardWidth; col++) {
        if (board[row][col] == 0) {
          isLineFull = false;
          break;
        }
      }

      if (isLineFull) {
        board.removeAt(row);
        board.insert(0, List.filled(boardWidth, 0));
        linesCleared++;
        row++; // Check the same row again
      }
    }

    if (linesCleared > 0) {
      this.linesCleared += linesCleared;
      score += linesCleared * 100 * level;

      // Level up every 10 lines
      int newLevel = (this.linesCleared ~/ 10) + 1;
      if (newLevel > level && newLevel <= 10) {
        level = newLevel;
        startGameLoop(); // Restart timer with new speed
      }
    }
  }

  void resetGame() {
    setState(() {
      board = List.generate(boardHeight, (i) => List.filled(boardWidth, 0));
      score = 0;
      level = 1;
      linesCleared = 0;
      gameOver = false;
      isPaused = false;
    });
    generateNewPiece();
    generateNextPiece();
    startGameLoop();
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  List<List<int>> getBoardWithCurrentPiece() {
    List<List<int>> displayBoard =
        board.map((row) => List<int>.from(row)).toList();

    for (int row = 0; row < currentPiece.length; row++) {
      for (int col = 0; col < currentPiece[row].length; col++) {
        if (currentPiece[row][col] == 1) {
          int boardX = currentX + col;
          int boardY = currentY + row;
          if (boardY >= 0 &&
              boardY < boardHeight &&
              boardX >= 0 &&
              boardX < boardWidth) {
            displayBoard[boardY][boardX] =
                2; // Different color for current piece
          }
        }
      }
    }

    return displayBoard;
  }

  Color getCellColor(int value) {
    switch (value) {
      case 0:
        return Colors.black;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red; // Current piece
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (!gameOver && !isPaused) {
            rotatePiece(); // Tap to rotate clockwise
          }
        },
        onPanStart: (details) {
          // Reset swipe tracking and store initial position
          _hasProcessedHorizontalSwipe = false;
          _hasProcessedVerticalSwipe = false;
          _initialSwipeX = details.globalPosition.dx;
          _initialSwipeY = details.globalPosition.dy;
        },
        onPanUpdate: (details) {
          if (!gameOver && !isPaused) {
            // Calculate total distance from start of swipe
            double totalDeltaX = details.globalPosition.dx - _initialSwipeX;
            double totalDeltaY = details.globalPosition.dy - _initialSwipeY;

            // Horizontal movement - only process once per swipe
            if (!_hasProcessedHorizontalSwipe && totalDeltaX.abs() > 30) {
              if (totalDeltaX > 0) {
                movePieceRight();
              } else {
                movePieceLeft();
              }
              _hasProcessedHorizontalSwipe = true;
              // Reset initial X position for potential additional moves
              _initialSwipeX = details.globalPosition.dx;
            }

            // Vertical movement - only process once per swipe
            if (!_hasProcessedVerticalSwipe && totalDeltaY > 40) {
              dropPiece();
              _hasProcessedVerticalSwipe = true;
            }
          }
        },
        onPanEnd: (details) {
          // Reset flags when swipe ends
          _hasProcessedHorizontalSwipe = false;
          _hasProcessedVerticalSwipe = false;
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Game board - Full screen
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: boardWidth,
                  ),
                  itemCount: boardWidth * boardHeight,
                  itemBuilder: (context, index) {
                    int row = index ~/ boardWidth;
                    int col = index % boardWidth;
                    List<List<int>> displayBoard = getBoardWithCurrentPiece();

                    return Container(
                      decoration: BoxDecoration(
                        color: getCellColor(displayBoard[row][col]),
                        border: Border.all(
                          color: Colors.grey[800]!,
                          width: 0.2,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Minimal UI overlay - Top left corner
              Positioned(
                top: 50,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: $score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Level: $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Lines: $linesCleared',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Next piece preview - Top right corner
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'NEXT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: previewSize,
                              ),
                          itemCount: previewSize * previewSize,
                          itemBuilder: (context, index) {
                            int row = index ~/ previewSize;
                            int col = index % previewSize;

                            bool isPartOfPiece = false;
                            if (nextPiece.isNotEmpty &&
                                row < nextPiece.length &&
                                col < nextPiece[0].length) {
                              isPartOfPiece = nextPiece[row][col] == 1;
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color:
                                    isPartOfPiece
                                        ? Colors.blue
                                        : Colors.transparent,
                                border: Border.all(
                                  color: Colors.grey[600]!,
                                  width: 0.2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pause/Menu button - Top center
              Positioned(
                top: 50,
                left: MediaQuery.of(context).size.width / 2 - 20,
                child: GestureDetector(
                  onTap: togglePause,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Instructions - Bottom center (only show briefly at start)
              if (!gameOver)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TAP: Rotate • SWIPE: Move • SWIPE DOWN: Fast Drop',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              // Game over overlay
              if (gameOver)
                Container(
                  color: Colors.black87,
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
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Final Score: $score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          'Level Reached: $level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          'Lines Cleared: $linesCleared',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: resetGame,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PLAY AGAIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'EXIT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Pause overlay
              if (isPaused && !gameOver)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'PAUSED',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: togglePause,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'RESUME',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
