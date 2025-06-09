// lib/services/daily_doseai.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DailyDoseAI {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Fetches all survey responses for the currently logged-in user
  /// and prints them to the debug console
  static Future<void> fetchAndPrintAllSurveyResponses() async {
    try {
      // Get current user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser == null) {
        debugPrint('❌ No user is currently logged in');
        return;
      }

      final userId = firebaseUser.uid;
      debugPrint('🔍 Fetching survey responses for user: $userId');

      // Reference to user's survey responses
      final surveyResponsesRef = _db.child('users').child(userId).child('survey_responses');

      // Listen for data once
      final snapshot = await surveyResponsesRef.get();

      if (!snapshot.exists) {
        debugPrint('📭 No survey responses found for this user');
        return;
      }

      // Parse and print all responses
      final responses = snapshot.value as Map<dynamic, dynamic>;
      
      debugPrint('📊 Found ${responses.length} survey responses:');
      debugPrint('=' * 50);

      // Sort responses by timestamp for chronological order
      final sortedEntries = responses.entries.toList()
        ..sort((a, b) {
          final timestampA = (a.value as Map)['timestamp'] ?? 0;
          final timestampB = (b.value as Map)['timestamp'] ?? 0;
          return timestampA.compareTo(timestampB);
        });

      for (int i = 0; i < sortedEntries.length; i++) {
        final entry = sortedEntries[i];
        final responseId = entry.key;
        final responseData = entry.value as Map<dynamic, dynamic>;

        final questionIndex = responseData['questionIndex'] ?? 'N/A';
        final question = responseData['question'] ?? 'No question text';
        final answer = responseData['answer'] ?? 'No answer';
        final timestamp = responseData['timestamp'];

        // Convert timestamp to readable date
        String formattedDate = 'N/A';
        if (timestamp != null) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }

        debugPrint('📝 Response ${i + 1}:');
        debugPrint('   ID: $responseId');
        debugPrint('   Question Index: $questionIndex');
        debugPrint('   Question: "$question"');
        debugPrint('   Answer: "$answer"');
        debugPrint('   Date: $formattedDate');
        debugPrint('-' * 30);
      }

      debugPrint('✅ Successfully fetched and printed all survey responses');

    } catch (e) {
      debugPrint('❌ Error fetching survey responses: $e');
    }
  }

  /// Fetches survey responses with additional filtering options
  static Future<List<Map<String, dynamic>>> getSurveyResponses({
    String? userId,
    int? questionIndex,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Use provided userId or get current user's ID
      final targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
      
      if (targetUserId == null) {
        debugPrint('❌ No user ID provided and no user is logged in');
        return [];
      }

      final surveyResponsesRef = _db.child('users').child(targetUserId).child('survey_responses');
      final snapshot = await surveyResponsesRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final responses = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> filteredResponses = [];

      responses.forEach((key, value) {
        final responseData = Map<String, dynamic>.from(value as Map);
        responseData['id'] = key; // Add the Firebase key as ID

        // Apply filters
        bool includeResponse = true;

        // Filter by question index
        if (questionIndex != null && responseData['questionIndex'] != questionIndex) {
          includeResponse = false;
        }

        // Filter by date range
        if (includeResponse && (fromDate != null || toDate != null)) {
          final timestamp = responseData['timestamp'];
          if (timestamp != null) {
            final responseDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
            
            if (fromDate != null && responseDate.isBefore(fromDate)) {
              includeResponse = false;
            }
            
            if (toDate != null && responseDate.isAfter(toDate)) {
              includeResponse = false;
            }
          }
        }

        if (includeResponse) {
          filteredResponses.add(responseData);
        }
      });

      // Sort by timestamp
      filteredResponses.sort((a, b) {
        final timestampA = a['timestamp'] ?? 0;
        final timestampB = b['timestamp'] ?? 0;
        return timestampA.compareTo(timestampB);
      });

      return filteredResponses;

    } catch (e) {
      debugPrint('❌ Error getting survey responses: $e');
      return [];
    }
  }

  /// Print responses for a specific question index
  static Future<void> printResponsesForQuestion(int questionIndex) async {
    try {
      final responses = await getSurveyResponses(questionIndex: questionIndex);
      
      if (responses.isEmpty) {
        debugPrint('📭 No responses found for question index $questionIndex');
        return;
      }

      debugPrint('📊 Responses for Question Index $questionIndex:');
      debugPrint('=' * 40);

      for (final response in responses) {
        final question = response['question'] ?? 'No question text';
        final answer = response['answer'] ?? 'No answer';
        final timestamp = response['timestamp'];

        String formattedDate = 'N/A';
        if (timestamp != null) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }

        debugPrint('Question: "$question"');
        debugPrint('Answer: "$answer"');
        debugPrint('Date: $formattedDate');
        debugPrint('-' * 20);
      }

    } catch (e) {
      debugPrint('❌ Error printing responses for question: $e');
    }
  }

  /// Get summary statistics of user's responses
  static Future<void> printResponseSummary() async {
    try {
      final responses = await getSurveyResponses();
      
      if (responses.isEmpty) {
        debugPrint('📭 No survey responses found');
        return;
      }

      // Group by question index
      Map<int, List<Map<String, dynamic>>> responsesByQuestion = {};
      
      for (final response in responses) {
        final questionIndex = response['questionIndex'] as int? ?? -1;
        if (!responsesByQuestion.containsKey(questionIndex)) {
          responsesByQuestion[questionIndex] = [];
        }
        responsesByQuestion[questionIndex]!.add(response);
      }

      debugPrint('📈 Survey Response Summary:');
      debugPrint('=' * 40);
      debugPrint('Total Responses: ${responses.length}');
      debugPrint('Unique Questions: ${responsesByQuestion.length}');
      debugPrint('');

      // Print summary for each question
      final sortedQuestions = responsesByQuestion.keys.toList()..sort();
      
      for (final questionIndex in sortedQuestions) {
        final questionResponses = responsesByQuestion[questionIndex]!;
        final sampleQuestion = questionResponses.first['question'] ?? 'Unknown question';
        
        debugPrint('Question $questionIndex: "${sampleQuestion.length > 50 ? sampleQuestion.substring(0, 50) + '...' : sampleQuestion}"');
        debugPrint('  Responses: ${questionResponses.length}');
        
        // Show most recent answer
        final mostRecent = questionResponses.last;
        final recentAnswer = mostRecent['answer'] ?? 'No answer';
        debugPrint('  Latest Answer: "$recentAnswer"');
        debugPrint('');
      }

    } catch (e) {
      debugPrint('❌ Error generating response summary: $e');
    }
  }
}

// Example usage class
class DailyDoseAIExample {
  static void demonstrateUsage() {
    // Example 1: Fetch and print all responses
    DailyDoseAI.fetchAndPrintAllSurveyResponses();

    // Example 2: Print responses for a specific question
    DailyDoseAI.printResponsesForQuestion(0);

    // Example 3: Print summary statistics
    DailyDoseAI.printResponseSummary();

    // Example 4: Get responses programmatically
    _getResponsesExample();
  }

  static void _getResponsesExample() async {
    // Get all responses
    final allResponses = await DailyDoseAI.getSurveyResponses();
    debugPrint('Found ${allResponses.length} total responses');

    // Get responses from the last 7 days
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentResponses = await DailyDoseAI.getSurveyResponses(
      fromDate: weekAgo,
    );
    debugPrint('Found ${recentResponses.length} responses in the last 7 days');
  }
}