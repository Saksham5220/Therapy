import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form4.dart';

class Form3 extends StatefulWidget {
  final int currentQuestionIndex;
  final List<String> answers;

  const Form3({
    super.key,
    required this.currentQuestionIndex,
    required this.answers,
  });

  @override
  State<Form3> createState() => _Form3State();
}

class _Form3State extends State<Form3> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _sliderValue = 2.0; // Default to middle option (Average day)
  String? _selectedAnswer;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();


  final List<Map<String, dynamic>> _options = [
    {
      "text": "Barely moving",
      "icon": "🐌",
      "color": Color(0xFFE8D5B7),
    },
    {
      "text": "Low but moving",
      "icon": "🐢",
      "color": Color(0xFFB8E6B8),
    },
    {
      "text": "Average day",
      "icon": "🐕",
      "color": Color(0xFFFFD4A3),
    },
    {
      "text": "Motivated",
      "icon": "🦅",
      "color": Color(0xFFE6E6FA),
    },
    {
      "text": "LET'S GOO",
      "icon": "🚀",
      "color": Color(0xFFFFB6C1),
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _selectedAnswer = _options[_sliderValue.round()]['text'];

    }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  Future<void> _saveAnswerToFirebase(String answer) async {
    final userId = FirebaseAuth.instance.currentUser?.uid
        ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    final ref = _db.child('users').child(userId).child('survey_responses');
    await ref.push().set({
      'questionIndex': widget.currentQuestionIndex,
      'question': 'How much energy do you have right now?',
      'answer': answer,
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> _handleNext() async {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer to continue')),
      );
      return;
    }

    await _saveAnswerToFirebase(_selectedAnswer!);

    final updated = [...widget.answers, _selectedAnswer!];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Form4(
          currentQuestionIndex: widget.currentQuestionIndex + 1,
          answers: updated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.currentQuestionIndex + 1) / 10;
    final selectedIndex = 4 - _sliderValue.round();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (ctx, child) {
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
                // Back button and progress bar (same as Form2)
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
                          "How much energy do you have right now?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Vertical slider with options
                        Expanded(
                          child: Row(
                            children: [
                              // Left side - Icons only
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: _options.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Map<String, dynamic> option = entry.value;
                                  bool isSelected = selectedIndex == index;
                                  
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? option["color"] 
                                          : option["color"].withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.orange
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        option["icon"],
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              
                              const SizedBox(width: 20),
                              
                              // Middle - Vertical slider
                              SizedBox(
                                height: double.infinity,
                                child: RotatedBox(
                                  quarterTurns: -1,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 8,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 16),
                                      thumbColor: Colors.orange,
                                      activeTrackColor: Colors.orange,
                                      inactiveTrackColor: Colors.grey.shade300,
                                      overlayShape: const RoundSliderOverlayShape(
                                          overlayRadius: 24),
                                    ),
                                    child: Slider(
                                      value: _sliderValue,
                                      min: 0,
                                      max: 4,
                                      divisions: 4,
                                      onChanged: (value) {
                                        setState(() {
                                          _sliderValue = value;
                                          _selectedAnswer = _options[value.round()]["text"];
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 20),
                              
                              // Right side - Text labels
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _options.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    Map<String, dynamic> option = entry.value;
                                    bool isSelected = selectedIndex == index;
                                    
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? option["color"].withOpacity(0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.orange
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      child: Center(
                                        child: Text(
                                          option["text"],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected 
                                                ? FontWeight.w600 
                                                : FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Next button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Next',
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