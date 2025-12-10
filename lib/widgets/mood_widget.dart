import 'package:flutter/material.dart';
import '../models/mood_model.dart';

class MoodWidget extends StatelessWidget {
  final String nickname;
  final MoodModel? mood;
  final bool isCurrentUser;

  const MoodWidget({
    super.key,
    required this.nickname,
    this.mood,
    required this.isCurrentUser,
  });

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
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nickname,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (mood != null)
              Text(
                _getMoodEmoji(mood!.mood),
                style: const TextStyle(fontSize: 48),
              )
            else
              Icon(
                Icons.mood_outlined,
                size: 48,
                color: Colors.grey[600],
              ),
            const SizedBox(height: 8),
            if (mood != null)
              Text(
                mood!.mood.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Text(
                'No mood set',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

