// lib/forms/form10.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:therapy_ai/Pages/home.dart';

class Form10 extends StatefulWidget {
  final int currentQuestionIndex;
  final List<String> answers;

  const Form10({
    super.key,
    required this.currentQuestionIndex,
    required this.answers,
  });

  @override
  State<Form10> createState() => _Form10State();
}

class _Form10State extends State<Form10> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedAnswer;

  // Real-time Database root reference
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final _choices = <String>[
    'Just need someone (or something) to listen',
    'Better coping tools for daily stress',
    'Help untangling my thoughts',
    'Building emotional resilience',
    "I'm not sure yet, but open to exploring",
  ];

  final _colors = <Color>[
    Color(0xFFFFE0B2),
    Color(0xFFC8E6C9),
    Color(0xFFBBDEFB),
    Color(0xFFFFF9C4),
    Color(0xFFD1C4E9),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Save the selected answer into Firebase Realtime Database
  Future<void> _saveAnswerToFirebase() async {
    final userId = FirebaseAuth.instance.currentUser?.uid
        ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    final responsesRef = _db.child('users').child(userId).child('survey_responses');

    await responsesRef.push().set({
      'questionIndex': widget.currentQuestionIndex,
      'question': 'What are you hoping to get from this AI therapy journey?',
      'answer': _selectedAnswer,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Handle saving and navigation
  Future<void> _saveAndNext() async {
    if (_selectedAnswer == null) return;
    // save to Firebase first
    await _saveAnswerToFirebase();
    // merge answers
    final all = List<String>.from(widget.answers)..add(_selectedAnswer!);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  Widget _hexTile(String text, Color baseColor) {
    final sel = _selectedAnswer == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedAnswer = text),
      child: ClipPath(
        clipper: _HexClipper(_hexPath),
        child: Container(
          width: 130,
          height: 110,
          padding: const EdgeInsets.all(10),
          color: sel ? baseColor.withOpacity(.7) : baseColor,
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Path _hexPath(Rect r) {
    final w = r.width, h = r.height;
    return Path()
      ..moveTo(w * .25, 0)
      ..lineTo(w * .75, 0)
      ..lineTo(w, h * .5)
      ..lineTo(w * .75, h)
      ..lineTo(w * .25, h)
      ..lineTo(0, h * .5)
      ..close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final top = Color.lerp(const Color(0xFFD7CB5C), Colors.white, _controller.value)!;
          final bottom = Color.lerp(Colors.white, Colors.yellow.shade200, _controller.value)!;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, bottom],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // back arrow + full progress
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withOpacity(.3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.9),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Text(
                            'What are you hoping to get from this AI\ntherapy journey?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _hexTile(_choices[0], _colors[0]),
                                  _hexTile(_choices[1], _colors[1]),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _hexTile(_choices[2], _colors[2]),
                              const SizedBox(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _hexTile(_choices[3], _colors[3]),
                                  _hexTile(_choices[4], _colors[4]),
                                ],
                              ),
                              const SizedBox(height: 40),
                              if (_selectedAnswer != null)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saveAndNext,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepOrange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      "Next",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  final Path Function(Rect) builder;
  const _HexClipper(this.builder);

  @override
  Path getClip(Size size) => builder(Offset.zero & size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
