import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../models/whisper_model.dart';

class WhisperPreviewWidget extends StatelessWidget {
  const WhisperPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUserId = appProvider.currentUserId;
    final settings = appProvider.settings;
    final firebaseService = FirebaseService();

    if (currentUserId == null || settings == null) {
      return const SizedBox.shrink();
    }

    final partnerId = settings.getPartnerId(currentUserId) ?? '';

    return StreamBuilder<List<WhisperModel>>(
      stream: firebaseService.watchWhispers(currentUserId, partnerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final latestWhisper = snapshot.data!.first;
        final isToday = latestWhisper.timestamp.year == DateTime.now().year &&
            latestWhisper.timestamp.month == DateTime.now().month &&
            latestWhisper.timestamp.day == DateTime.now().day;

        if (!isToday) {
          return const SizedBox.shrink();
        }

        return Card(
          child: ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Today\'s Whispers'),
            subtitle: Text(
              latestWhisper.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/chat');
            },
          ),
        );
      },
    );
  }
}

