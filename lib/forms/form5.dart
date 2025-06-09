// lib/forms/form5.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form6.dart';

class Form5 extends StatefulWidget {
  final int currentQuestionIndex;
  final List<String> answers;

  const Form5({
    super.key,
    required this.currentQuestionIndex,
    required this.answers,
  });

  @override
  State<Form5> createState() => _Form5State();
}

class _Form5State extends State<Form5> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Set<String> _selectedAnswers = {};

  // Realtime Database root reference
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final List<Map<String, dynamic>> _options = [
    {'label': 'Music',        'icon': Icons.music_note},
    {'label': 'Self-care',    'icon': Icons.spa},
    {'label': 'Cooking',      'icon': Icons.restaurant_menu},
    {'label': 'Exercise',     'icon': Icons.fitness_center},
    {'label': 'Talking',      'icon': Icons.chat_bubble_outline},
    {'label': 'Comfort Food', 'icon': Icons.fastfood},
    {'label': 'Other',        'icon': Icons.more_horiz},
    {'label': 'Scrolling',    'icon': Icons.phone_android},
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

  /// Save the selected answers into Firebase Realtime Database
  Future<void> _saveAnswersToFirebase() async {
    final userId = FirebaseAuth.instance.currentUser?.uid
        ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    final responsesRef = _db
        .child('users')
        .child(userId)
        .child('survey_responses');
    await responsesRef.push().set({
      'questionIndex': widget.currentQuestionIndex,
      'question': "When you're down, what usually helps you bounce back?",
      'answer': _selectedAnswers.toList(),
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Handle pressing Next: validate, save, then navigate
  Future<void> _handleNext() async {
    if (_selectedAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one option')),
      );
      return;
    }
    // save first
    await _saveAnswersToFirebase();
    // then navigate
    final updated = [...widget.answers, _selectedAnswers.join(', ')];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Form6(
          currentQuestionIndex: widget.currentQuestionIndex + 1,
          answers: updated,
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
          final top = Color.lerp(const Color.fromARGB(255, 215, 203, 92), Colors.white, _controller.value)!;
          final bottom = Color.lerp(Colors.white, Colors.yellow.shade200, _controller.value)!;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
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
                // Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "When you're down, what usually helps you bounce back?",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 32,
                            runSpacing: 32,
                            alignment: WrapAlignment.center,
                            children: _options.map((opt) {
                              final label = opt['label'] as String;
                              final selected = _selectedAnswers.contains(label);
                              return GestureDetector(
                                onTap: () => setState(() {
                                  if (selected) {
                                    _selectedAnswers.remove(label);
                                  } else {
                                    _selectedAnswers.add(label);
                                  }
                                }),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 70, width: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: selected ? Colors.orange.shade100 : Colors.white,
                                        border: Border.all(
                                          color: selected ? Colors.deepOrange : Colors.grey.shade300,
                                          width: 3,
                                        ),
                                      ),
                                      child: Icon(opt['icon'] as IconData, size: 28),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        label,
                                        style: const TextStyle(fontSize: 12.5),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),
                          if (_selectedAnswers.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text("Next", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              ),
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
