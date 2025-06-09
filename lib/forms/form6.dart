// lib/forms/form6.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form7.dart';

class Form6 extends StatefulWidget {
  final int currentQuestionIndex;
  final List<String> answers;

  const Form6({
    super.key,
    required this.currentQuestionIndex,
    required this.answers,
  });

  @override
  State<Form6> createState() => _Form6State();
}

class _Form6State extends State<Form6> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedAnswer;

  // Realtime Database root reference
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final List<Map<String, dynamic>> _options = <Map<String, dynamic>>[
    {'label': 'Spring: fresh start energy', 'icon': Icons.local_florist},
    {'label': 'Summer: full speed chaos', 'icon': Icons.wb_sunny},
    {'label': 'Fall: reflective & cozy', 'icon': Icons.eco},
    {'label': 'Winter: low energy, need a blanket', 'icon': Icons.ac_unit},
    {
      'label': 'Mixed season: unpredictable mood swings',
      'icon': Icons.air,
    },
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
  Future<void> _saveAnswerToFirebase(String answer) async {
    final userId = FirebaseAuth.instance.currentUser?.uid
        ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    final responsesRef = _db
        .child('users')
        .child(userId)
        .child('survey_responses');

    await responsesRef.push().set({
      'questionIndex': widget.currentQuestionIndex,
      'question': "If your life right now were a season, what would it be?",
      'answer': answer,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Handle Next button: validate, save, then navigate
  Future<void> _handleNext() async {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option')),
      );
      return;
    }

    // Save to Firebase before navigation
    await _saveAnswerToFirebase(_selectedAnswer!);

    final updatedAnswers = [...widget.answers, _selectedAnswer!];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Form7(
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
        builder: (ctx, child) {
          final top = Color.lerp(
              const Color.fromARGB(255, 215, 203, 92), Colors.white, _controller.value)!;
          final bottom = Color.lerp(
              Colors.white, Colors.yellow.shade200, _controller.value)!;
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
                // Back button and progress
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
                const SizedBox(height: 40),

                // Main survey card
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
                          "If your life right now were a season,\nwhat would it be?",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _options.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final opt = _options[i];
                              final label = opt['label'] as String;
                              final selected = _selectedAnswer == label;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedAnswer = label),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.orange.shade100 : Colors.yellow.shade100,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: selected ? Colors.deepOrange : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  child: Row(
                                    children: [
                                      Icon(opt['icon'] as IconData, size: 28),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
