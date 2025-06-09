// lib/widgets/gradient_daily_dose_section.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brain_therapy/services/playlist_service.dart';
import '../models/dose.dart';
import '../screens/daily_doseai.dart';
import '../services/ai_services.dart';
import '../services/api_keys.dart'; // Import ApiKeys instead of dotenv

class GradientDailyDoseSection extends StatefulWidget {
  const GradientDailyDoseSection({super.key});

  @override
  State<GradientDailyDoseSection> createState() =>
      _GradientDailyDoseSectionState();
}

class _GradientDailyDoseSectionState extends State<GradientDailyDoseSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late Future<List<Dose>> _dosesFuture;
  List<Dose>? _displayDoses;
  bool _useAiGenerated = true;
  String? _currentUserId;
  Map<String, dynamic>? _userStats;

  @override
  void _startPlaylistRetryLoop() async {
    while (mounted) {
      try {
        final playlists = await PlaylistService.generatePlaylists();
        if (playlists.isNotEmpty) {
          debugPrint('✅ PlaylistService: Successfully generated playlists');
          break;
        }
      } catch (e) {
        debugPrint('[RetryLoop] ❌ Error generating playlists: $e');
      }

      debugPrint('[RetryLoop] ⏳ Retrying playlist generation in 60s...');
      await Future.delayed(const Duration(seconds: 60));
    }
  }

  @override
  void initState() {
    super.initState();

    _getCurrentUser();
    _initializeAIService();
    _debugPrintResponses();
    _loadUserStats();

    _dosesFuture =
        _useAiGenerated ? _fetchAIGeneratedDoses() : _fetchDosesFromFirebase();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(_controller);
    _startPlaylistRetryLoop();
  }

  /// Get current user information
  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUserId = user?.uid;
    });

    if (_currentUserId != null) {
      debugPrint('✅ Current user ID: $_currentUserId');
    } else {
      debugPrint('❌ No authenticated user found');
    }
  }

  /// Load user AI dose statistics
  void _loadUserStats() async {
    if (_currentUserId == null) return;

    try {
      final stats = await AIService.getUserAIDoseStats();
      if (!mounted || stats == null) return;

      setState(() {
        _userStats = stats;
      });
      debugPrint('📊 User AI dose stats loaded: $stats');
    } catch (e) {
      debugPrint('❌ Error loading user stats: $e');
    }
  }

  /// Initialize AI Service using ApiKeys
  void _initializeAIService() {
    // Use ApiKeys class instead of dotenv
    if (ApiKeys.isValidApiKey()) {
      AIService.initialize(
        ApiKeys.openaiApiKey,
      ); // Pass the API key for compatibility
      debugPrint('✅ AIService initialized with ApiKeys configuration');
    } else {
      debugPrint('❌ Invalid API key configuration in ApiKeys');
    }
  }

  /// Debug method to print survey responses
  void _debugPrintResponses() async {
    debugPrint(
      '🔍 GradientDailyDoseSection: Debug - Printing all survey responses for user $_currentUserId...',
    );
    await DailyDoseAI.fetchAndPrintAllSurveyResponses();

    // Also debug cached doses if they exist
    try {
      final responses = await DailyDoseAI.getSurveyResponses();
      if (responses.isNotEmpty) {
        final surveyId = AIService().generateSurveyId(responses);
        final cachedDoses = await AIService.getCachedAIDoses(surveyId);
        if (cachedDoses != null) {
          debugPrint('🔍 Debug: Found ${cachedDoses.length} cached doses:');
          for (int i = 0; i < cachedDoses.length; i++) {
            final dose = cachedDoses[i];
            debugPrint('  Dose $i: ${dose.toString()}');
          }
        } else {
          debugPrint('🔍 Debug: No cached doses found');
        }
      }
    } catch (e) {
      debugPrint('🔍 Debug error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Dose>> _fetchAIGeneratedDoses() async {
    if (_currentUserId == null) {
      debugPrint('❌ Cannot fetch AI doses: No authenticated user');
      return [];
    }

    try {
      debugPrint(
        '🤖 GradientDailyDoseSection: Starting AI dose generation for user $_currentUserId...',
      );

      final responses = await DailyDoseAI.getSurveyResponses();
      debugPrint(
        '📋 GradientDailyDoseSection: Retrieved ${responses.length} responses for AI processing',
      );

      if (responses.isEmpty) {
        debugPrint(
          '📭 GradientDailyDoseSection: No responses found for AI processing',
        );
        return [];
      }

      final String surveyId = AIService().generateSurveyId(responses);
      debugPrint('🔑 Generated survey ID: $surveyId for user $_currentUserId');

      // Use AIService.sendAllSurveyEntries which handles caching internally
      final aiDoses = await AIService.sendAllSurveyEntries(
        surveyResponses: responses,
        surveyId: surveyId,
      );

      if (aiDoses == null || aiDoses.isEmpty) {
        debugPrint(
          '❌ GradientDailyDoseSection: AI returned no doses for user $_currentUserId',
        );
        return [];
      }

      if (!mounted || !_useAiGenerated) return [];

      // Convert AI doses to Dose objects
      final convertedDoses =
          aiDoses.map<Dose>((entry) {
            debugPrint(
              '🔄 Converting dose: ${entry['title']} - ${entry['subtitle']}',
            );
            return Dose(
              title: entry['title'] ?? 'Untitled',
              subtitle: entry['subtitle'] ?? '',
              answer: entry['answer'] ?? '',
            );
          }).toList();

      // Refresh user stats after generating new doses
      _loadUserStats();

      debugPrint(
        '✅ GradientDailyDoseSection: Successfully processed ${convertedDoses.length} doses for user $_currentUserId',
      );
      return convertedDoses;
    } catch (e) {
      debugPrint(
        '❌ GradientDailyDoseSection: Error generating AI doses for user $_currentUserId: $e',
      );
      return _fetchDosesFromFirebase();
    }
  }

  /// Fetches survey responses from Firebase and converts them to Dose objects (fallback)
  Future<List<Dose>> _fetchDosesFromFirebase() async {
    if (_currentUserId == null) {
      debugPrint('❌ Cannot fetch survey responses: No authenticated user');
      return [];
    }

    try {
      debugPrint(
        '🔍 GradientDailyDoseSection: Starting to fetch survey responses for user $_currentUserId...',
      );

      // Get survey responses from Firebase
      final responses = await DailyDoseAI.getSurveyResponses();

      debugPrint(
        '📊 GradientDailyDoseSection: Retrieved ${responses.length} responses from Firebase for user $_currentUserId',
      );

      if (responses.isEmpty) {
        debugPrint(
          '📭 GradientDailyDoseSection: No responses found for user $_currentUserId',
        );
        return [];
      }

      // Convert survey responses to Dose objects
      List<Dose> doses = [];

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        final question =
            response['question']?.toString() ?? 'No question available';

        // Handle both string and list answers
        String answer;
        final rawAnswer = response['answer'];
        if (rawAnswer is List) {
          answer = rawAnswer.map((item) => item?.toString() ?? '').join(', ');
        } else {
          answer = rawAnswer?.toString() ?? 'No answer provided';
        }

        final questionIndex = response['questionIndex'] ?? i;
        final timestamp = response['timestamp'];

        String title = 'Question ${questionIndex + 1}';
        String subtitle =
            question.length > 50 ? '${question.substring(0, 50)}...' : question;

        if (timestamp != null) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          title += ' • ${dateTime.day}/${dateTime.month}';
        }

        final dose = Dose(title: title, subtitle: subtitle, answer: answer);

        doses.add(dose);
      }

      debugPrint(
        '✅ GradientDailyDoseSection: Successfully created ${doses.length} dose objects for user $_currentUserId',
      );
      return doses;
    } catch (e) {
      debugPrint(
        '❌ GradientDailyDoseSection: Error fetching survey responses for user $_currentUserId: $e',
      );
      throw Exception('Failed to fetch survey responses: $e');
    }
  }

  void _selectFiveUnique(List<Dose> allDoses) {
    if (_displayDoses != null || allDoses.isEmpty) return;
    final rnd = Random();
    final temp = List<Dose>.from(allDoses);
    temp.shuffle(rnd);
    _displayDoses = temp.length <= 5 ? temp : temp.sublist(0, 5);
  }

  void _refreshDoses() {
    setState(() {
      _dosesFuture =
          _useAiGenerated
              ? _fetchAIGeneratedDoses()
              : _fetchDosesFromFirebase();
      _displayDoses = null;
    });
    _loadUserStats(); // Refresh stats when refreshing doses
  }

  void _toggleDoseType() {
    setState(() {
      _useAiGenerated = !_useAiGenerated;
      _dosesFuture =
          _useAiGenerated
              ? _fetchAIGeneratedDoses()
              : _fetchDosesFromFirebase();
      _displayDoses = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final alignmentX = _animation.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(alignmentX, 0),
                end: Alignment(alignmentX - 2, 0),
                colors:
                    _useAiGenerated
                        ? const [
                          Color(0xFFE1BEE7), // Purple theme for AI
                          Color(0xFFCE93D8),
                          Color(0xFFBA68C8),
                        ]
                        : const [
                          Color(0xFFB3E5FC), // Blue theme for survey
                          Color(0xFF81D4FA),
                          Color(0xFF4FC3F7),
                        ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FutureBuilder<List<Dose>>(
              future: _dosesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          _useAiGenerated
                              ? 'Generating AI doses...'
                              : 'Loading survey responses...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _useAiGenerated
                              ? 'Failed to generate AI doses\n${snapshot.error}'
                              : 'Failed to load survey responses\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _refreshDoses,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                _useAiGenerated ? Colors.purple : Colors.blue,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allDoses = snapshot.data ?? [];
                _selectFiveUnique(allDoses);

                if (_displayDoses == null || _displayDoses!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _useAiGenerated
                              ? Icons.psychology
                              : Icons.quiz_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _useAiGenerated
                              ? 'No AI doses available'
                              : 'No survey responses available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Complete the survey to see content here',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: _refreshDoses,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor:
                                    _useAiGenerated
                                        ? Colors.purple
                                        : Colors.blue,
                              ),
                              child: const Text('Refresh'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _toggleDoseType,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white70,
                                foregroundColor:
                                    _useAiGenerated
                                        ? Colors.purple
                                        : Colors.blue,
                              ),
                              child: Text(
                                _useAiGenerated ? 'Show Survey' : 'Show AI',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                final doses = _displayDoses!;

                return Column(
                  children: [
                    // Header with count, type, and controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _useAiGenerated
                                ? 'AI Mental Health Doses (${doses.length})'
                                : 'Survey Highlights (${doses.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _toggleDoseType,
                                icon: Icon(
                                  _useAiGenerated
                                      ? Icons.quiz
                                      : Icons.psychology,
                                  color: Colors.white,
                                ),
                                tooltip:
                                    _useAiGenerated
                                        ? 'Switch to Survey'
                                        : 'Switch to AI',
                              ),
                              IconButton(
                                onPressed: _refreshDoses,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Horizontal list of doses
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: doses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final dose = doses[index];
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dose.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (_useAiGenerated
                                                ? Colors.purple
                                                : Colors.blue)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _useAiGenerated
                                                ? Icons.psychology
                                                : Icons.quiz,
                                            size: 12,
                                            color:
                                                _useAiGenerated
                                                    ? Colors.purple
                                                    : Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${index + 1}/${doses.length}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  _useAiGenerated
                                                      ? Colors.purple
                                                      : Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dose.subtitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      dose.answer,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
