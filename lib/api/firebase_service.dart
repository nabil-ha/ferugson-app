import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseStorage _storage;

  FirebaseService()
      : _firestore = FirebaseFirestore.instance,
        _auth = firebase_auth.FirebaseAuth.instance,
        _storage = FirebaseStorage.instance;

  // Firestore getters
  FirebaseFirestore get firestore => _firestore;
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get sessionsCollection =>
      _firestore.collection('sessions');
  CollectionReference get performancesCollection =>
      _firestore.collection('performances');
  CollectionReference get fatigueReportsCollection =>
      _firestore.collection('fatigueReports');
  CollectionReference get aiInsightsCollection =>
      _firestore.collection('aiInsights');

  // Auth getter
  firebase_auth.FirebaseAuth get auth => _auth;

  // Storage getter
  FirebaseStorage get storage => _storage;

  // Current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Error handling helper
  Exception _handleAuthException(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      return Exception(e.message ?? 'Authentication error');
    }
    return Exception('An unknown error occurred');
  }
}
