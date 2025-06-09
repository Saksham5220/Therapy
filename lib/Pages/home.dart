// lib/screens/home.dart

import 'package:flutter/material.dart';
import 'chat.dart';
import 'games.dart';
import 'journal.dart';
import 'profile.dart';
import '../screens/gradient_playlist_section.dart';
import '../screens/gradient_daily_dose.dart';

// Safe wrapper for components that might cause issues
class SafeWidget extends StatelessWidget {
  final Widget child;
  final String componentName;

  const SafeWidget({
    super.key,
    required this.child,
    required this.componentName,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e, stackTrace) {
          debugPrint('Error in $componentName: $e');
          debugPrint('Stack trace: $stackTrace');
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error in $componentName',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Component temporarily disabled. Check debug console for details.',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// Safe section title component
class SafeSectionTitle extends StatelessWidget {
  final String title;

  const SafeSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
    );
  }
}

// SafeDailyDoseSection and SafePlaylistSection are already provided via
// gradient_daily_dose_section.dart and gradient_playlist_section.dart.

// Definition for SafeDeepMindReads (placeholder if an error occurs)
class SafeDeepMindReads extends StatelessWidget {
  const SafeDeepMindReads({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommended Reading',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Mindfulness articles and resources'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.book, color: Colors.brown),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The Power of Now - Daily Reflection',
                    style: TextStyle(color: Colors.brown.shade700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Combined Home Page Content with error boundaries
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafeSectionTitle("Here's what your mind needs today"),
            const SafeSectionTitle("Your daily dose"),
            const SizedBox(height: 8),
            SafeWidget(
              componentName: "GradientDailyDoseSection",
              child: const GradientDailyDoseSection(),
            ),
            const SizedBox(height: 24),

            const SafeSectionTitle("Your calm soundtrack"),
            const SizedBox(height: 12),
            SafeWidget(
              componentName: "GradientPlaylistSection",
              child: const GradientPlaylistSection(),
            ),
            const SizedBox(height: 24),

            const SafeSectionTitle("Deep Mind Reads"),
            const SizedBox(height: 12),
            SafeWidget(
              componentName: "DeepMindReads",
              child: const SafeDeepMindReads(),
            ),
          ],
        ),
      ),
    );
  }
}

// Main Home Page with bottom navigation and animated background
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomePageContent(),
    chatPage(),
    gamePage(),
    JournalPage(),
    profilePage(),
  ];

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
          body: _pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.brown,
            unselectedItemColor: Colors.brown.withOpacity(0.4),
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'Games'),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
