import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../services/firebase_service.dart';
import '../theme/gothic_theme.dart';

class AppProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  SettingsModel? _settings;
  String? _pairId;
  String? _currentUserId;
  bool _isInitialized = false;

  SettingsModel? get settings => _settings;
  String? get pairId => _pairId;
  String? get currentUserId => _currentUserId;
  bool get isInitialized => _isInitialized;

  ThemeData get theme {
    if (_settings == null) {
      return GothicTheme.getDarkTheme(0);
    }
    return _settings!.isDarkMode
        ? GothicTheme.getDarkTheme(_settings!.accentColorIndex)
        : GothicTheme.getLightTheme(_settings!.accentColorIndex);
  }

  Color get accentColor {
    if (_settings == null) {
      return GothicTheme.accentColors[0];
    }
    return GothicTheme.accentColors[_settings!.accentColorIndex];
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _firebaseService.initialize();
      
      // Listen to auth state
      _firebaseService.authStateChanges.listen((user) async {
        _currentUserId = user?.uid;
        if (_currentUserId != null && _pairId != null) {
          await _loadOrCreateSettings();
        }
        notifyListeners();
      });

      // Check if already signed in
      _currentUserId = _firebaseService.currentUser?.uid;
      if (_currentUserId != null) {
        // Use user ID as pair ID for now (simplified pairing)
        // In a real app, you'd have a pairing code or invite system
        _pairId = _currentUserId;
        await _loadOrCreateSettings();
      }
    } catch (e) {
      debugPrint('AppProvider initialization error: $e');
      // Continue anyway
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> signIn() async {
    await _firebaseService.signInAnonymously();
  }

  Future<void> setPairId(String pairId) async {
    _pairId = pairId;
    if (_currentUserId != null) {
      await _loadOrCreateSettings();
    }
    notifyListeners();
  }

  Future<void> _loadOrCreateSettings() async {
    if (_pairId == null || _currentUserId == null) return;
    
    _firebaseService.watchSettings(_pairId!).listen((settings) async {
      if (settings == null) {
        // Create default settings if they don't exist
        final defaultSettings = SettingsModel(
          pairId: _pairId!,
          user1Id: _currentUserId!,
          user1Nickname: 'Dracula',
          user2Nickname: 'Mina',
          meetingDate: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        await _firebaseService.saveSettings(defaultSettings);
        _settings = defaultSettings;
      } else {
        // Update user2Id if current user is not user1 and user2 is empty
        if (settings.user1Id != _currentUserId && settings.user2Id.isEmpty) {
          final updatedSettings = settings.copyWith(user2Id: _currentUserId);
          await _firebaseService.saveSettings(updatedSettings);
          _settings = updatedSettings;
        } else {
          _settings = settings;
        }
      }
      notifyListeners();
    });
  }

  Future<void> updateSettings(SettingsModel newSettings) async {
    if (_pairId == null) return;
    
    final updated = newSettings.copyWith(
      pairId: _pairId!,
      lastUpdated: DateTime.now(),
    );
    
    await _firebaseService.saveSettings(updated);
    _settings = updated;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    _currentUserId = null;
    _pairId = null;
    _settings = null;
    notifyListeners();
  }
}

