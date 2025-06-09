// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'available_games.dart'; // Import your games data

class gamePage extends StatefulWidget {
  const gamePage({super.key});

  @override
  State<gamePage> createState() => _GamePageState();
}

class _GamePageState extends State<gamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.yellow.shade50,
      end: Colors.yellow.shade200,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _colorAnimation.value,
          body: Stack(
            children: [
              const GamePageContent(),
              // Floating box positioned at the top
              Positioned(
                top: 55,
                left: 20,
                right: 20,
                child: Container(
                  margin: const EdgeInsets.only(top: 50),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.red.shade400],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Play for fun and to earn points!",
                    textAlign: TextAlign.center,
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
        );
      },
    );
  }
}

class GamePageContent extends StatelessWidget {
  const GamePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 100,
          bottom: 16,
        ), // Added top padding for floating box
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle("Your Games"),
            const SizedBox(height: 16),
            DynamicGameGrid(
              games: availableGames,
              onGameTap: (game) => _launchGame(context, game),
            ),
          ],
        ),
      ),
    );
  }

  void _launchGame(BuildContext context, dynamic game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => game.page ?? const GameNotFoundPage(),
      ),
    );
  }
}

class DynamicGameGrid extends StatelessWidget {
  final List<dynamic> games;
  final Function(dynamic) onGameTap;

  const DynamicGameGrid({
    super.key,
    required this.games,
    required this.onGameTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;

        // Calculate tile width to ensure full width usage
        double spacing = 12;
        int tilesPerRow = 2;
        double totalSpacing = spacing * (tilesPerRow - 1);
        double tileWidth = (screenWidth - totalSpacing) / tilesPerRow;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: tilesPerRow,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1.0, // Square tiles
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            return DynamicGameTile(
              game: games[index],
              screenWidth: tileWidth,
              onTap: () => onGameTap(games[index]),
            );
          },
        );
      },
    );
  }
}

class DynamicGameTile extends StatefulWidget {
  final dynamic game;
  final double screenWidth;
  final VoidCallback onTap;

  const DynamicGameTile({
    super.key,
    required this.game,
    required this.screenWidth,
    required this.onTap,
  });

  @override
  State<DynamicGameTile> createState() => _DynamicGameTileState();
}

class _DynamicGameTileState extends State<DynamicGameTile> {
  String _getGameImage(String? title) {
    print('Game title: $title'); // Debug print to see actual title
    switch (title?.toLowerCase()) {
      case 'pac-man':
        return 'assets/images/game1.png';
      case 'game2':
        return 'assets/images/game2.png';
      default:
        return widget.game.image ?? '';
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGameColors(widget.game.title),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getGameIcon(widget.game.title), size: 50, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            widget.game.title ?? 'Game',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Color> _getGameColors(String? title) {
    switch (title?.toLowerCase()) {
      case 'pac-man':
        return [Colors.yellow.shade600, Colors.orange.shade700];
      case 'memory match':
        return [Colors.blue.shade600, Colors.purple.shade700];
      case 'word quest':
        return [Colors.green.shade600, Colors.teal.shade700];
      case 'number ninja':
        return [Colors.red.shade600, Colors.pink.shade700];
      case 'color rush':
        return [Colors.pink.shade600, Colors.purple.shade700];
      case 'logic lab':
        return [Colors.indigo.shade600, Colors.blue.shade700];
      case 'speed tap':
        return [Colors.orange.shade600, Colors.red.shade700];
      case 'pattern pro':
        return [Colors.teal.shade600, Colors.green.shade700];
      case 'quiz champion':
        return [Colors.purple.shade600, Colors.indigo.shade700];
      case 'strategy master':
        return [Colors.brown.shade600, Colors.grey.shade700];
      default:
        return [Colors.grey.shade600, Colors.blueGrey.shade700];
    }
  }

  IconData _getGameIcon(String? title) {
    switch (title?.toLowerCase()) {
      case 'pac-man':
        return Icons.circle;
      case 'memory match':
        return Icons.psychology;
      case 'word quest':
        return Icons.text_fields;
      case 'number ninja':
        return Icons.calculate;
      case 'color rush':
        return Icons.palette;
      case 'logic lab':
        return Icons.lightbulb;
      case 'speed tap':
        return Icons.touch_app;
      case 'pattern pro':
        return Icons.pattern;
      case 'quiz champion':
        return Icons.quiz;
      case 'strategy master':
        return Icons.extension;
      default:
        return Icons.games;
    }
  }

  @override
  Widget build(BuildContext context) {
    String imagePath = _getGameImage(widget.game.title);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child:
                      imagePath.isNotEmpty
                          ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          )
                          : _buildPlaceholderImage(),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: Text(
                  widget.game.title ?? 'Unknown Game',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
    );
  }
}

class GameNotFoundPage extends StatelessWidget {
  const GameNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Not Found')),
      body: const Center(child: Text('Game could not be loaded')),
    );
  }
}
