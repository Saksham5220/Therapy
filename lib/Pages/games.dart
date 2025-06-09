// import 'package:flutter/material.dart';

// class gamePage extends StatefulWidget {
//   const gamePage({super.key});

//   @override
//   State<gamePage> createState() => _GamePageState();
// }

// class _GamePageState extends State<gamePage>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Color?> _colorAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 4),
//     )..repeat(reverse: true);

//     _colorAnimation = ColorTween(
//       begin: Colors.yellow.shade50,
//       end: Colors.yellow.shade200,
//     ).animate(_controller);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _colorAnimation,
//       builder: (context, child) {
//         return Scaffold(
//           backgroundColor: _colorAnimation.value,
//           body: const JournalPageContent(),
//         );
//       },
//     );
//   }
// }

// class JournalPageContent extends StatelessWidget {
//   const JournalPageContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: const [
//             SectionTitle("Your Journal"),
//             SizedBox(height: 8),
//             Text("Start writing your thoughts here..."),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class SectionTitle extends StatelessWidget {
//   final String text;
//   const SectionTitle(this.text, {super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//           color: Colors.brown,
//         ),
//       ),
//     );
//   }
// }
