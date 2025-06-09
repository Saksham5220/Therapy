import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/playlist.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<List<Playlist>> generatePlaylists() async {
    debugPrint('[PlaylistService] ▶ Starting generatePlaylists');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[PlaylistService] ❌ No authenticated user');
      return _getFallbackPlaylists();
    }

    try {
      final cached = await getCachedPlaylists();
      if (cached != null && cached.isNotEmpty) {
        debugPrint('[PlaylistService] 📦 Loaded ${cached.length} cached AI playlists');
        return cached;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('survey_responses')
          .orderBy('timestamp', descending: true)
          .limit(15)
          .get();

      List<Map<String, dynamic>> surveyResponses;

      if (snapshot.docs.isNotEmpty) {
        surveyResponses = snapshot.docs.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value.data();
          return {
            'question': data['question'] ?? '',
            'answer': data['answer'] ?? '',
            'questionIndex': index,
            'timestamp': data['timestamp'],
          };
        }).toList();
        debugPrint('[PlaylistService] 📋 Found ${surveyResponses.length} Firestore responses');
      } else {
        debugPrint('[PlaylistService] ❌ No Firestore responses, using Realtime DB fallback');
        surveyResponses = await getCachedSurveyResponses();
        if (surveyResponses.isEmpty) return _getFallbackPlaylists();
      }

      final playlistData = await _generatePlaylistsWithAI(surveyResponses);
      if (playlistData != null && playlistData.isNotEmpty) {
        final playlists = playlistData.map(_convertToPlaylist).toList();

        try {
          await cachePlaylists(playlists);
        } catch (e) {
          debugPrint('[PlaylistService] ⚠️ Firestore cache failed, saving locally: $e');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_ai_playlist_doses', jsonEncode(playlistData));
          await prefs.setInt('last_ai_run_time', DateTime.now().millisecondsSinceEpoch);
        }

        return playlists.length >= 3
            ? playlists.take(3).toList()
            : [...playlists, ..._getFallbackPlaylists()].take(3).toList();
      }
    } catch (e) {
      debugPrint('[PlaylistService] ❌ Error generating playlists: $e');
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
    try {
      final prompt = _formatPlaylistRequest(responses);
      debugPrint('🎵 Sending AI prompt:\n$prompt');
      return await _mockPlaylistGeneration(responses);
    } catch (e) {
      debugPrint('[PlaylistService] ❌ AI generation error: $e');
      return null;
    }
  }

  static String _formatPlaylistRequest(List<Map<String, dynamic>> responses) {
    final buffer = StringBuffer();
    buffer.writeln("Generate 3 JSON playlists based on the following emotional responses.");
    buffer.writeln("Each playlist must include: mood (2 words max), title (4 words max), description (max 25 words), and 2 music links.");
    buffer.writeln("\nUser Responses:\n");

    for (int i = 0; i < responses.length; i++) {
      final r = responses[i];
      buffer.writeln("Q${i + 1}: ${r['question']}");
      buffer.writeln("A${i + 1}: ${r['answer']}\n");
    }

    buffer.writeln("""
Return in JSON format:
{
  "playlists": [
    {
      "mood": "Calm Focus",
      "title": "Flow State",
      "description": "Soothing background music to maintain concentration.",
      "songs": [
        "https://open.spotify.com/track/example1",
        "https://music.apple.com/us/song/example2"
      ]
    }
  ]
}
""");

    return buffer.toString();
  }

  static Future<List<Map<String, String>>> _mockPlaylistGeneration(List<Map<String, dynamic>> responses) async {
    await Future.delayed(const Duration(seconds: 2));
    final all = responses.map((r) => '${r['question']} ${r['answer']}').join(' ').toLowerCase();

    final List<Map<String, String>> playlists = [];

    if (all.contains('stress') || all.contains('anxiety')) {
      playlists.add({
        'mood': 'Calm',
        'title': 'Stress Relief',
        'description': 'Ambient sounds to ease tension.',
        'spotifyUrl': '',
        'appleMusicUrl': ''
      });
    }
    if (all.contains('sad') || all.contains('depressed')) {
      playlists.add({
        'mood': 'Joyful',
        'title': 'Mood Booster',
        'description': 'Upbeat tracks to lift your spirit.',
        'spotifyUrl': '',
        'appleMusicUrl': ''
      });
    }
    if (all.contains('focus') || all.contains('work')) {
      playlists.add({
        'mood': 'Focused',
        'title': 'Deep Work',
        'description': 'Lo-fi beats to stay productive.',
        'spotifyUrl': '',
        'appleMusicUrl': ''
      });
    }

    while (playlists.length < 3) {
      playlists.add({
        'mood': 'Balanced',
        'title': 'Daily Blend',
        'description': 'A soothing mix of calm and joy.',
        'spotifyUrl': '',
        'appleMusicUrl': ''
      });
    }

    return playlists.take(3).toList();
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

  static List<Playlist> _getFallbackPlaylists() {
    return [
      Playlist(
        mood: 'Calm',
        title: 'Morning Peace',
        description: 'Gentle acoustic vibes to begin your day.',
        spotifyUrl: 'https://open.spotify.com/track/3Qm86XLflmIXVm1wcwkgDK',
        appleMusicUrl: 'https://music.apple.com/us/album/peaceful-mind/1451234567',
      ),
      Playlist(
        mood: 'Focused',
        title: 'Deep Work',
        description: 'Lo-fi and ambient tracks to keep you in flow.',
        spotifyUrl: 'https://open.spotify.com/track/6gx9f4GhNFzfwB2doqbEIb',
        appleMusicUrl: 'https://music.apple.com/us/album/focus-mode/1476543210',
      ),
      Playlist(
        mood: 'Uplifting',
        title: 'Mood Boost',
        description: 'Happy songs for brighter days.',
        spotifyUrl: 'https://open.spotify.com/track/1ahDOtG9vPSOmsWgNW0BEY',
        appleMusicUrl: 'https://music.apple.com/us/album/feel-good-vibes/1509876543',
      ),
    ];
  }

  static Future<List<Playlist>?> getCachedPlaylists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

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
      debugPrint('[PlaylistService] ❌ Error loading cached playlists: $e');
    }

    return null;
  }

  static Future<void> cachePlaylists(List<Playlist> playlists) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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
    } catch (e) {
      debugPrint('[PlaylistService] ❌ Error saving playlists: $e');
    }
  }
}
