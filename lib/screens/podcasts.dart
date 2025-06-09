// lib/podcasts.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:url_launcher/url_launcher.dart';

class Podcast {
  final String title;
  final String description;
  final String url;

  Podcast({required this.title, required this.description, required this.url});
}

Future<List<Podcast>> fetchPodcasts() async {
  final List<Podcast> allPodcasts = [];

  // Add sample podcasts first as fallback
  allPodcasts.addAll(_getSamplePodcasts());

  // Try to fetch from real sources
  allPodcasts.addAll(await _fetchFromListenNotes());
  allPodcasts.addAll(await _fetchFromPodcastOne());

  return allPodcasts;
}

List<Podcast> _getSamplePodcasts() {
  return [
    Podcast(
      title: 'The Joe Rogan Experience',
      description: 'Popular long-form podcast',
      url: 'https://open.spotify.com/show/4rOoJ6Egrf8K2IrywzwOMk',
    ),
    Podcast(
      title: 'NPR News Now',
      description: 'Latest news updates',
      url: 'https://www.npr.org/podcasts/500005/npr-news-now',
    ),
    Podcast(
      title: 'Serial',
      description: 'True crime podcast series',
      url: 'https://serialpodcast.org/',
    ),
    Podcast(
      title: 'This American Life',
      description: 'Weekly public radio show',
      url: 'https://www.thisamericanlife.org/',
    ),
  ];
}

Future<List<Podcast>> _fetchFromListenNotes() async {
  try {
    final response = await http.get(Uri.parse('https://www.listennotes.com/'));

    if (response.statusCode != 200) return [];

    final document = parse(response.body);
    final podcasts = <Podcast>[];

    // Try multiple selectors for Listen Notes
    final selectors = [
      '.podcast-item',
      '.search-result-item',
      'a[href*="/podcast/"]',
    ];

    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        for (final elem in elements.take(5)) {
          final titleElem = elem.querySelector(
            'h3, h4, .title, .podcast-title',
          );
          final descElem = elem.querySelector(
            'p, .description, .podcast-description',
          );
          final linkElem = elem.querySelector('a') ?? elem;

          final title = titleElem?.text.trim() ?? '';
          final description =
              descElem?.text.trim() ?? 'Podcast from Listen Notes';
          final href = linkElem.attributes['href'] ?? '';

          if (title.isNotEmpty && href.isNotEmpty) {
            final url =
                href.startsWith('http')
                    ? href
                    : 'https://www.listennotes.com$href';
            podcasts.add(
              Podcast(title: title, description: description, url: url),
            );
          }
        }
        break;
      }
    }

    return podcasts;
  } catch (e) {
    return [];
  }
}

Future<List<Podcast>> _fetchFromPodcastOne() async {
  try {
    final response = await http.get(Uri.parse('https://www.podcastone.com/'));

    if (response.statusCode != 200) return [];

    final document = parse(response.body);
    final podcasts = <Podcast>[];

    final elements = document.querySelectorAll(
      'a[href*="podcast"], .show-item, .podcast-item',
    );

    for (final elem in elements.take(5)) {
      final title = elem.text.trim();
      final href = elem.attributes['href'] ?? '';

      if (title.isNotEmpty && href.isNotEmpty && title.length > 5) {
        final url =
            href.startsWith('http') ? href : 'https://www.podcastone.com$href';
        podcasts.add(
          Podcast(
            title: title,
            description: 'Podcast from PodcastOne',
            url: url,
          ),
        );
      }
    }

    return podcasts;
  } catch (e) {
    return [];
  }
}

class PodcastsPage extends StatelessWidget {
  const PodcastsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Podcast>>(
      future: fetchPodcasts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                const Text('Error loading podcasts'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Rebuild widget
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final podcasts = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: podcasts.length,
          itemBuilder: (context, index) {
            final podcast = podcasts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.podcasts, color: Colors.blue),
                ),
                title: Text(
                  podcast.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  podcast.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: () async {
                  final uri = Uri.parse(podcast.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open podcast')),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
