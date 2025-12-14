import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../models/whisper_model.dart';
import '../models/settings_model.dart';
import '../widgets/whisper_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<WhisperModel> _whispers = [];
  Timer? _sealedLetterCheckTimer;
  String? _lastWhisperId; // Track last whisper to detect new ones

  @override
  void initState() {
    super.initState();
    _loadWhispers();
    _checkSealedLetters();
    // Check for sealed letters every minute
    _sealedLetterCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSealedLetters(),
    );
  }

  void _loadWhispers() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final settings = appProvider.settings;
    final currentUserId = appProvider.currentUserId;

    if (settings == null || currentUserId == null) return;

    final partnerId = settings.getPartnerId(currentUserId) ?? '';

    _firebaseService
        .watchWhispers(currentUserId, partnerId)
        .listen((whispers) {
      if (mounted) {
        final reversedWhispers = whispers.reversed.toList();
        
        // Check for new messages from partner
        if (_lastWhisperId != null && reversedWhispers.isNotEmpty) {
          final latestWhisper = reversedWhispers.first;
          if (latestWhisper.id != _lastWhisperId && 
              latestWhisper.senderId == partnerId) {
            // New message from partner - trigger notification/haptic
            _onNewMessage(latestWhisper, settings);
          }
        }
        
        if (reversedWhispers.isNotEmpty) {
          _lastWhisperId = reversedWhispers.first.id;
        }
        
        setState(() {
          _whispers = reversedWhispers;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendWhisper() async {
    if (_messageController.text.trim().isEmpty) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUserId = appProvider.currentUserId;
    final settings = appProvider.settings;

    if (currentUserId == null || settings == null) {
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

    final whisper = WhisperModel(
      id: '', // Will be set by Firestore
      senderId: currentUserId,
      receiverId: partnerId,
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
      isDelivered: false,
      isRead: false,
    );

    await _firebaseService.sendWhisper(whisper);
    _messageController.clear();
  }

  void _onNewMessage(WhisperModel whisper, SettingsModel settings) {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Show notification
    if (mounted) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUserId = appProvider.currentUserId;
      if (currentUserId == null) return;
      
      // Determine partner name based on who sent the message
      final partnerName = whisper.senderId == settings.maleUserId
          ? settings.maleNickname
          : settings.femaleNickname;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.message, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$partnerName: ${whisper.text.length > 30 ? whisper.text.substring(0, 30) + "..." : whisper.text}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: appProvider.accentColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkSealedLetters() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final settings = appProvider.settings;
    final currentUserId = appProvider.currentUserId;

    if (settings == null || currentUserId == null || !settings.sealedLettersEnabled) {
      return;
    }

    final partnerId = settings.getPartnerId(currentUserId);
    if (partnerId == null || partnerId.isEmpty) return;

    // Get all sealed letters
    final letters = await _firebaseService
        .watchSealedLetters(currentUserId, partnerId)
        .first;

    final now = DateTime.now();
    for (final letter in letters) {
      // If reveal time has passed and letter hasn't been revealed
      if (!letter.isRevealed && letter.revealAt.isBefore(now)) {
        // Mark as revealed
        await _firebaseService.markLetterRevealed(letter.id);

        // Convert sealed letter to whisper and add to chat
        final whisper = WhisperModel(
          id: 'letter_${letter.id}',
          senderId: letter.senderId,
          receiverId: letter.receiverId,
          text: '📜 Sealed Letter:\n\n${letter.content}',
          timestamp: letter.revealAt,
          isDelivered: true,
          isRead: false,
        );

        // Add to whispers (this will trigger a reload)
        await _firebaseService.sendWhisper(whisper);

        // Show notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('A sealed letter has been revealed!'),
              backgroundColor: appProvider.accentColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _sealedLetterCheckTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final settings = appProvider.settings;
        final currentUserId = appProvider.currentUserId;
        final accentColor = appProvider.accentColor;

        if (settings == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          children: [
              // Messages List
              Expanded(
                child: _whispers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No whispers yet...',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _whispers.length,
                        itemBuilder: (context, index) {
                          final whisper = _whispers[index];
                          final isMe = whisper.senderId == currentUserId;
                          return WhisperBubble(
                            whisper: whisper,
                            isMe: isMe,
                            accentColor: accentColor,
                          );
                        },
                      ),
              ),

              // Message Input
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a whisper...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendWhisper(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendWhisper,
                      icon: Icon(Icons.send, color: accentColor),
                      style: IconButton.styleFrom(
                        backgroundColor: accentColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

