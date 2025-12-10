import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../models/sealed_letter_model.dart';

class SealedLettersPage extends StatefulWidget {
  const SealedLettersPage({super.key});

  @override
  State<SealedLettersPage> createState() => _SealedLettersPageState();
}

class _SealedLettersPageState extends State<SealedLettersPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _contentController = TextEditingController();
  DateTime? _revealDate;
  TimeOfDay? _revealTime;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createSealedLetter() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter letter content')),
      );
      return;
    }

    if (_revealDate == null || _revealTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select reveal date and time')),
      );
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUserId = appProvider.currentUserId;
    final settings = appProvider.settings;

    if (currentUserId == null || settings == null) return;

    final revealAt = DateTime(
      _revealDate!.year,
      _revealDate!.month,
      _revealDate!.day,
      _revealTime!.hour,
      _revealTime!.minute,
    );

    if (revealAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reveal time must be in the future')),
      );
      return;
    }

    final partnerId = settings.getPartnerId(currentUserId);
    if (partnerId == null || partnerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No partner connected yet')),
        );
      }
      return;
    }

    final letter = SealedLetterModel(
      id: '',
      senderId: currentUserId,
      receiverId: partnerId,
      content: _contentController.text.trim(),
      createdAt: DateTime.now(),
      revealAt: revealAt,
      isRevealed: false,
    );

    await _firebaseService.createSealedLetter(letter);

    _contentController.clear();
    _revealDate = null;
    _revealTime = null;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sealed letter created')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final settings = appProvider.settings;
        final accentColor = appProvider.accentColor;

        if (settings == null || !settings.sealedLettersEnabled) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sealed Letters')),
            body: const Center(
              child: Text('Sealed Letters are disabled in settings'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sealed Letters'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Letter Content',
                  hintText: 'Write your sealed letter...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Reveal Date'),
                subtitle: Text(
                  _revealDate != null
                      ? DateFormat('MMMM d, y').format(_revealDate!)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _revealDate = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('Reveal Time'),
                subtitle: Text(
                  _revealTime != null
                      ? _revealTime!.format(context)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => _revealTime = picked);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createSealedLetter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Seal Letter'),
              ),
            ],
          ),
        );
      },
    );
  }
}

