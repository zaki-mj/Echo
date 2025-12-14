import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/mood_model.dart';
import '../models/whisper_model.dart';
import '../models/sealed_letter_model.dart';
import '../models/settings_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Initialize Firestore with offline persistence
  Future<void> initialize() async {
    // Note: Settings API has changed in newer Firestore versions
    // Offline persistence is enabled by default on mobile platforms
    // For web, you may need to configure differently
  }

  // Auth
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('Firebase Auth error: $e');
      // In demo mode, create a mock user ID
      throw Exception('Firebase not configured. Please set up Firebase to use this app.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Settings
  Future<void> saveSettings(SettingsModel settings) async {
    await _firestore.collection('pairs').doc(settings.pairId).set(settings.toMap(), SetOptions(merge: true));
  }

  Stream<SettingsModel?> watchSettings(String pairId) {
    return _firestore.collection('pairs').doc(pairId).snapshots().map((snapshot) => snapshot.exists ? SettingsModel.fromMap(snapshot.data()!) : null);
  }

  // Moods
  Future<void> saveMood(MoodModel mood) async {
    await _firestore.collection('moods').add(mood.toMap());
  }

  Stream<List<MoodModel>> watchMoods(String userId) {
    return _firestore.collection('moods').where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).limit(1).snapshots().map((snapshot) => snapshot.docs.map((doc) => MoodModel.fromMap(doc.data())).toList());
  }

  Stream<List<MoodModel>> watchMoodsForDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _firestore.collection('moods').where('timestamp', isGreaterThanOrEqualTo: start, isLessThanOrEqualTo: end).orderBy('timestamp', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => MoodModel.fromMap(doc.data())).toList());
  }

  // Whispers
  Future<String> sendWhisper(WhisperModel whisper) async {
    final docRef = await _firestore.collection('whispers').add(whisper.toMap());
    return docRef.id;
  }

  Stream<List<WhisperModel>> watchWhispers(String userId1, String userId2) {
    if (userId2.isEmpty) {
      // If no partner yet, return empty stream
      return Stream.value([]);
    }

    // Query messages where current user is sender or receiver, then filter for partner
    return _firestore.collection('whispers').where('senderId', whereIn: [userId1, userId2]).orderBy('timestamp', descending: true).snapshots().map((snapshot) {
          final allDocs = <WhisperModel>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final senderId = data['senderId'] as String?;
            final receiverId = data['receiverId'] as String?;

            // Only include messages between these two users
            if ((senderId == userId1 && receiverId == userId2) || (senderId == userId2 && receiverId == userId1)) {
              allDocs.add(WhisperModel.fromMap({
                ...data,
                'id': doc.id,
              }));
            }
          }
          return allDocs;
        });
  }

  Future<void> markWhisperDelivered(String whisperId) async {
    await _firestore.collection('whispers').doc(whisperId).update({'isDelivered': true});
  }

  Future<void> markWhisperRead(String whisperId) async {
    await _firestore.collection('whispers').doc(whisperId).update({'isRead': true});
  }

  // Sealed Letters
  Future<String> createSealedLetter(SealedLetterModel letter) async {
    final docRef = await _firestore.collection('sealedLetters').add(letter.toMap());
    return docRef.id;
  }

  Stream<List<SealedLetterModel>> watchSealedLetters(
    String userId1,
    String userId2,
  ) {
    if (userId2.isEmpty) {
      return Stream.value([]);
    }

    // Query letters where either user is sender, then filter for partner
    return _firestore.collection('sealedLetters').where('senderId', whereIn: [userId1, userId2]).orderBy('revealAt', descending: false).snapshots().map((snapshot) {
          final allDocs = <SealedLetterModel>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final senderId = data['senderId'] as String?;
            final receiverId = data['receiverId'] as String?;

            // Only include letters between these two users
            if ((senderId == userId1 && receiverId == userId2) || (senderId == userId2 && receiverId == userId1)) {
              allDocs.add(SealedLetterModel.fromMap({
                ...data,
                'id': doc.id,
              }));
            }
          }
          return allDocs;
        });
  }

  Future<void> markLetterRevealed(String letterId) async {
    await _firestore.collection('sealedLetters').doc(letterId).update({'isRevealed': true});
  }

  // Storage for voice/photo
  Future<String> uploadFile(String path, List<int> data) async {
    final ref = _storage.ref().child(path);
    await ref.putData(Uint8List.fromList(data));
    return await ref.getDownloadURL();
  }

  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }
}
