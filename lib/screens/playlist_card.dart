import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/playlist.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;

  const PlaylistCard({super.key, required this.playlist});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playlist.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              playlist.mood,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(playlist.description),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                debugPrint('🎧 Spotify URL: ${playlist.spotifyUrl}');
                debugPrint('🎧 Apple Music URL: ${playlist.appleMusicUrl}');
                return const SizedBox(); // placeholder widget
              },
            ),
            Row(
              children: [
                if (playlist.spotifyUrl.isNotEmpty)
                    TextButton.icon(
                    onPressed: () => _launchUrl(playlist.spotifyUrl),
                    icon: const Icon(Icons.music_note, color: Colors.green),
                    label: const Text("Spotify"),
                  ),
                if (playlist.appleMusicUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _launchUrl(playlist.appleMusicUrl),
                    icon: const Icon(Icons.library_music, color: Colors.red),
                    label: const Text("Apple Music"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
