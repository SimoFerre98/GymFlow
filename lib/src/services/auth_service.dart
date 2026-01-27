import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'gymflow',
  );

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow; // Handle specific errors in UI
    }
  }

  // Register with email, password, and display name
  Future<User?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Create Auth User
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user != null) {
        // 2. Generate Friend Code (6 uppercase chars)
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        final rnd = Random();
        String friendCode = String.fromCharCodes(
          Iterable.generate(
            6,
            (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
          ),
        );

        // 3. Create User Profile in Firestore
        final newUserProfile = UserProfile(
          id: user.uid,
          email: email,
          displayName: displayName,
          friendCode: friendCode,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUserProfile.toMap());

        // 4. Update Auth display name
        await user.updateDisplayName(displayName);
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get User Profile Data
  Future<UserProfile?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Get User Profile Stream
  Stream<UserProfile?> getUserProfileStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .set(profile.toMap(), SetOptions(merge: true));

      // Also update auth display name just in case
      await currentUser?.updateDisplayName(profile.displayName);
      if (profile.photoUrl != null) {
        await currentUser?.updatePhotoURL(profile.photoUrl);
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}
