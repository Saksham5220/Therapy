import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget child;

  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Hide system UI for full screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // This helps trigger GIF animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _controller.forward();

    // Navigate to main app after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Restore system UI before navigating
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => widget.child,
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restore system UI when disposing
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove default padding and background
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/joy.gif',
          fit: BoxFit.cover, // This ensures the image covers the entire screen
          gaplessPlayback: true,
          // errorBuilder: (context, error, stackTrace) {
          // Fallback to PNG if GIF fails
          // return Image.asset(
          //   'assets/videos/joy.mp4',
          //   width: double.infinity,
          //   height: double.infinity,
          //   fit: BoxFit.cover,
          // );
          // },
        ),
      ),
    );
  }
}
