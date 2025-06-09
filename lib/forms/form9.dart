// lib/forms/form9.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form10.dart';

class Form9 extends StatefulWidget {
  final int currentQuestionIndex;
  final List<String> answers;

  const Form9({
    super.key,
    required this.currentQuestionIndex,
    required this.answers,
  });

  @override
  State<Form9> createState() => _Form9State();
}

class _Form9State extends State<Form9> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedAnswer;

  // Realtime Database root reference
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final _choices = <Map<String, dynamic>>[
    {'icon': Icons.hotel,            'text': 'Got out of bed on a hard day'},
    {'icon': Icons.checklist_rtl,    'text': 'Finished something I kept putting off'},
    {'icon': Icons.self_improvement, 'text': 'Made time for myself (even if it was 5 mins)'},
    {'icon': Icons.block,            'text': 'Said “no” to something that drained me'},
    {'icon': Icons.phone_forwarded,  'text': 'Reached out to someone'},
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
      'question': "What’s a small ‘win’ you’re proud of recently?",
      'answer': answer,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Handle Next: validate, save, then navigate replacement
  Future<void> _next() async {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an option first')),
      );
      return;
    }

    // 1) Save to Firebase
    await _saveAnswerToFirebase(_selectedAnswer!);

    // 2) Navigate on completion
    final updated = [...widget.answers, _selectedAnswer!];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Form10(
          currentQuestionIndex: widget.currentQuestionIndex + 1,
          answers: updated,
        ),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> c) {
    final sel = _selectedAnswer == c['text'];
    return GestureDetector(
      onTap: () => setState(() => _selectedAnswer = c['text']),
      child: Container(
        decoration: BoxDecoration(
          color: sel ? Colors.orange.shade100 : Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: sel ? Colors.deepOrange : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(c['icon'] as IconData, size: 38),
            const SizedBox(height: 6),
            Text(
              c['text'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const progress = 0.9; // 9/10
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final top = Color.lerp(
              const Color(0xFFD7CB5C),
              Colors.white,
              _controller.value)!;
          final bottom = Color.lerp(
              Colors.white,
              Colors.yellow.shade200,
              _controller.value)!;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [top, bottom]),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // back + progress bar
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
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const Text(
                          "What’s a small “win” you’re proud of recently?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: GridView.builder(
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.98,
                            ),
                            itemCount: _choices.length,
                            itemBuilder: (_, i) => _tile(_choices[i]),
                          ),
                        ),
                        if (_selectedAnswer != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _next,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16))),
                              child: const Text(
                                "Next",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600),
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