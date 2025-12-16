import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      
      // Load saved pair ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedPairId = prefs.getString(_pairIdKey);
      if (savedPairId != null && savedPairId.isNotEmpty) {
        debugPrint('Loaded saved pair ID: $savedPairId');
        _pairId = savedPairId;
      }
      
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
      if (_currentUserId != null && _pairId != null) {
        // Load settings if we have both user ID and pair ID
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
    
    // Save pair ID to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pairIdKey, pairId);
      debugPrint('Saved pair ID to SharedPreferences: $pairId');
    } catch (e) {
      debugPrint('Error saving pair ID to SharedPreferences: $e');
    }
    
    if (_currentUserId != null) {
      // Load settings immediately (synchronous fetch)
      try {
        debugPrint('Loading settings for pairId: $pairId');
        final settings = await _firebaseService.getSettings(pairId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Timeout loading settings');
            return null;
          },
        );
        if (settings != null) {
          debugPrint('Settings loaded successfully');
          _settings = settings;
          notifyListeners();
        } else {
          debugPrint('Settings not found for pairId: $pairId');
        }
      } catch (e, stackTrace) {
        debugPrint('Error loading settings: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Set up stream listener for future updates
      try {
        await _loadOrCreateSettings();
      } catch (e, stackTrace) {
        debugPrint('Error setting up settings stream: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    notifyListeners();
  }
  
  // Check if user needs to pair
  bool get needsPairing {
    if (_settings == null || _currentUserId == null) return true;
    // Check if current user is in the pair
    return !_settings!.isUserInPair(_currentUserId!);
  }

  Future<void> _loadOrCreateSettings() async {
    if (_pairId == null || _currentUserId == null) return;
    
    // Cancel previous subscription if exists
    await _settingsSubscription?.cancel();
    
    // Set up new subscription
    _settingsSubscription = _firebaseService.watchSettings(_pairId!).listen((settings) {
      try {
        if (settings == null) {
          // Settings don't exist yet - will be created when user selects gender
          _settings = null;
        } else {
          // Check if current user needs to be added to the pair
          final isMale = settings.maleUserId == _currentUserId;
          final isFemale = settings.femaleUserId == _currentUserId;
          
          if (!isMale && !isFemale) {
            // User is not in the pair yet - check if there's a slot
            if (settings.maleUserId.isEmpty) {
              // Male slot is empty - but we don't know user's gender here
              // This will be handled in settings page
            } else if (settings.femaleUserId.isEmpty) {
              // Female slot is empty - but we don't know user's gender here
              // This will be handled in settings page
            }
          }
          
          _settings = settings;
        }
        notifyListeners();
      } catch (e, stackTrace) {
        debugPrint('Error processing settings update: $e');
        debugPrint('Stack trace: $stackTrace');
        // Don't clear settings on error, keep the last known good state
      }
    }, onError: (error) {
      debugPrint('Error watching settings: $error');
      // Don't clear settings on stream error, keep the last known good state
      // _settings = null;
      notifyListeners();
    });
  }
  
  // Find or create pair based on gender
  Future<String> findOrCreatePair(Gender gender) async {
    if (_currentUserId == null) throw Exception('Not signed in');
    
    // Try to find existing pair with opposite gender
    // For simplicity, we'll use a shared pair code
    // In a real app, you might want a pairing code system
    
    // For now, use a fixed pair ID based on a shared code
    // Both users will need to enter the same pair code
    // Let's use the first user's ID as the pair ID for now
    // When second user joins, they'll use the same pair ID
    
    return _currentUserId!; // Simplified - in production, use pairing code
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
    await _settingsSubscription?.cancel();
    _settingsSubscription = null;
    await _firebaseService.signOut();
    
    // Clear saved pair ID from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pairIdKey);
    } catch (e) {
      debugPrint('Error clearing pair ID from SharedPreferences: $e');
    }
    
    _currentUserId = null;
    _pairId = null;
    _settings = null;
    notifyListeners();
  }

  Future<void> saveFcmToken(String token) async {
    if (_pairId != null && _currentUserId != null) {
      await _firebaseService.saveFcmToken(_pairId!, _currentUserId!);
    }
  }
  
  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
