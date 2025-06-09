// lib/widgets/daily_dose_section.dart

import 'package:flutter/material.dart';
import '../models/dose.dart';
import 'daily_doseai.dart';

class DailyDoseSection extends StatefulWidget {
  const DailyDoseSection({super.key});

  @override
  State<DailyDoseSection> createState() => _DailyDoseSectionState();
}

class _DailyDoseSectionState extends State<DailyDoseSection> {
  late Future<List<Dose>> _dosesFuture;

  @override
  void initState() {
    super.initState();
    _dosesFuture = _fetchDosesFromFirebase();
  }

  /// Fetches survey responses from Firebase and converts them to Dose objects
  Future<List<Dose>> _fetchDosesFromFirebase() async {
    try {
      // Get survey responses from Firebase
      final responses = await DailyDoseAI.getSurveyResponses();
      
      if (responses.isEmpty) {
        return [];
      }

      // Convert survey responses to Dose objects
      List<Dose> doses = [];
      
      for (final response in responses) {
        final question = response['question'] ?? 'No question available';
        final answer = response['answer'] ?? 'No answer provided';
        final questionIndex = response['questionIndex'] ?? 0;
        final timestamp = response['timestamp'];

        // Create a formatted title from question index
        String title = 'Question ${questionIndex + 1}';
        
        // Create subtitle from truncated question
        String subtitle = question.length > 60 
            ? '${question.substring(0, 60)}...' 
            : question;

        // Format timestamp for additional context
        String formattedDate = '';
        if (timestamp != null) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        }

        // Create Dose object
        final dose = Dose(
          title: title,
          subtitle: subtitle,
          answer: answer,
          // You can add additional fields if your Dose model supports them
          // date: formattedDate,
          // questionIndex: questionIndex,
        );

        doses.add(dose);
      }

      // Return the most recent responses (limit to prevent overwhelming UI)
      return doses.take(10).toList();

    } catch (e) {
      throw Exception('Failed to fetch survey responses: $e');
    }
  }

  void _refreshDoses() {
    setState(() {
      _dosesFuture = _fetchDosesFromFirebase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Dose>>(
      future: _dosesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your survey responses...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load survey responses\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshDoses,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final doses = snapshot.data ?? [];
        if (doses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No survey responses found.\nComplete the survey to see your responses here!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshDoses,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Survey Responses (${doses.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshDoses,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh responses',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220, // Increased height to accommodate answer text
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: doses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final dose = doses[index];
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.8, // Slightly wider
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                dose.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.brown.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${index + 1}/${doses.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.brown,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dose.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              dose.answer,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}