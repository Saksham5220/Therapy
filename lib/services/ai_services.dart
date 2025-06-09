import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AIService {
  
  /// Get current user ID from Firebase Auth
  static String? get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Get cached AI doses for a specific user and survey
  static Future<List<Map<String, String>>?> getCachedAIDoses(String surveyId) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('❌ No authenticated user found');
      return null;
    }

    try {
      // First try local cache
      final prefs = await SharedPreferences.getInstance();
      final localCacheKey = 'ai_doses_${userId}_$surveyId';
      final cachedJson = prefs.getString(localCacheKey);
      
      if (cachedJson != null) {
        try {
          final List<dynamic> parsed = jsonDecode(cachedJson);
          debugPrint('✅ Found local cached AI doses for user $userId, survey $surveyId');
          return parsed.map<Map<String, String>>((item) {
            return Map<String, String>.from(
              (item as Map).map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''))
            );
          }).toList();
        } catch (e) {
          debugPrint('❌ Failed to decode local cached AI doses: $e');
        }
      }

      // If not in local cache, try Firestore
      final firestoreDoses = await _getAIDosesFromFirestore(userId, surveyId);
      if (firestoreDoses != null) {
        // Cache locally for faster access
        await prefs.setString(localCacheKey, jsonEncode(firestoreDoses));
        debugPrint('✅ Retrieved AI doses from Firestore for user $userId, survey $surveyId');
        return firestoreDoses;
      }

    } catch (e) {
      debugPrint('❌ Error getting cached AI doses: $e');
    }
    
    return null;
  }

  /// Get AI doses from Firestore for a specific user and survey
  static Future<List<Map<String, String>>?> _getAIDosesFromFirestore(String userId, String surveyId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ai_doses')
          .doc(surveyId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final List<dynamic> doses = data['doses'] ?? [];
        return doses.map<Map<String, String>>((item) {
          return Map<String, String>.from(
            (item as Map).map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''))
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('❌ Error getting AI doses from Firestore: $e');
    }
    return null;
  }

  /// Store AI doses in both local cache and Firestore
  static Future<void> _storeAIDoses(String userId, String surveyId, List<Map<String, String>> doses) async {
    try {
      // Store in local cache
      final prefs = await SharedPreferences.getInstance();
      final localCacheKey = 'ai_doses_${userId}_$surveyId';
      await prefs.setString(localCacheKey, jsonEncode(doses));

      // Store in Firestore with user organization
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ai_doses')
          .doc(surveyId)
          .set({
        'doses': doses,
        'surveyId': surveyId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Also update user's main document with latest AI dose info
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'lastAIDoseGeneration': FieldValue.serverTimestamp(),
        'latestSurveyId': surveyId,
        'totalAIDoses': doses.length,
      });

      debugPrint('✅ Successfully stored AI doses for user $userId, survey $surveyId');
    } catch (e) {
      debugPrint('❌ Error storing AI doses: $e');
    }
  }
  

  /// Get all AI doses for a user (for future use)
  static Future<List<Map<String, dynamic>>?> getAllUserAIDoses() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ai_doses')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'surveyId': doc.id,
          'doses': data['doses'],
          'createdAt': data['createdAt'],
          'lastUpdated': data['lastUpdated'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting all user AI doses: $e');
      return null;
    }
  }

  String generateSurveyId(List<Map<String, dynamic>> responses) {
    final userId = _currentUserId ?? 'anonymous';
    final jsonString = jsonEncode(responses);
    final combinedString = '$userId:$jsonString';
    final hash = sha256.convert(utf8.encode(combinedString));
    return hash.toString();
  }

  // Remove hardcoded API key - get from secure storage
  static String? _apiKey = 'OPEN_API_KEY';
  static const String _assistantId = 'OPENAI_ASSISTANT_ID';
  static const String _baseUrl = 'https://api.openai.com/v1';

  /// Initialize with API key from secure storage
  static void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  /// Send all survey responses at once and get batch response
  static Future<List<Map<String, String>>?> sendAllSurveyEntries({
    required List<Map<String, dynamic>> surveyResponses,
    required String surveyId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('❌ No authenticated user found');
      return null;
    }

    if (_apiKey == null) {
      debugPrint('❌ AIService: API key not initialized');
      return null;
    }

    // Check if we have cached doses for this user and survey
    final cachedDoses = await getCachedAIDoses(surveyId);
    if (cachedDoses != null) {
      debugPrint('✅ Returning cached AI doses for user $userId, survey $surveyId');
      return cachedDoses;
    }

    // Check rate limiting per user
    final prefs = await SharedPreferences.getInstance();
    final lastRunKey = 'last_ai_run_${userId}_$surveyId';
    final lastRun = prefs.getInt(lastRunKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastRun != null && now - lastRun < 24 * 60 * 60 * 1000) {
      debugPrint('⏳ Rate limit: AI doses already generated for user $userId in last 24h');
      // Still try to get from cache/Firestore
      return await getCachedAIDoses(surveyId);
    }

    try {
      debugPrint('🤖 AIService: Generating AI doses for user $userId with ${surveyResponses.length} survey responses...');
      
      final threadId = await _createThread();
      if (threadId == null) throw Exception('Failed to create thread');

      final combinedMessage = _formatAllResponses(surveyResponses, userId);
      final messageAdded = await _addBatchMessage(threadId, combinedMessage);
      if (!messageAdded) throw Exception('Failed to add batch message');

      final runId = await _runAssistant(threadId);
      if (runId == null) throw Exception('Failed to run assistant');

      final output = await _waitForRunCompletion(threadId, runId);
      if (output != null) {
        final parsed = _parseDoses(output);
        if (parsed != null) {
          // Store with user organization
          await _storeAIDoses(userId, surveyId, parsed);
          await storeDailyDosesToRealtimeDB(surveyId, parsed);
          
          // Update rate limiting
          await prefs.setInt(lastRunKey, now);
          
          debugPrint('✅ Successfully generated and stored ${parsed.length} AI doses for user $userId');
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('❌ AIService Batch Error for user $userId: $e');
    }

    return null;
  }

  /// Format all survey responses into a single comprehensive message
  static String _formatAllResponses(List<Map<String, dynamic>> responses, String userId) {
    final buffer = StringBuffer();
    buffer.writeln('User Survey Responses - Complete Profile:');
    buffer.writeln('User ID: $userId');
    buffer.writeln('Total responses: ${responses.length}');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      final question = response['question']?.toString() ?? 'No question';
      final answer = response['answer']?.toString() ?? 'No answer';
      final questionIndex = response['questionIndex'] ?? i;
      final timestamp = response['timestamp'];

      buffer.writeln('--- Response ${i + 1} (Question Index: $questionIndex) ---');
      buffer.writeln('Question: "$question"');
      buffer.writeln('Answer: "$answer"');
      if (timestamp != null) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        buffer.writeln('Answered: ${dateTime.toIso8601String()}');
      }
      buffer.writeln('');
    }

    buffer.writeln('Based on this complete survey profile for user $userId, generate 5 personalized daily mental health doses in JSON using the daily_dose_generator schema. Consider the user\'s overall responses to create well-rounded, relevant mental health recommendations. Give responses with just title(max 3 words) and body (max 25 words)');

    return buffer.toString();
  }

  /// Get user's AI dose history (for analytics/tracking)
  static Future<Map<String, dynamic>?> getUserAIDoseStats() async {
  final userId = _currentUserId;
  if (userId == null) return null;

  try {
    final userDoc = await _retry(() =>
      FirebaseFirestore.instance.collection('users').doc(userId).get()
    );

    if (userDoc != null && userDoc.exists) {
      final data = userDoc.data()!;
      return {
        'totalAIDoses': data['totalAIDoses'] ?? 0,
        'lastAIDoseGeneration': data['lastAIDoseGeneration'],
        'latestSurveyId': data['latestSurveyId'],
      };
    }
  } catch (e) {
    debugPrint('❌ Error getting user AI dose stats: $e');
  }

  return null;
}

  static Future<T?> _retry<T>(Future<T> Function() action, {int retries = 3}) async {
  for (int i = 0; i < retries; i++) {
    try {
      return await action();
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
  return null;
}



  /// Legacy method for single question processing (kept for backward compatibility)
  static Future<List<Map<String, String>>?> sendSurveyEntry({
    required String question,
    required String answer,
    required int index,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('❌ No authenticated user found');
      return null;
    }

    if (_apiKey == null) {
      debugPrint('❌ AIService: API key not initialized');
      return null;
    }

    try {
      debugPrint('🤖 AIService: Sending Q$index to Assistant for user $userId...');
      final threadId = await _createThread();
      if (threadId == null) throw Exception('Failed to create thread');

      final messageAdded = await _addMessage(threadId, question, answer, userId);
      if (!messageAdded) throw Exception('Failed to add message');

      final runId = await _runAssistant(threadId);
      if (runId == null) throw Exception('Failed to run assistant');

      final output = await _waitForRunCompletion(threadId, runId);
      if (output != null) {
        debugPrint('✅ AI Response for user $userId, Q$index (raw):\n$output\n');
        final parsed = _parseDoses(output);
        if (parsed != null) {
          debugPrint('✅ AI Response for user $userId, Q$index (parsed):\n$parsed\n');
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('❌ AIService Error for user $userId, Q$index: $e');
    }
    return null;
  }

  static Future<String?> _createThread() async {
    final res = await http.post(
      Uri.parse('$_baseUrl/threads'),
      headers: _headers(),
      body: jsonEncode({}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['id'];
    } else {
      debugPrint('❌ Failed to create thread: ${res.statusCode} ${res.body}');
    }
    return null;
  }

  static Future<bool> _addBatchMessage(String threadId, String content) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/threads/$threadId/messages'),
      headers: _headers(),
      body: jsonEncode({
        'role': 'user',
        'content': content,
      }),
    );
    if (res.statusCode != 200) {
      debugPrint('Failed to add batch message: ${res.statusCode} ${res.body}');
    }
    return res.statusCode == 200;
  }

  static Future<bool> _addMessage(String threadId, String question, String answer, String userId) async {
    final content = 'User ID: $userId\nUser was asked:\n"$question"\nThey answered:\n"$answer"\nGenerate 5 personalized daily mental health doses in JSON using the daily_dose_generator schema.';
    final res = await http.post(
      Uri.parse('$_baseUrl/threads/$threadId/messages'),
      headers: _headers(),
      body: jsonEncode({
        'role': 'user',
        'content': content,
      }),
    );
    if (res.statusCode != 200) {
      debugPrint('Failed to add message: ${res.statusCode} ${res.body}');
    }
    return res.statusCode == 200;
  }

  static Future<String?> _runAssistant(String threadId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/threads/$threadId/runs'),
      headers: _headers(),
      body: jsonEncode({
        'assistant_id': _assistantId,
        'tools': [
          {
            'type': 'function',
            'function': {'name': 'daily_dose_generator'}
          }
        ]
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['id'];
    } else {
      debugPrint('Failed to run assistant: ${res.statusCode} ${res.body}');
    }
    return null;
  }

  static Future<String?> _waitForRunCompletion(String threadId, String runId) async {
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('Polling status... attempt ${i + 1}/30');
      final res = await http.get(
        Uri.parse('$_baseUrl/threads/$threadId/runs/$runId'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data['status'];
        if (status == 'completed') {
          return _getMessages(threadId);
        } else if (status == 'failed' || status == 'cancelled') {
          throw Exception('Run failed or cancelled');
        }
      } else {
        debugPrint('❌ Error while polling run: ${res.statusCode} ${res.body}');
      }
    }
    throw Exception('Timeout waiting for run to complete');
  }

  static Future<String?> _getMessages(String threadId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/threads/$threadId/messages'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final messages = data['data'];
      if (messages != null && messages.isNotEmpty) {
        for (var msg in messages) {
          if (msg['role'] == 'assistant') {
            final contentList = msg['content'];
            for (var content in contentList) {
              if (content['type'] == 'function_call') {
                return content['function_call']['arguments'];
              } else if (content['type'] == 'text') {
                return content['text']['value'];
              }
            }
          }
        }
      }
    } else {
      debugPrint('Failed to fetch messages: ${res.statusCode} ${res.body}');
    }
    return null;
  }

  static List<Map<String, String>>? _parseDoses(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      final List<dynamic> doses = decoded['doses'];
      return doses.map<Map<String, String>>((item) {
        return {
          'title': item['title']?.toString() ?? '',
          'subtitle': item['subtitle']?.toString() ?? '',
          'answer': item['answer']?.toString() ?? '',
          'spotifyUrl': item['spotifyUrl']?.toString() ?? '',
          'appleMusicUrl': item['appleMusicUrl']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Failed to parse doses: $e');
      return null;
    }
  }
    static Future<void> storeDailyDosesToRealtimeDB(String surveyId, List<Map<String, String>> doses) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final ref = FirebaseDatabase.instance.ref("users/$userId/daily_doses/$surveyId");
    final existing = await ref.once();

    if (existing.snapshot.exists) {
      debugPrint('⏳ Daily dose already exists for $surveyId');
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'surveyId': surveyId,
      'createdAt': timestamp,
      'doses': doses,
    };

    await ref.set(data);
    debugPrint('✅ Daily doses saved under users/$userId/daily_doses/$surveyId');
  }

  static Map<String, String> _headers() {
    if (_apiKey == null) {
      throw Exception('API key not initialized');
    }
    return {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'OpenAI-Beta': 'assistants=v2',
    };
  }
}