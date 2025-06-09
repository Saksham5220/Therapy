// lib/screens/playlist_ai_doses_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaylistAIDosesScreen extends StatelessWidget {
  final List<Map<String, String>> doses;

  const PlaylistAIDosesScreen({super.key, required this.doses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recommended Music'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doses.length,
        itemBuilder: (context, index) {
          final dose = doses[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose['title'] ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dose['answer'] ?? '',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if ((dose['spotifyUrl'] ?? '').isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _launchUrl(dose['spotifyUrl']!),
                          icon: const Icon(Icons.music_note, color: Colors.white),
                          label: const Text('Spotify'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      const SizedBox(width: 12),
                      if ((dose['appleMusicUrl'] ?? '').isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _launchUrl(dose['appleMusicUrl']!),
                          icon: const Icon(Icons.music_note, color: Colors.white),
                          label: const Text('Apple Music'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('❌ Could not launch $url');
    }
  }
}
