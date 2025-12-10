import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';

class DataExport {
  static Future<void> exportAllData(
    BuildContext context,
    AppProvider appProvider,
  ) async {
    try {
      final firebaseService = FirebaseService();
      final currentUserId = appProvider.currentUserId;
      final settings = appProvider.settings;

      if (currentUserId == null || settings == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
        return;
      }

      // Collect all data
      final exportData = <String, dynamic>{
        'exportDate': DateTime.now().toIso8601String(),
        'settings': settings.toMap(),
      };

      // Get moods
      final moodsSnapshot = await firebaseService
          .watchMoodsForDateRange(
            DateTime(2000),
            DateTime.now(),
          )
          .first;
      exportData['moods'] = moodsSnapshot.map((m) => m.toMap()).toList();

      // Get whispers
      final partnerId = settings.getPartnerId(currentUserId) ?? '';
      final whispersSnapshot = await firebaseService
          .watchWhispers(currentUserId, partnerId)
          .first;
      exportData['whispers'] =
          whispersSnapshot.map((w) => w.toMap()).toList();

      // Get sealed letters
      final lettersSnapshot = await firebaseService
          .watchSealedLetters(currentUserId, partnerId)
          .first;
      exportData['sealedLetters'] =
          lettersSnapshot.map((l) => l.toMap()).toList();

      // Export as JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      await _saveFile('raven_export_${DateTime.now().millisecondsSinceEpoch}.json', jsonString);

      // Export as TXT (log format)
      final txtString = _formatAsTxt(exportData);
      await _saveFile('raven_export_${DateTime.now().millisecondsSinceEpoch}.txt', txtString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  static String _formatAsTxt(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('=== RAVEN ETERNAL BOND EXPORT ===');
    buffer.writeln('Export Date: ${data['exportDate']}');
    buffer.writeln('');

    if (data['settings'] != null) {
      buffer.writeln('=== SETTINGS ===');
      final settings = data['settings'] as Map<String, dynamic>;
      buffer.writeln('User 1: ${settings['user1Nickname']}');
      buffer.writeln('User 2: ${settings['user2Nickname']}');
      buffer.writeln('Meeting Date: ${settings['meetingDate']}');
      buffer.writeln('');
    }

    if (data['moods'] != null) {
      buffer.writeln('=== MOODS ===');
      final moods = data['moods'] as List;
      for (final mood in moods) {
        buffer.writeln('${mood['timestamp']}: ${mood['mood']}');
      }
      buffer.writeln('');
    }

    if (data['whispers'] != null) {
      buffer.writeln('=== WHISPERS ===');
      final whispers = data['whispers'] as List;
      for (final whisper in whispers) {
        buffer.writeln('${whisper['timestamp']}: ${whisper['text']}');
      }
      buffer.writeln('');
    }

    if (data['sealedLetters'] != null) {
      buffer.writeln('=== SEALED LETTERS ===');
      final letters = data['sealedLetters'] as List;
      for (final letter in letters) {
        buffer.writeln('Created: ${letter['createdAt']}');
        buffer.writeln('Reveal: ${letter['revealAt']}');
        buffer.writeln('Content: ${letter['content']}');
        buffer.writeln('');
      }
    }

    return buffer.toString();
  }

  static Future<void> _saveFile(String filename, String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
  }
}

