// lib/forms/form4.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form5.dart';

class Form4 extends StatefulWidget {
  final int currentQuestionIndex;
  final List<String> answers;

  const Form4({
    super.key,
    required this.currentQuestionIndex,
    required this.answers,
  });

  @override
  State<Form4> createState() => _Form4State();
}

class _Form4State extends State<Form4> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Set<String> _selectedAnswers = {};

  // Realtime Database reference
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final List<String> _options = [
    "Work",
    "School",
    "Family",
    "Relationship",
    "Big life changes",
    "Social media",
    "New Overload",
    "Loneliness",
    "Addiction",
    "Overthinking",
    "Other",
    "Honestly, IDK"
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

  /// Save the selected answers to Firebase Realtime Database
  Future<void> _saveAnswersToFirebase() async {
    final userId = FirebaseAuth.instance.currentUser?.uid
        ?? 'anonymous_\${DateTime.now().millisecondsSinceEpoch}';
    final responsesRef = _db
        .child('users')
        .child(userId)
        .child('survey_responses');

    await responsesRef.push().set({
      'questionIndex': widget.currentQuestionIndex,
      'question': "What's been taking up most of your brain space lately?",
      'answer': _selectedAnswers.toList(),
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Handle Next button press
  Future<void> _handleNext() async {
    if (_selectedAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one answer')),
      );
      return;
    }

    // Save to Firebase before navigating
    await _saveAnswersToFirebase();

    final updatedAnswers = [...widget.answers, _selectedAnswers.join(', ')];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Form5(
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
          final bottomColor = Color.lerp(
              Colors.white,
              Colors.yellow.shade200,
              _controller.value)!;

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
                // Back button and progress bar
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

                // Main content
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
                          "What's been taking up most of your brain space lately?",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _options.map((option) {
                                final isSelected = _selectedAnswers.contains(option);
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    isSelected
                                        ? _selectedAnswers.remove(option)
                                        : _selectedAnswers.add(option);
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.orange.shade100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.deepOrange
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(option, style: const TextStyle(fontSize: 15)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_selectedAnswers.isNotEmpty)
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
