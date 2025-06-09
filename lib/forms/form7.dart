// lib/forms/form7.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form8.dart';

class Form7 extends StatefulWidget {
  final int currentQuestionIndex;
  final List<String> answers;

  const Form7({
    super.key,
    required this.currentQuestionIndex,
    required this.answers,
  });

  @override
  State<Form7> createState() => _Form7State();
}

class _Form7State extends State<Form7> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedAnswer;

  // Realtime Database root reference
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final List<String> _options = [
    "🧱 Pretty closed off, tbh",
    "🧊 I take time to warm up",
    "🍇 I open up with the right people",
    "🧁 Soft center with some effort",
    "Soft center with some effort",
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

  /// Save single answer into Firebase Realtime Database
  Future<void> _saveAnswerToFirebase(String answer) async {
    final userId = FirebaseAuth.instance.currentUser?.uid
        ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    final responsesRef = _db
        .child('users')
        .child(userId)
        .child('survey_responses');
    await responsesRef.push().set({
      'questionIndex': widget.currentQuestionIndex,
      'question': "How do you feel about opening up emotionally?",
      'answer': answer,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Handle Next: validate, save to Firebase, then navigate
  Future<void> _handleNext() async {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option')),
      );
      return;
    }

    // Save the selected answer
    await _saveAnswerToFirebase(_selectedAnswer!);

    // Navigate with updated answers
    final updatedAnswers = [...widget.answers, _selectedAnswer!];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Form8(
          currentQuestionIndex: widget.currentQuestionIndex + 1,
          answers: updatedAnswers,
        ),
      ),
    );
  }

  Widget _buildTile(String text, {bool large = false}) {
    final selected = _selectedAnswer == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedAnswer = text),
      child: Container(
        width: large ? double.infinity : null,
        padding: EdgeInsets.symmetric(
            vertical: large ? 20 : 18, horizontal: large ? 18 : 16),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.shade100 : Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? Colors.deepOrange : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
        builder: (_, child) {
          final top = Color.lerp(
            const Color.fromARGB(255, 215, 203, 92),
            Colors.white,
            _controller.value,
          )!;
          final bottom = Color.lerp(
            Colors.white,
            Colors.yellow.shade200,
            _controller.value,
          )!;
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
                // Back & progress row
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Colors.black87,
                        ),
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
                const SizedBox(height: 40),
                // Main card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "How do you feel about opening up emotionally?",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildTile(_options[0]),
                        const SizedBox(height: 14),
                        _buildTile(_options[1]),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildTile(_options[2])),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTile(_options[3])),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildTile(_options[4], large: true),
                        const SizedBox(height: 24),
                        if (_selectedAnswer != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
