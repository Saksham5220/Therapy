import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import '../models/article.dart';

class ArticleService {
  static const String _apiKey = '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'; 
  static const String _baseUrl = 'https://api.openai.com/v1';

  /// Each time this is called, GPT returns two fresh, short, attractive article recommendations.
  static Future<List<Article>> fetchDeepMindReads() async {
    const prompt = '''
You are a helpful mental-health coach. Recommend exactly 2 mental-health articles that are either very recent or widely read (e.g., from leading psychology blogs or major publications). 
For each article, provide:
  • "category": a single-word or short category (e.g. "Relationship", "Burnout Recovery"),
  • "title": a short, attractive, click-worthy title of no more than 8 words,
  • "link": a valid URL pointing to the actual article source (for example: "https://www.psychologytoday.com/us/blog/friendship/articles/XXXXX" or "https://www.nytimes.com/XXXXXX").

Respond with only a JSON array containing 2 objects. Do not add any extra text or explanation.
Example:
[
  {
    "category": "Anxiety",
    "title": "Quiet Your Racing Thoughts Fast",
    "link": "https://www.psychologytoday.com/…"
  },
  {
    "category": "Burnout Recovery",
    "title": "Break Free from Endless Exhaustion",
    "link": "https://www.nytimes.com/…"
  }
]
''';

    try {
      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a mental-health coach recommending concise article titles.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 600,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _fallbackArticles();
      }

      final responseData = jsonDecode(response.body);
      final raw = responseData['choices'][0]['message']['content'] as String? ?? '';
      
      // Strip any ``` fences
      var jsonString =
          raw.replaceAll(RegExp(r'```json?'), '').replaceAll('```', '').trim();

      // Extract JSON array
      final match = RegExp(r'\[.*\]', dotAll: true).firstMatch(jsonString);
      if (match != null) {
        jsonString = match.group(0)!;
      }

      // Validate closing bracket
      if (!jsonString.endsWith(']')) {
        return _fallbackArticles();
      }

      // Parse JSON
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((item) {
        final category = (item['category'] as String?)?.trim() ?? 'General';
        final title = (item['title'] as String?)?.trim() ?? 'Mental Health Read';
        final link = (item['link'] as String?)?.trim() ??
            'https://www.example.com/placeholder';
        return Article(category: category, title: title, link: link);
      }).toList();
    } catch (e) {
      // In case of any error (timeout, parse issue), return fallback
      print('Error fetching articles: $e');
      return _fallbackArticles();
    }
  }

  /// Two static fallback articles if the AI call fails
  static List<Article> _fallbackArticles() {
    return [
      Article(
        category: 'Relationship',
        title: 'Building Emotional Intimacy',
        link:
            'https://www.psychologytoday.com/us/blog/building-emotional-intimacy',
      ),
      Article(
        category: 'Burnout Recovery',
        title: 'Overcoming the Burnout Slump',
        link:
            'https://www.healthline.com/health/overcoming-burnout-slump',
      ),
    ];
  }
}