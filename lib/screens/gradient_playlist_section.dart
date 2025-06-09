import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class GradientPlaylistSection extends StatefulWidget {
  const GradientPlaylistSection({super.key});

  @override
  State<GradientPlaylistSection> createState() => _GradientPlaylistSectionState();
}

class _GradientPlaylistSectionState extends State<GradientPlaylistSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late Future<List<Playlist>> _playlistsFuture;
  List<Playlist>? _displayPlaylists;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(_controller);
  }

  void _loadPlaylists() {
    setState(() {
      _playlistsFuture = PlaylistService.generatePlaylists();
    });
  }

  Future<void> _refreshPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getInt('last_ai_run_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastRun;

    if (diff < 24 * 60 * 60 * 1000) {
      debugPrint('📦 Showing cached playlists');
    } else {
      debugPrint('♻️ Regenerating playlists');
      await PlaylistService.generatePlaylists(); // Triggers regeneration
    }

    _loadPlaylists();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper method to check if URL is a valid music platform URL
  bool _isValidMusicUrl(String url) {
    if (url.isEmpty) return false;
    
    // Check for actual music platform URLs (not placeholder/example URLs)
    return url.contains('open.spotify.com') || 
           url.contains('music.apple.com') ||
           url.contains('youtube.com') ||
           url.contains('youtu.be');
  }

  // Helper method to generate search URLs for music platforms
  String _generateSpotifySearchUrl(String mood, String title) {
    final searchQuery = '$mood $title music playlist';
    final encodedQuery = Uri.encodeComponent(searchQuery);
    return 'https://open.spotify.com/search/$encodedQuery';
  }

  String _generateAppleMusicSearchUrl(String mood, String title) {
    final searchQuery = '$mood $title music playlist';
    final encodedQuery = Uri.encodeComponent(searchQuery);
    return 'https://music.apple.com/search?term=$encodedQuery';
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) {
      debugPrint('URL is empty');
      _showUrlErrorSnackBar();
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint('Invalid URL format: $url');
      _showUrlErrorSnackBar();
      return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
        _showUrlErrorSnackBar();
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      _showUrlErrorSnackBar();
    }
  }

  void _showUrlErrorSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open music app. Please check if the app is installed.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildMusicPlatformButton({
    required String url,
    required String fallbackUrl,
    required IconData icon,
    required Color iconColor,
    required String platform,
  }) {
    final isValidUrl = _isValidMusicUrl(url);
    final urlToUse = isValidUrl ? url : fallbackUrl;
    
    return Tooltip(
      message: 'Open in $platform',
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: () => _launchUrl(urlToUse),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final alignmentX = _animation.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(alignmentX, 0),
                end: Alignment(alignmentX - 2, 0),
                colors: const [
                  Color(0xFFD1C4E9),
                  Color(0xFFB39DDB),
                  Color(0xFF9575CD),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '🎵 Music Therapy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _refreshPlaylists,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Playlist>>(
                    future: _playlistsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Could not load music recommendations'));
                      }

                      final playlists = snapshot.data!;

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: playlists.length.clamp(0, 3),
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final p = playlists[index];
                          
                          // Generate fallback search URLs
                          final spotifySearchUrl = _generateSpotifySearchUrl(p.mood, p.title);
                          final appleMusicSearchUrl = _generateAppleMusicSearchUrl(p.mood, p.title);
                          
                          return Container(
                            width: 220,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.95 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.mood,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  p.description,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    _buildMusicPlatformButton(
                                      url: p.spotifyUrl,
                                      fallbackUrl: spotifySearchUrl,
                                      icon: Icons.music_note,
                                      iconColor: Colors.green,
                                      platform: 'Spotify',
                                    ),
                                    _buildMusicPlatformButton(
                                      url: p.appleMusicUrl,
                                      fallbackUrl: appleMusicSearchUrl,
                                      icon: Icons.music_note,
                                      iconColor: Colors.black,
                                      platform: 'Apple Music',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}