import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class MentalHealthStatsBubble extends StatefulWidget {
  const MentalHealthStatsBubble({super.key});

  @override
  State<MentalHealthStatsBubble> createState() => _MentalHealthStatsBubbleState();
}

class _MentalHealthStatsBubbleState extends State<MentalHealthStatsBubble> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, double> categoryScores = {};

  @override
  void initState() {
    super.initState();
    _loadSurveyData();
  }

  Future<void> _loadSurveyData() async {
  if (userId == null) return;

  try {
    final snapshot = await FirebaseDatabase.instance
        .ref('users/$userId/survey_responses')
        .get();

    if (!snapshot.exists) {
      debugPrint('No survey data found for user.');
      return;
    }

    Map<String, int> categoryCounts = {
      'Stress': 0,
      'Anxiety': 0,
      'Focus': 0,
      'Sleep': 0,
      'Mood': 0,
    };

    int matchedCount = 0;

    for (final child in snapshot.children) {
      final data = child.value as Map<dynamic, dynamic>?;

      if (data == null) continue;

      final question = (data['question'] ?? '').toString().toLowerCase();
      final answer = (data['answer'] ?? '').toString().toLowerCase();

      bool matched = false;

      if (question.contains('stress') || answer.contains('stress')) {
        categoryCounts['Stress'] = categoryCounts['Stress']! + 1;
        matched = true;
      }
      if (question.contains('anxiety') || answer.contains('anxious')) {
        categoryCounts['Anxiety'] = categoryCounts['Anxiety']! + 1;
        matched = true;
      }
      if (question.contains('focus') || answer.contains('distract')) {
        categoryCounts['Focus'] = categoryCounts['Focus']! + 1;
        matched = true;
      }
      if (question.contains('sleep') || answer.contains('tired')) {
        categoryCounts['Sleep'] = categoryCounts['Sleep']! + 1;
        matched = true;
      }
      if (question.contains('mood') || answer.contains('upset')) {
        categoryCounts['Mood'] = categoryCounts['Mood']! + 1;
        matched = true;
      }

      if (matched) matchedCount++;
    }

    if (matchedCount == 0) {
      debugPrint('No matches found in survey data.');
      return;
    }

    setState(() {
      categoryScores = {
        for (var key in categoryCounts.keys)
          key: (categoryCounts[key]! / matchedCount * 100).clamp(0, 100),
      };
    });

    debugPrint('[✅] Final categoryScores: $categoryScores');
  } catch (e) {
    debugPrint('❌ Error fetching or parsing survey data: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    if (categoryScores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: categoryScores.entries.map((entry) {
          return _StatBubble(title: entry.key, percentage: entry.value);
        }).toList(),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String title;
  final double percentage;

  const _StatBubble({required this.title, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.teal.shade200, Colors.teal.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${percentage.toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
