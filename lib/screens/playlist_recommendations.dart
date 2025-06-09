// lib/screens/playlist_recommendation.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/playlist_service.dart';
import '../models/playlist.dart';

class PlaylistRecommendation extends StatefulWidget {
  const PlaylistRecommendation({super.key});

  @override
  State<PlaylistRecommendation> createState() => _PlaylistRecommendationState();
}

class _PlaylistRecommendationState extends State<PlaylistRecommendation> {
  bool _isLoading = false;
  bool _isGenerating = false;
  List<Playlist>? _cachedPlaylists;

  @override
  void initState() {
    super.initState();
    _loadCachedPlaylists();
  }

  Future<void> _loadCachedPlaylists() async {
    final cached = await PlaylistService.getCachedPlaylists();
    if (cached != null && mounted) {
      setState(() {
        _cachedPlaylists = cached;
      });
    }
  }

  Future<List<Playlist>> _generateFreshPlaylists() async {
    setState(() => _isGenerating = true);
    try {
      final playlists = await PlaylistService.generatePlaylists();
      await PlaylistService.cachePlaylists(playlists);
      return playlists;
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String _buildAppleSearchUrl(String mood, String title) {
    final query = Uri.encodeComponent('$mood $title music playlist');
    return 'https://music.apple.com/us/search?term=$query';
  }

  Future<void> _openUrl(String url) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open link');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to open link: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Music Therapy',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_cachedPlaylists != null)
                IconButton(
                  onPressed: _isGenerating
                      ? null
                      : () async {
                          try {
                            final fresh = await _generateFreshPlaylists();
                            if (mounted) {
                              setState(() {
                                _cachedPlaylists = fresh;
                              });
                              _showSuccessSnackBar('Playlists updated!');
                            }
                          } catch (_) {
                            _showErrorSnackBar('Failed to generate playlists');
                          }
                        },
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh, color: colorScheme.primary),
                ),
            ],
          ),
        ),
        Expanded(
          child: _cachedPlaylists != null
              ? _PlaylistGrid(
                  playlists: _cachedPlaylists!,
                  onAppleMusic: _buildAppleSearchUrl,
                  onOpenUrl: _openUrl,
                  isLoading: _isLoading,
                  colorScheme: colorScheme,
                )
              : FutureBuilder<List<Playlist>>(
                  future: _generateFreshPlaylists(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingWidget(isGenerating: true);
                    }
                    if (snapshot.hasError || snapshot.data == null || snapshot.data!.length < 3) {
                      return _ErrorWidget(
                        message: 'Unable to load playlists',
                        onRetry: () => setState(() => _cachedPlaylists = null),
                      );
                    }

                    final playlists = snapshot.data!;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _cachedPlaylists = playlists);
                      }
                    });

                    return _PlaylistGrid(
                      playlists: playlists,
                      onAppleMusic: _buildAppleSearchUrl,
                      onOpenUrl: _openUrl,
                      isLoading: _isLoading,
                      colorScheme: colorScheme,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  final List<Playlist> playlists;
  final String Function(String, String) onAppleMusic;
  final Future<void> Function(String) onOpenUrl;
  final bool isLoading;
  final ColorScheme colorScheme;

  const _PlaylistGrid({
    required this.playlists,
    required this.onAppleMusic,
    required this.onOpenUrl,
    required this.isLoading,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlaylistCard(
              playlist: playlists[index],
              icon: Icons.music_note,
              onTap: () => onOpenUrl(onAppleMusic(playlists[index].mood, playlists[index].title)),
              isLoading: isLoading,
              colorScheme: colorScheme,
              showPlayButton: true,
            ),
          );
        }),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final ColorScheme colorScheme;
  final bool showPlayButton;

  const _PlaylistCard({
    required this.playlist,
    required this.icon,
    required this.onTap,
    required this.isLoading,
    required this.colorScheme,
    required this.showPlayButton,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
                  ),
                  const Spacer(),
                  if (showPlayButton)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow, color: colorScheme.onSecondary, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                playlist.mood,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                playlist.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary),
              ),
              const SizedBox(height: 4),
              Text(
                playlist.description,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.7)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  final bool isGenerating;
  const _LoadingWidget({this.isGenerating = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            isGenerating ? 'Analyzing responses...' : 'Loading playlists...',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_off, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.red.shade600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
