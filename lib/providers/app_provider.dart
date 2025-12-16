import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Required for getToken
import '../models/settings_model.dart';
import '../services/firebase_service.dart';
import '../theme/gothic_theme.dart';

class AppProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  static const String _pairIdKey = 'saved_pair_id';

  SettingsModel? _settings;
  String? _pairId;
  String? _currentUserId;
  bool _isInitialized = false;
  StreamSubscription<SettingsModel?>? _settingsSubscription;

  // --- START: CORRECTED TOKEN LOGIC ---
  bool _fcmTokenSavePending = false;
  String? _pendingFcmToken;
  // --- END: CORRECTED TOKEN LOGIC ---

  SettingsModel? get settings => _settings;
  String? get pairId => _pairId;
  String? get currentUserId => _currentUserId;
  bool get isInitialized => _isInitialized;

  ThemeData get theme {
    if (_settings == null) {
      return GothicTheme.getDarkTheme(0);
    }
    return _settings!.isDarkMode ? GothicTheme.getDarkTheme(_settings!.accentColorIndex) : GothicTheme.getLightTheme(_settings!.accentColorIndex);
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

      final prefs = await SharedPreferences.getInstance();
      final savedPairId = prefs.getString(_pairIdKey);
      if (savedPairId != null && savedPairId.isNotEmpty) {
        _pairId = savedPairId;
      }

      _firebaseService.authStateChanges.listen((user) async {
        _currentUserId = user?.uid;
        if (_currentUserId != null && _pairId != null) {
          await _loadOrCreateSettings();
        }
        notifyListeners();
      });

      _currentUserId = _firebaseService.currentUser?.uid;
      if (_currentUserId != null && _pairId != null) {
        await _loadOrCreateSettings();
      }
    } catch (e) {
      debugPrint('AppProvider initialization error: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> signIn() async {
    await _firebaseService.signInAnonymously();
  }

  Future<void> setPairId(String pairId) async {
    _pairId = pairId;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pairIdKey, pairId);
    } catch (e) {
      debugPrint('Error saving pair ID to SharedPreferences: $e');
    }

    if (_currentUserId != null) {
      await _loadOrCreateSettings();
    }
    notifyListeners();
  }

  bool get needsPairing {
    if (_settings == null || _currentUserId == null) return true;
    return !_settings!.isUserInPair(_currentUserId!);
  }

  Future<void> _loadOrCreateSettings() async {
    if (_pairId == null || _currentUserId == null) return;

    await _settingsSubscription?.cancel();

    _settingsSubscription = _firebaseService.watchSettings(_pairId!).listen((settings) {
      _settings = settings;
      // After settings are loaded or updated, try to save any pending FCM token.
      _trySaveFcmToken();
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error watching settings: $error');
      notifyListeners();
    });
  }

  // --- START: REWRITTEN FCM TOKEN METHODS ---

  /// Schedules the FCM token to be saved.
  /// It stores the token and attempts to save it immediately.
  /// If conditions aren't met (e.g., settings not loaded), it will retry later.
  void scheduleFcmTokenSave(String? token) {
    if (token == null || token.isEmpty) {
      debugPrint('AppProvider: scheduleFcmTokenSave called with null or empty token.');
      return;
    }
    debugPrint('AppProvider: Scheduling token for save: $token');
    _pendingFcmToken = token;
    _fcmTokenSavePending = true;
    _trySaveFcmToken(); // Attempt to save immediately.
  }

  /// Private method that checks conditions and performs the save.
  Future<void> _trySaveFcmToken() async {
    // Only proceed if a save is pending and all necessary data is available.
    if (_fcmTokenSavePending && _settings != null && _currentUserId != null && _pendingFcmToken != null) {
      debugPrint('AppProvider: Conditions met. Attempting to save FCM token.');
      try {
        // IMPORTANT: We now pass the stored token to the service.
        await _firebaseService.saveFcmToken(_settings!.pairId, _currentUserId!, _pendingFcmToken!);

        // Reset flags after a successful attempt.
        _fcmTokenSavePending = false;
        _pendingFcmToken = null;
        debugPrint('AppProvider: FCM token save operation completed successfully.');
      } catch (e) {
        debugPrint('AppProvider: Error during scheduled FCM token save: $e');
      }
    } else {
      debugPrint('AppProvider: Conditions for saving FCM token not met. Will retry later.');
    }
  }

  // --- END: REWRITTEN FCM TOKEN METHODS ---

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
    await _settingsSubscription?.cancel();
    _settingsSubscription = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pairIdKey);

    await _firebaseService.signOut();

    _currentUserId = null;
    _pairId = null;
    _settings = null;
    _fcmTokenSavePending = false;
    _pendingFcmToken = null;
    notifyListeners();
  }

  // The old method is no longer needed.

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
