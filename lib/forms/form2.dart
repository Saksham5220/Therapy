import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form3.dart';

class Form2 extends StatefulWidget {
  final int currentQuestionIndex;
  final List<String> answers;
  final String? userId;

  const Form2({
    super.key,
    required this.currentQuestionIndex,
    required this.answers,
    this.userId,
  });

  @override
  State<Form2> createState() => _Form2State();
}

class _Form2State extends State<Form2> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedAnswer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final DatabaseReference _db = FirebaseDatabase.instance.ref();


  final List<Map<String, dynamic>> _options = [
    {
      "text": "This is fine.",
      "description": "Dog sitting in burning room",
      "color": Colors.orange.shade300,
      "backgroundColor": Colors.orange.shade50,
    },
    {
      "text": "Me pretending to be okay while lowkey spiraling",
      "description": "Person with spiral above head",
      "color": Colors.blue.shade400,
      "backgroundColor": Colors.blue.shade50,
    },
    {
      "text": "Brain: let's overthink everything. Me: deal.",
      "description": "Brain and person conversation",
      "color": Colors.pink.shade300,
      "backgroundColor": Colors.pink.shade50,
    },
    {
      "text": "Introvert energy: plans got cancelled 😌",
      "description": "Happy person with closed eyes",
      "color": Colors.amber.shade400,
      "backgroundColor": Colors.amber.shade50,
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

  Future<void> _saveAnswerToFirebase(String answer) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final userId = firebaseUser?.uid
      ?? widget.userId
      ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';

  final responsesRef = _db
      .child('users')
      .child(userId)
      .child('survey_responses');

  await responsesRef.push().set({
    'questionIndex': widget.currentQuestionIndex,
    'question': '…your question text here…',
    'answer': answer,
    'timestamp': ServerValue.timestamp,
  });
}



  void _handleNext() async {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer to continue')),
      );
      return;
    }

    // Save to Firebase
    await _saveAnswerToFirebase(_selectedAnswer!);

    List<String> updatedAnswers = List.from(widget.answers)
      ..add(_selectedAnswer!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Form3(
          currentQuestionIndex: widget.currentQuestionIndex + 1,
          answers: updatedAnswers,
        ),
      ),
    );
  }

  void _handleNoneOfTheAbove() async {
    const noneAnswer = "None of the above";
    
    // Save to Firebase
    await _saveAnswerToFirebase(noneAnswer);

    List<String> updatedAnswers = List.from(widget.answers)
      ..add(noneAnswer);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Form3(
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
              Colors.white, Colors.yellow.shade200, _controller.value)!;

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
                // Back button and top section
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
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
                
                // Main content card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        // Question text
                        const Text(
                          "Pick an image that matches your current vibe:",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        // Options in 2x2 grid
                        Expanded(
                          child: Column(
                            children: [
                              // First row
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildMemeOption(0),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMemeOption(1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Second row
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildMemeOption(2),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMemeOption(3),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // None of the above button
                              GestureDetector(
                                onTap: () {
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    _handleNoneOfTheAbove();
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: const Text(
                                    "None of the above",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildMemeOption(int index) {
    final option = _options[index];
    final isSelected = _selectedAnswer == option["text"];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnswer = option["text"];
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          _handleNext();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected 
              ? option["color"].withOpacity(0.1)
              : option["backgroundColor"],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? option["color"]
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option["color"].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title text
            Text(
              option["text"],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Placeholder for meme image (you can replace with actual images)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: option["color"].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getMemeIcon(index),
                      size: 40,
                      color: option["color"],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option["description"],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMemeIcon(int index) {
    switch (index) {
      case 0:
        return Icons.local_fire_department; // "This is fine" - fire
      case 1:
        return Icons.psychology; // Spiral/mental state
      case 2:
        return Icons.psychology_alt; // Brain overthinking
      case 3:
        return Icons.home; // Introvert at home
      default:
        return Icons.emoji_emotions;
    }
  }
}