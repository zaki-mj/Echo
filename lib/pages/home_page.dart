import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../models/mood_model.dart';
import '../models/settings_model.dart';
import '../utils/moon_phase.dart';
import '../widgets/mood_widget.dart';
import '../widgets/whisper_preview_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  MoodModel? _user1Mood;
  MoodModel? _user2Mood;

  @override
  void initState() {
    super.initState();
    _loadMoods();
  }

  void _loadMoods() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final settings = appProvider.settings;
    final currentUserId = appProvider.currentUserId;

    if (settings == null || currentUserId == null) return;

    final partnerId = settings.getPartnerId(currentUserId);

    // Determine user's gender to assign moods correctly
    final userGender = settings.getUserGender(currentUserId);
    final isMale = userGender == Gender.male;

    // Load current user's mood
    _firebaseService.watchMoods(currentUserId).listen((moods) async {
      if (mounted && moods.isNotEmpty) {
        final mood = moods.first;
        // Check if mood needs to be reset
        if (mood.resetAt != null && DateTime.now().isAfter(mood.resetAt!)) {
          // Mood has expired, user needs to set a new one
          setState(() {
            if (isMale) {
              _user1Mood = null;
            } else {
              _user2Mood = null;
            }
          });
        } else {
          setState(() {
            if (isMale) {
              _user1Mood = mood;
            } else {
              _user2Mood = mood;
            }
          });
        }
      } else if (mounted) {
        setState(() {
          if (isMale) {
            _user1Mood = null;
          } else {
            _user2Mood = null;
          }
        });
      }
    });

    // Load partner's mood if partner exists
    if (partnerId != null && partnerId.isNotEmpty) {
      _firebaseService.watchMoods(partnerId).listen((moods) {
        if (mounted && moods.isNotEmpty) {
          final mood = moods.first;
          // Check if mood needs to be reset
          if (mood.resetAt != null && DateTime.now().isAfter(mood.resetAt!)) {
            setState(() {
              if (isMale) {
                _user2Mood = null;
              } else {
                _user1Mood = null;
              }
            });
          } else {
            setState(() {
              if (isMale) {
                _user2Mood = mood;
              } else {
                _user1Mood = mood;
              }
            });
          }
        } else if (mounted) {
          setState(() {
            if (isMale) {
              _user2Mood = null;
            } else {
              _user1Mood = null;
            }
          });
        }
      });
    }
  }

  int _calculateNightsSince(DateTime meetingDate) {
    return DateTime.now().difference(meetingDate).inDays;
  }

  Future<void> _handleMoodDoubleTap(String partnerNickname) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.settings?.touchOfNightEnabled ?? false) {
      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$partnerNickname poked you'),
            backgroundColor: appProvider.accentColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showMoodSelector(BuildContext context, AppProvider appProvider) {
    final moods = ['bat', 'moon', 'rose', 'thorns', 'blood', 'crown', 'skull', 'star'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Your Mood',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: moods.length,
              itemBuilder: (context, index) {
                final mood = moods[index];
                return GestureDetector(
                  onTap: () async {
                    final currentUserId = appProvider.currentUserId;
                    final settings = appProvider.settings;
                    if (currentUserId != null && settings != null) {
                      final resetAt = DateTime.now().add(settings.moodResetInterval);
                      final moodModel = MoodModel(
                        userId: currentUserId,
                        mood: mood,
                        timestamp: DateTime.now(),
                        resetAt: resetAt,
                      );
                      await _firebaseService.saveMood(moodModel);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Card(
                    child: Center(
                      child: Text(
                        _getMoodEmoji(mood),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'bat':
        return '🦇';
      case 'moon':
        return '🌙';
      case 'rose':
        return '🌹';
      case 'thorns':
        return '🌵';
      case 'blood':
        return '🩸';
      case 'crown':
        return '👑';
      case 'skull':
        return '💀';
      case 'star':
        return '⭐';
      default:
        return '🦇';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final settings = appProvider.settings;
        final accentColor = appProvider.accentColor;

        if (settings == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final nightsSince = _calculateNightsSince(settings.meetingDate);
        final moonEmoji = MoonPhase.getMoonEmoji(DateTime.now());
        final moonPhase = MoonPhase.getPhaseName(DateTime.now());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Moon Phase Header
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      moonEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      moonPhase,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              // Eternal Counter
              Card(
                color: accentColor.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Nights since our blood crossed:',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$nightsSince',
                        style: Theme.of(context).textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Side-by-side Moods (Gender-based)
              Builder(
                builder: (context) {
                  final currentUserId = appProvider.currentUserId;
                  if (currentUserId == null) return const SizedBox.shrink();

                  final userGender = settings.getUserGender(currentUserId);
                  final partnerId = settings.getPartnerId(currentUserId);

                  // Determine which mood belongs to which user
                  final isMale = userGender == Gender.male;
                  final currentUserMood = isMale ? _user1Mood : _user2Mood;
                  final partnerMood = isMale ? _user2Mood : _user1Mood;
                  final currentUserNickname = isMale ? settings.maleNickname : settings.femaleNickname;
                  final partnerNickname = isMale ? settings.femaleNickname : settings.maleNickname;

                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Allow user to set their mood
                            _showMoodSelector(context, appProvider);
                          },
                          onDoubleTap: () {
                            if (partnerId != null && partnerId.isNotEmpty) {
                              _handleMoodDoubleTap(partnerNickname);
                            }
                          },
                          child: MoodWidget(
                            nickname: currentUserNickname,
                            mood: currentUserMood,
                            isCurrentUser: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onDoubleTap: () => _handleMoodDoubleTap(currentUserNickname),
                          child: MoodWidget(
                            nickname: partnerNickname,
                            mood: partnerMood,
                            isCurrentUser: false,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick Send Whisper
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Whisper'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Today's Chat Preview
              WhisperPreviewWidget(),
            ],
          ),
        );
      },
    );
  }

  // Helper widget to show moon phase in a custom AppBar if needed
  Widget _buildMoonPhaseHeader() {
    final moonEmoji = MoonPhase.getMoonEmoji(DateTime.now());
    final moonPhase = MoonPhase.getPhaseName(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            moonEmoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            moonPhase,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
