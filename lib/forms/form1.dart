// lib/forms/form1.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form2.dart';

class Form1 extends StatefulWidget {
  final int currentQuestionIndex;
  final List<String> answers;
  final String? userId;

  const Form1({
    super.key,
    required this.currentQuestionIndex,
    required this.answers,
    this.userId,
  });

  @override
  State<Form1> createState() => _Form1State();
}

class _Form1State extends State<Form1> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedAnswer;

  // Realtime Database root reference
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final List<Map<String, dynamic>> _options = [
    {
      "text": "Clear skies, feeling good",
      "icon": Icons.wb_sunny,
      "color": Colors.orange,
    },
    {
      "text": "A little cloud, but managing",
      "icon": Icons.cloud,
      "color": Colors.blueAccent,
    },
    {
      "text": "Rainy with occasional overthinking",
      "icon": Icons.grain,
      "color": Colors.blue,
    },
    {
      "text": "Total mental tornado",
      "icon": Icons.tornado,
      "color": Colors.grey,
    },
    {
      "text": "Numb or frozen, can't tell",
      "icon": Icons.ac_unit,
      "color": Colors.cyan,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAnswerToFirebase(String answer) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final userId = firebaseUser?.uid
        ?? widget.userId
        ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';

    // Build the path: /users/<userId>/survey_responses/<pushId>
    final responsesRef = _db.child('users').child(userId).child('survey_responses');

    // Push a new child with auto‑ID
    await responsesRef.push().set({
      'questionIndex': widget.currentQuestionIndex,
      'question':
          "If your mind were a weather forecast today, what would it be?",
      'answer': answer,
      'timestamp': ServerValue.timestamp,
    });
  }

  void _handleNext() {
    final updatedAnswers = List<String>.from(widget.answers)
      ..add(_selectedAnswer!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Form2(
          currentQuestionIndex: widget.currentQuestionIndex + 1,
          answers: updatedAnswers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.currentQuestionIndex + 1) / 10;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final topColor = Color.lerp(
              const Color.fromARGB(255, 215, 203, 92),
              Colors.white,
              _controller.value)!;
          final bottomColor =
              Color.lerp(Colors.white, Colors.yellow.shade200, _controller.value)!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 20, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
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
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          "If your mind were a weather forecast today, what would it be?",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _options.map((option) {
                            final isSelected = _selectedAnswer == option["text"];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              child: GestureDetector(
                                onTap: () async {
                                  setState(() => _selectedAnswer = option["text"]);
                                  await _saveAnswerToFirebase(_selectedAnswer!);
                                  _handleNext();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? option["color"].withOpacity(0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? option["color"]
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: option["color"].withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Icon(option["icon"],
                                            color: option["color"], size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option["text"],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
