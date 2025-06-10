import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_keys.dart'; // Import the API keys

class AIService {
  /// Get current user ID from Firebase Auth
  static String? get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Get cached AI doses for a specific user and survey
  static Future<List<Map<String, String>>?> getCachedAIDoses(
    String surveyId,
  ) async {
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
          debugPrint(
            '✅ Found local cached AI doses for user $userId, survey $surveyId',
          );
          return parsed.map<Map<String, String>>((item) {
            return Map<String, String>.from(
              (item as Map).map(
                (key, value) =>
                    MapEntry(key.toString(), value?.toString() ?? ''),
              ),
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
        debugPrint(
          '✅ Retrieved AI doses from Firestore for user $userId, survey $surveyId',
        );
        return firestoreDoses;
      }
    } catch (e) {
      debugPrint('❌ Error getting cached AI doses: $e');
    }

    return null;
  }

  /// Get AI doses from Firebase Realtime Database for a specific user and survey
  static Future<List<Map<String, String>>?> _getAIDosesFromFirestore(
    String userId,
    String surveyId,
  ) async {
    try {
      // Create reference to the specific path in Realtime Database
      final DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('ai_doses')
          .child(surveyId);

      // Get the data snapshot
      final DataSnapshot snapshot = await ref.get();

      // Check if data exists
      if (snapshot.exists && snapshot.value != null) {
        final dynamic rawData = snapshot.value;

        // Handle different data structures that might be returned
        if (rawData is Map) {
          final Map<dynamic, dynamic> data = rawData;
          final dynamic dosesData = data['doses'];

          // Handle different types of doses data
          if (dosesData is List) {
            // If doses is a list
            return dosesData
                .map<Map<String, String>>((item) {
                  if (item is Map) {
                    return Map<String, String>.from(
                      item.map(
                        (key, value) =>
                            MapEntry(key.toString(), value?.toString() ?? ''),
                      ),
                    );
                  }
                  return <
                    String,
                    String
                  >{}; // Return empty map for invalid items
                })
                .where((map) => map.isNotEmpty)
                .toList();
          } else if (dosesData is Map) {
            // If doses is a map (converted from array by Firebase)
            return dosesData.values
                .map<Map<String, String>>((item) {
                  if (item is Map) {
                    return Map<String, String>.from(
                      item.map(
                        (key, value) =>
                            MapEntry(key.toString(), value?.toString() ?? ''),
                      ),
                    );
                  }
                  return <
                    String,
                    String
                  >{}; // Return empty map for invalid items
                })
                .where((map) => map.isNotEmpty)
                .toList();
          }
        } else if (rawData is List) {
          // If the entire data is a list
          return rawData
              .map<Map<String, String>>((item) {
                if (item is Map) {
                  return Map<String, String>.from(
                    item.map(
                      (key, value) =>
                          MapEntry(key.toString(), value?.toString() ?? ''),
                    ),
                  );
                }
                return <String, String>{}; // Return empty map for invalid items
              })
              .where((map) => map.isNotEmpty)
              .toList();
        }

        debugPrint('⚠️ Unexpected data structure in Realtime Database');
        return [];
      } else {
        debugPrint('📭 No AI doses found for user: $userId, survey: $surveyId');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting AI doses from Realtime Database: $e');
      debugPrint('🔍 Stack trace: ${StackTrace.current}');
    }
    return null;
  }

  /// Store AI doses in both local cache and Firestore
  static Future<void> _storeAIDoses(
    String userId,
    String surveyId,
    List<Map<String, String>> doses,
  ) async {
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
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'lastAIDoseGeneration': FieldValue.serverTimestamp(),
        'latestSurveyId': surveyId,
        'totalAIDoses': doses.length,
      });

      debugPrint(
        '✅ Successfully stored AI doses for user $userId, survey $surveyId',
      );
    } catch (e) {
      debugPrint('❌ Error storing AI doses: $e');
    }
  }

  /// Get all AI doses for a user (for future use)
  static Future<List<Map<String, dynamic>>?> getAllUserAIDoses() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
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

  // Get API key and assistant ID from ApiKeys class
  static String? get _apiKey {
    final key = ApiKeys.openaiApiKey;
    debugPrint(
      '🔑 API Key loaded from ApiKeys: ${key.isNotEmpty ? '${key.substring(0, 10)}...' : 'EMPTY'}',
    );
    return key.isNotEmpty ? key : null;
  }

  static String? get _assistantId {
    final id = ApiKeys.openaiAssistantId;
    debugPrint(
      '🤖 Assistant ID loaded from ApiKeys: ${id.isNotEmpty ? id : 'EMPTY'}',
    );
    return id.isNotEmpty ? id : null;
  }

  static const String _baseUrl = 'https://api.openai.com/v1';

  /// Initialize with API key validation (backward compatible)
  static void initialize([String? apiKey]) {
    // Print debug info to verify configuration
    ApiKeys.printDebugInfo();

    if (apiKey != null) {
      debugPrint(
        '⚠️ AIService: API key parameter ignored - using ApiKeys configuration',
      );
    }

    if (!ApiKeys.isValidApiKey()) {
      debugPrint('❌ AIService: Invalid API key configuration');
    }

    if (!ApiKeys.isValidAssistantId()) {
      debugPrint('❌ AIService: Invalid Assistant ID configuration');
    }

    if (ApiKeys.isValidApiKey() && ApiKeys.isValidAssistantId()) {
      debugPrint('✅ AIService initialized successfully with ApiKeys');
    } else {
      debugPrint(
        '❌ AIService initialization failed - check ApiKeys configuration',
      );
    }
  }

  // NEW: Single function to fetch all responses from your API
  static Future<Map<String, dynamic>?> fetchAllResponses() async {
    const String baseUrl =
        'YOUR_API_ENDPOINT_HERE'; // Replace with your actual endpoint

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-responses'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Successfully fetched all responses from API');
        return data;
      } else {
        debugPrint('❌ Failed to fetch data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching all responses: $e');
      return null;
    }
  }

  // NEW: Parse doses from the full response
  static List<Map<String, String>> parseDoses(
    Map<String, dynamic> fullResponse,
  ) {
    try {
      final doses = fullResponse['doses'] as List<dynamic>? ?? [];
      final parsedDoses =
          doses
              .map(
                (dose) => {
                  'title': dose['title']?.toString() ?? '',
                  'subtitle': dose['subtitle']?.toString() ?? '',
                  'answer': dose['answer']?.toString() ?? '',
                },
              )
              .toList();

      debugPrint('✅ Parsed ${parsedDoses.length} doses from response');
      return parsedDoses;
    } catch (e) {
      debugPrint('❌ Error parsing doses: $e');
      return [];
    }
  }

  // NEW: Parse song categories from the full response
  static List<String> parseSongs(Map<String, dynamic> fullResponse) {
    try {
      final songCategories =
          fullResponse['songCategories'] as List<dynamic>? ?? [];
      final parsedSongs =
          songCategories.map((category) => category.toString()).toList();

      debugPrint(
        '✅ Parsed ${parsedSongs.length} song categories from response',
      );
      return parsedSongs;
    } catch (e) {
      debugPrint('❌ Error parsing song categories: $e');
      return [];
    }
  }

  // NEW: Parse podcast categories from the full response
  static List<String> parsePodcasts(Map<String, dynamic> fullResponse) {
    try {
      final podcastCategories =
          fullResponse['podcastCategories'] as List<dynamic>? ?? [];
      final parsedPodcasts =
          podcastCategories.map((category) => category.toString()).toList();

      debugPrint(
        '✅ Parsed ${parsedPodcasts.length} podcast categories from response',
      );
      return parsedPodcasts;
    } catch (e) {
      debugPrint('❌ Error parsing podcast categories: $e');
      return [];
    }
  }

  // NEW: Parse therapy probabilities from the full response
  static Map<String, int> parseTherapyProb(Map<String, dynamic> fullResponse) {
    try {
      final therapyProb =
          fullResponse['therapyProbabilities'] as Map<String, dynamic>? ?? {};
      final parsedTherapy = therapyProb.map(
        (key, value) => MapEntry(key, value as int? ?? 0),
      );

      debugPrint(
        '✅ Parsed ${parsedTherapy.length} therapy probabilities from response',
      );
      return parsedTherapy;
    } catch (e) {
      debugPrint('❌ Error parsing therapy probabilities: $e');
      return {};
    }
  }

  // NEW: Method to fetch and distribute all data to respective services
  static Future<void> fetchAndDistributeData() async {
    try {
      debugPrint('🔄 Starting fetchAndDistributeData...');

      // Fetch all data in one call
      final fullResponse = await fetchAllResponses();
      if (fullResponse == null) {
        debugPrint('❌ Failed to fetch data from API');
        return;
      }

      // Parse all data types
      final doses = parseDoses(fullResponse);
      final songCategories = parseSongs(fullResponse);
      final podcastCategories = parsePodcasts(fullResponse);
      final therapyProbabilities = parseTherapyProb(fullResponse);

      // Send data to respective services (you'll need to implement these services)
      // Example calls - implement these based on your service structure:

      // await ScriptedFileService.updateDoses(doses);
      // await PlaylistServices.updateSongCategories(songCategories);
      // await PodcastsService.updatePodcastCategories(podcastCategories);
      // await ProfileService.updateTherapyProbabilities(therapyProbabilities);

      debugPrint('✅ Successfully distributed all data to services');
      debugPrint('📊 Data summary:');
      debugPrint('  - Doses: ${doses.length}');
      debugPrint('  - Song Categories: ${songCategories.length}');
      debugPrint('  - Podcast Categories: ${podcastCategories.length}');
      debugPrint('  - Therapy Probabilities: ${therapyProbabilities.length}');
    } catch (e) {
      debugPrint('❌ Error in fetchAndDistributeData: $e');
    }
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

    final apiKey = _apiKey;
    final assistantId = _assistantId;

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('❌ AIService: API key not found in ApiKeys');
      return null;
    }

    if (assistantId == null || assistantId.isEmpty) {
      debugPrint('❌ AIService: Assistant ID not found in ApiKeys');
      return null;
    }

    // Check if we have cached doses for this user and survey
    final cachedDoses = await getCachedAIDoses(surveyId);
    if (cachedDoses != null && cachedDoses.isNotEmpty) {
      debugPrint(
        '✅ Returning cached AI doses for user $userId, survey $surveyId (${cachedDoses.length} doses)',
      );
      return cachedDoses; // Return immediately when cached doses are found
    }

    // Check rate limiting per user
    final prefs = await SharedPreferences.getInstance();
    final lastRunKey = 'last_ai_run_${userId}_$surveyId';
    final lastRun = prefs.getInt(lastRunKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastRun != null && now - lastRun < 24 * 60 * 60 * 1000) {
      debugPrint(
        '⏳ Rate limit: AI doses already generated for user $userId in last 24h',
      );
      // Still try to get from cache/Firestore
      return await getCachedAIDoses(surveyId);
    }

    try {
      debugPrint(
        '🤖 AIService: Generating AI doses for user $userId with ${surveyResponses.length} survey responses...',
      );
      debugPrint('🔑 Using API key: ${apiKey.substring(0, 10)}...');
      debugPrint('🤖 Using Assistant ID: $assistantId');

      final threadId = await _createThread(apiKey);
      if (threadId == null) throw Exception('Failed to create thread');

      final combinedMessage = _formatAllResponses(surveyResponses, userId);
      final messageAdded = await _addBatchMessage(
        threadId,
        combinedMessage,
        apiKey,
      );
      if (!messageAdded) throw Exception('Failed to add batch message');

      final runId = await _runAssistant(threadId, assistantId, apiKey);
      if (runId == null) throw Exception('Failed to run assistant');

      final output = await _waitForRunCompletion(threadId, runId, apiKey);
      if (output != null) {
        final parsed = _parseDoses(output);
        if (parsed != null) {
          // Store with user organization
          await _storeAIDoses(userId, surveyId, parsed);
          await storeDailyDosesToRealtimeDB(surveyId, parsed);

          // Update rate limiting
          await prefs.setInt(lastRunKey, now);

          debugPrint(
            '✅ Successfully generated and stored ${parsed.length} AI doses for user $userId',
          );
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('❌ AIService Batch Error for user $userId: $e');
    }

    return null;
  }

  /// Format all survey responses into a single comprehensive message
  static String _formatAllResponses(
    List<Map<String, dynamic>> responses,
    String userId,
  ) {
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

      buffer.writeln(
        '--- Response ${i + 1} (Question Index: $questionIndex) ---',
      );
      buffer.writeln('Question: "$question"');
      buffer.writeln('Answer: "$answer"');
      if (timestamp != null) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        buffer.writeln('Answered: ${dateTime.toIso8601String()}');
      }
      buffer.writeln('');
    }

    buffer.writeln(
      'Based on this complete survey profile for user $userId, generate 5 personalized daily mental health doses in JSON using the daily_dose_generator schema. Consider the user\'s overall responses to create well-rounded, relevant mental health recommendations. Give responses with just title(max 3 words) and body (max 25 words)',
    );

    return buffer.toString();
  }

  /// Get user's AI dose history (for analytics/tracking)
  static Future<Map<String, dynamic>?> getUserAIDoseStats() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final userDoc = await _retry(
        () => FirebaseFirestore.instance.collection('users').doc(userId).get(),
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

  static Future<T?> _retry<T>(
    Future<T> Function() action, {
    int retries = 3,
  }) async {
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

    final apiKey = _apiKey;
    final assistantId = _assistantId;

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('❌ AIService: API key not found in ApiKeys');
      return null;
    }

    if (assistantId == null || assistantId.isEmpty) {
      debugPrint('❌ AIService: Assistant ID not found in ApiKeys');
      return null;
    }

    try {
      debugPrint(
        '🤖 AIService: Sending Q$index to Assistant for user $userId...',
      );
      final threadId = await _createThread(apiKey);
      if (threadId == null) throw Exception('Failed to create thread');

      final messageAdded = await _addMessage(
        threadId,
        question,
        answer,
        userId,
        apiKey,
      );
      if (!messageAdded) throw Exception('Failed to add message');

      final runId = await _runAssistant(threadId, assistantId, apiKey);
      if (runId == null) throw Exception('Failed to run assistant');

      final output = await _waitForRunCompletion(threadId, runId, apiKey);
      if (output != null) {
        debugPrint('✅ AI Response for user $userId, Q$index (raw):\n$output\n');
        final parsed = _parseDoses(output);
        if (parsed != null) {
          debugPrint(
            '✅ AI Response for user $userId, Q$index (parsed):\n$parsed\n',
          );
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('❌ AIService Error for user $userId, Q$index: $e');
    }
    return null;
  }

  static Future<String?> _createThread(String apiKey) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/threads'),
      headers: _headers(apiKey),
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

  static Future<bool> _addBatchMessage(
    String threadId,
    String content,
    String apiKey,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/threads/$threadId/messages'),
      headers: _headers(apiKey),
      body: jsonEncode({'role': 'user', 'content': content}),
    );
    if (res.statusCode != 200) {
      debugPrint('Failed to add batch message: ${res.statusCode} ${res.body}');
    }
    return res.statusCode == 200;
  }

  static Future<bool> _addMessage(
    String threadId,
    String question,
    String answer,
    String userId,
    String apiKey,
  ) async {
    final content =
        'User ID: $userId\nUser was asked:\n"$question"\nThey answered:\n"$answer"\nGenerate 5 personalized daily mental health doses in JSON using the daily_dose_generator schema.';
    final res = await http.post(
      Uri.parse('$_baseUrl/threads/$threadId/messages'),
      headers: _headers(apiKey),
      body: jsonEncode({'role': 'user', 'content': content}),
    );
    if (res.statusCode != 200) {
      debugPrint('Failed to add message: ${res.statusCode} ${res.body}');
    }
    return res.statusCode == 200;
  }

  static Future<String?> _runAssistant(
    String threadId,
    String assistantId,
    String apiKey,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/threads/$threadId/runs'),
      headers: _headers(apiKey),
      body: jsonEncode({
        'assistant_id': assistantId,
        'tools': [
          {
            'type': 'function',
            'function': {'name': 'daily_dose_generator'},
          },
        ],
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

  static Future<String?> _waitForRunCompletion(
    String threadId,
    String runId,
    String apiKey,
  ) async {
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('Polling status... attempt ${i + 1}/30');
      final res = await http.get(
        Uri.parse('$_baseUrl/threads/$threadId/runs/$runId'),
        headers: _headers(apiKey),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data['status'];
        if (status == 'completed') {
          return _getMessages(threadId, apiKey);
        } else if (status == 'failed' || status == 'cancelled') {
          throw Exception('Run failed or cancelled');
        }
      } else {
        debugPrint('❌ Error while polling run: ${res.statusCode} ${res.body}');
      }
    }
    throw Exception('Timeout waiting for run to complete');
  }

  static Future<String?> _getMessages(String threadId, String apiKey) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/threads/$threadId/messages'),
      headers: _headers(apiKey),
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

  static Future<void> storeDailyDosesToRealtimeDB(
    String surveyId,
    List<Map<String, String>> doses,
  ) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final ref = FirebaseDatabase.instance.ref(
      "users/$userId/daily_doses/$surveyId",
    );
    final existing = await ref.once();

    if (existing.snapshot.exists) {
      debugPrint('⏳ Daily dose already exists for $surveyId');
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {'surveyId': surveyId, 'createdAt': timestamp, 'doses': doses};

    await ref.set(data);
    debugPrint('✅ Daily doses saved under users/$userId/daily_doses/$surveyId');
  }

  static Map<String, String> _headers(String apiKey) {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'OpenAI-Beta': 'assistants=v2',
    };
  }
}
