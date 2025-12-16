import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../models/mood_model.dart';
import '../models/settings_model.dart';
import '../models/poke_model.dart';
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
  StreamSubscription<List<PokeModel>>? _pokeSubscription;

  // TODO: Replace with your GitHub username and repository name
  final String _githubUsername = 'zaki-mj';
  final String _githubRepo = 'Echo';

  // IMPORTANT: This is a placeholder. You must generate a Personal Access Token (PAT)
  // with 'repo' scope from your GitHub account settings and store it securely.
  // It is highly recommended to NOT store it in the source code.
  // For this example, we'll use a placeholder.
  final String _githubToken = '//'; //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

  @override
  void initState() {
    super.initState();
    _loadMoods();
    _listenForPokes();
  }

  @override
  void dispose() {
    _pokeSubscription?.cancel();
    super.dispose();
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

  Future<void> _handleMoodDoubleTap(String partnerId, String partnerNickname) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final settings = appProvider.settings;
    final currentUserId = appProvider.currentUserId;

    if (settings == null || currentUserId == null || partnerId.isEmpty) return;

    // Local haptic feedback on sender's device (immediate response)
    if (settings.touchOfNightEnabled) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You poked $partnerNickname'),
            backgroundColor: appProvider.accentColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // Determine sender name based on gender
    final senderName = currentUserId == settings.maleUserId ? settings.maleNickname : settings.femaleNickname;

    // Create poke document so the partner's device can react (vibration + notification)
    final poke = PokeModel(
      id: '',
      senderId: currentUserId,
      receiverId: partnerId,
      senderName: senderName,
      timestamp: DateTime.now(),
      isHandled: false,
    );

    await _firebaseService.sendPoke(poke);
  }

  void _listenForPokes() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUserId = appProvider.currentUserId;

    if (currentUserId == null) return;

    _pokeSubscription = _firebaseService.watchPokes(currentUserId).listen(
      (pokes) async {
        if (!mounted || pokes.isEmpty) return;

        // Handle the most recent unhandled poke
        pokes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final poke = pokes.first;

        // Vibrate / haptic feedback on receiver device
        try {
          final hasVibrator = await Vibration.hasVibrator() ?? false;
          if (hasVibrator) {
            // Short double pulse
            final hasAmplitude = await Vibration.hasAmplitudeControl() ?? false;
            if (hasAmplitude) {
              await Vibration.vibrate(
                pattern: [0, 80, 60, 80],
                intensities: [128, 255],
              );
            } else {
              await Vibration.vibrate(pattern: [0, 80, 60, 80]);
            }
          } else {
            // Fallback to built-in haptics
            await HapticFeedback.heavyImpact();
          }
        } catch (_) {
          // Fallback if vibration API fails
          await HapticFeedback.heavyImpact();
        }

        if (!mounted) return;

        final accentColor = appProvider.accentColor;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${poke.senderName} poked you'),
            backgroundColor: accentColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Mark poke as handled so it doesn't repeat
        await _firebaseService.markPokeHandled(poke.id);
      },
    );
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

  Future<void> _sendNotification(String message) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final settings = appProvider.settings;
    final currentUserId = appProvider.currentUserId;

    if (settings == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send notification: User not configured.')),
      );
      return;
    }

    final partnerId = settings.getPartnerId(currentUserId);
    if (partnerId == null || partnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send notification: Partner not found.')),
      );
      return;
    }

    final partnerGender = settings.getUserGender(partnerId);
    final partnerFcmToken = partnerGender == Gender.male ? settings.maleFcmToken : settings.femaleFcmToken;

    if (partnerFcmToken == null || partnerFcmToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send notification: Partner has not enabled notifications.')),
      );
      return;
    }

    final senderName = settings.getUserGender(currentUserId) == Gender.male ? settings.maleNickname : settings.femaleNickname;

    final url = Uri.parse('https://api.github.com/repos/$_githubUsername/$_githubRepo/dispatches');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/vnd.github.everest-preview+json',
        'Authorization': 'Bearer $_githubToken',
      },
      body: jsonEncode({
        'event_type': 'send-notification',
        'client_payload': {
          'message': message,
          'token': partnerFcmToken,
          'senderName': senderName,
        }
      }),
    );

    if (mounted) {
      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification. Status: ${response.statusCode}\nBody: ${response.body}')),
        );
      }
    }
  }

  void _showNotificationDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send a Notification'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Your message...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _sendNotification(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
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
                          onLongPress: () {
                            // Allow user to set their mood
                            _showMoodSelector(context, appProvider);
                          },
                          onDoubleTap: () {
                            if (partnerId != null && partnerId.isNotEmpty) {
                              _handleMoodDoubleTap(partnerId, partnerNickname);
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
                          onDoubleTap: () {
                            if (partnerId != null && partnerId.isNotEmpty) {
                              _handleMoodDoubleTap(partnerId, currentUserNickname);
                            }
                          },
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
                onPressed: _showNotificationDialog,
                icon: const Icon(Icons.send),
                label: const Text('Send Notification'),
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
