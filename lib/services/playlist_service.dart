import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';

class PlaylistService {
  static final _firestore = FirebaseFirestore.instance;
  static Future<List<Playlist>>? _ongoingRequest;
  static const String _openAIApiKey = 'OPENAI_API_KEY';

  static Future<List<Playlist>> generatePlaylists() {
    _ongoingRequest ??= _generatePlaylistsInternal();
    return _ongoingRequest!;
  }

  static Future<List<Playlist>> _generatePlaylistsInternal() async {
    debugPrint('[PlaylistService] ▶ Starting generatePlaylists');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _getFallbackPlaylists();

    try {
      if (!await _shouldRegenerateAI()) {
        final cached = await getCachedPlaylists();
        if (cached != null && cached.isNotEmpty) {
          debugPrint('[PlaylistService] 📦 Using cached playlists');
          return cached;
        }
      }

      List<Map<String, dynamic>> surveyResponses;
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('survey_responses')
            .orderBy('timestamp', descending: true)
            .limit(15)
            .get();

        if (snapshot.docs.isNotEmpty) {
          surveyResponses = snapshot.docs.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value.data();
            return {
              'question': data['question']?.toString() ?? '',
              'answer': data['answer']?.toString() ?? '',
              'questionIndex': index,
              'timestamp': data['timestamp'],
            };
          }).toList();
          debugPrint('[PlaylistService] 📋 Loaded ${surveyResponses.length} Firestore responses');
        } else {
          debugPrint('[PlaylistService] ❌ Firestore empty, fallback to Realtime DB');
          surveyResponses = await getCachedSurveyResponses();
        }
      } catch (e) {
        debugPrint('[PlaylistService] ❌ Firestore error: $e');
        surveyResponses = await getCachedSurveyResponses();
      }

      if (surveyResponses.isEmpty) return _getFallbackPlaylists();

      final playlistData = await _generatePlaylistsWithAI(surveyResponses);
      if (playlistData != null && playlistData.isNotEmpty) {
        final playlists = playlistData.map(_convertToPlaylist).toList();
        await cachePlaylists(playlists);
        return playlists.take(3).toList();
      }
    } catch (e) {
      debugPrint('[PlaylistService] ❌ Error: $e');
    }

    return _getFallbackPlaylists();
  }

  static Future<List<Map<String, dynamic>>> getCachedSurveyResponses() async {
    final snapshot = await FirebaseDatabase.instance.ref("survey_responses").get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.entries.map((entry) {
      final item = Map<String, dynamic>.from(entry.value);
      return {
        'question': item['question'] ?? '',
        'answer': item['answer'] ?? '',
        'questionIndex': item['questionIndex'],
        'timestamp': item['timestamp'],
      };
    }).toList();
  }

  static Future<List<Map<String, String>>?> _generatePlaylistsWithAI(List<Map<String, dynamic>> responses) async {
    final prompt = _formatPlaylistRequest(responses);
    debugPrint('[PlaylistService] 🤖 Sending prompt to OpenAI...');

    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_openAIApiKey",
      },
      body: jsonEncode({
        "model": "gpt-4",
        "messages": [
          {
            "role": "system", 
            "content": "You are a helpful music therapist who recommends playlists to improve mental health. You must provide real, working Spotify and Apple Music URLs, not placeholder links."
          },
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final content = decoded['choices'][0]['message']['content'];
      debugPrint('[PlaylistService] ✅ OpenAI Response:\n$content');

      try {
        // Try to extract JSON from the response
        String jsonContent = content;
        if (content.contains('```json')) {
          final start = content.indexOf('```json') + 7;
          final end = content.indexOf('```', start);
          if (end != -1) {
            jsonContent = content.substring(start, end).trim();
          }
        } else if (content.contains('{')) {
          final start = content.indexOf('{');
          final end = content.lastIndexOf('}') + 1;
          jsonContent = content.substring(start, end);
        }

        final parsed = jsonDecode(jsonContent);
        final List<dynamic> playlistsJson = parsed['playlists'];
        
        return playlistsJson.map<Map<String, String>>((p) {
          // Handle both array format and object format for songs
          String spotifyUrl = '';
          String appleMusicUrl = '';
          
          if (p['songs'] is List && (p['songs'] as List).length >= 2) {
            spotifyUrl = p['songs'][0]?.toString() ?? '';
            appleMusicUrl = p['songs'][1]?.toString() ?? '';
          } else if (p['spotify_url'] != null || p['apple_music_url'] != null) {
            spotifyUrl = p['spotify_url']?.toString() ?? '';
            appleMusicUrl = p['apple_music_url']?.toString() ?? '';
          }
          
          return {
            'mood': p['mood']?.toString() ?? '',
            'title': p['title']?.toString() ?? '',
            'description': p['description']?.toString() ?? '',
            'spotifyUrl': spotifyUrl,
            'appleMusicUrl': appleMusicUrl,
          };
        }).toList();
      } catch (parseError) {
        debugPrint('[PlaylistService] ❌ JSON Parse Error: $parseError');
        debugPrint('[PlaylistService] Raw content: $content');
        return null;
      }
    } else {
      debugPrint('[PlaylistService] ❌ OpenAI API failed: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  static String _formatPlaylistRequest(List<Map<String, dynamic>> responses) {
    final buffer = StringBuffer();
    buffer.writeln("Based on these emotional responses from a mental health survey, recommend 3 therapeutic music playlists.");
    buffer.writeln("");
    buffer.writeln("REQUIREMENTS:");
    buffer.writeln("- Each playlist should have: mood (max 2 words), title (max 4 words), description (max 25 words)");
    buffer.writeln("- Provide REAL working Spotify and Apple Music URLs - search for actual playlists that match the mood");
    buffer.writeln("- Focus on music that helps with the emotional states mentioned in the responses");
    buffer.writeln("- Respond ONLY with valid JSON in this exact format:");
    buffer.writeln("");
    buffer.writeln("""
{
  "playlists": [
    {
      "mood": "Calm Focus",
      "title": "Peaceful Mind",
      "description": "Gentle instrumental music for relaxation and mental clarity",
      "songs": [
        "https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd",
        "https://music.apple.com/us/playlist/chill-instrumental/pl.u-oZylaXPU6oK5v"
      ]
    }
  ]
}
""");
    buffer.writeln("");
    buffer.writeln("User Emotional Survey Responses:");
    buffer.writeln("");

    for (int i = 0; i < responses.length; i++) {
      final r = responses[i];
      buffer.writeln("Q${i + 1}: ${r['question']}");
      buffer.writeln("A${i + 1}: ${r['answer']}");
      buffer.writeln("");
    }

    buffer.writeln("Generate playlists that address the emotional needs expressed in these responses.");

    return buffer.toString();
  }

  static Playlist _convertToPlaylist(Map<String, String> data) {
    return Playlist(
      mood: data['mood'] ?? 'Relax',
      title: data['title'] ?? 'My Playlist',
      description: data['description'] ?? '',
      spotifyUrl: data['spotifyUrl'] ?? '',
      appleMusicUrl: data['appleMusicUrl'] ?? '',
    );
  }

  static Future<void> cachePlaylists(List<Playlist> playlists) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    try {
      // Store to Firestore
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('generated_content')
            .doc('playlists')
            .set({
          'playlists': playlists.map((p) => {
                'mood': p.mood,
                'title': p.title,
                'description': p.description,
                'spotifyUrl': p.spotifyUrl,
                'appleMusicUrl': p.appleMusicUrl,
              }).toList(),
          'generated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[PlaylistService] ❌ Firestore save failed: $e');
    }

    // Also cache locally
    try {
      final json = jsonEncode(playlists.map((p) => {
            'mood': p.mood,
            'title': p.title,
            'description': p.description,
            'spotifyUrl': p.spotifyUrl,
            'appleMusicUrl': p.appleMusicUrl,
          }).toList());
      await prefs.setString('cached_ai_playlist_doses', json);
      await prefs.setInt('last_ai_run_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[PlaylistService] ❌ Local cache failed: $e');
    }
  }

  static Future<List<Playlist>?> getCachedPlaylists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Try Firestore
    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('generated_content')
          .doc('playlists')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final playlistsData = data?['playlists'] as List<dynamic>?;
        if (playlistsData != null) {
          return playlistsData.map((item) {
            final map = item as Map<String, dynamic>;
            return Playlist(
              mood: map['mood'] ?? '',
              title: map['title'] ?? '',
              description: map['description'] ?? '',
              spotifyUrl: map['spotifyUrl'] ?? '',
              appleMusicUrl: map['appleMusicUrl'] ?? '',
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('[PlaylistService] ⚠️ Firestore cache error: $e');
    }

    // If Firestore fails, try local SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('cached_ai_playlist_doses');
      if (json != null) {
        final decoded = jsonDecode(json) as List;
        return decoded.map((item) {
          final map = item as Map<String, dynamic>;
          return Playlist(
            mood: map['mood'] ?? '',
            title: map['title'] ?? '',
            description: map['description'] ?? '',
            spotifyUrl: map['spotifyUrl'] ?? '',
            appleMusicUrl: map['appleMusicUrl'] ?? '',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[PlaylistService] ⚠️ Local cache load error: $e');
    }

    return null;
  }

  static List<Playlist> _getFallbackPlaylists() {
    return [
      Playlist(
        mood: 'Calm',
        title: 'Morning Peace',
        description: 'Gentle acoustic vibes to begin your day.',
        spotifyUrl: 'https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd',
        appleMusicUrl: 'https://music.apple.com/us/playlist/peaceful-morning/pl.u-oZylaGKU6oK5v',
      ),
      Playlist(
        mood: 'Focused',
        title: 'Deep Work',
        description: 'Lo-fi and ambient tracks to keep you in flow.',
        spotifyUrl: 'https://open.spotify.com/playlist/37i9dQZF1DWZeKCadgRdKQ',
        appleMusicUrl: 'https://music.apple.com/us/playlist/focus-flow/pl.u-8aAVVdDTe4pN5',
      ),
      Playlist(
        mood: 'Uplifting',
        title: 'Mood Boost',
        description: 'Happy songs for brighter days.',
        spotifyUrl: 'https://open.spotify.com/playlist/37i9dQZF1DX3rxVfibe1L0',
        appleMusicUrl: 'https://music.apple.com/us/playlist/good-vibes/pl.u-kv9l1p8uvvp77',
      ),
    ];
  }

  static Future<bool> _shouldRegenerateAI() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDoseTime = prefs.getInt('last_ai_dose_time') ?? 0;
    final lastPlaylistTime = prefs.getInt('last_ai_run_time') ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final earliest = [lastDoseTime, lastPlaylistTime].where((e) => e > 0).fold(now, (a, b) => a < b ? a : b);

    return now - earliest >= 24 * 60 * 60 * 1000;
  }
}