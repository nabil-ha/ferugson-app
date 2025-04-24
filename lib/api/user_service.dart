import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class UserService {
  final FirebaseService _firebaseService;

  UserService(this._firebaseService);

  // Get current user data
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseService.currentUser;
      if (firebaseUser == null) return null;

      final userDoc =
          await _firebaseService.usersCollection.doc(firebaseUser.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      final roleStr = userData['role'] as String;

      if (roleStr == 'coach') {
        return Coach.fromJson(userData);
      } else if (roleStr == 'player') {
        return Player.fromJson(userData);
      } else if (roleStr == 'owner') {
        return Owner.fromJson(userData);
      }
      return User.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  // Get a user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final userDoc = await _firebaseService.usersCollection.doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      final roleStr = userData['role'] as String;

      if (roleStr == 'coach') {
        return Coach.fromJson(userData);
      } else if (roleStr == 'player') {
        return Player.fromJson(userData);
      } else if (roleStr == 'owner') {
        return Owner.fromJson(userData);
      }
      return User.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to get user by ID: $e');
    }
  }

  // Create a new user
  Future<void> createUser(User user) async {
    try {
      await _firebaseService.usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Update an existing user
  Future<void> updateUser(User user) async {
    try {
      await _firebaseService.usersCollection.doc(user.id).update(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Get all coaches
  Future<List<Coach>> getAllCoaches() async {
    try {
      final snapshot = await _firebaseService.usersCollection
          .where('role', isEqualTo: 'coach')
          .get();

      return snapshot.docs
          .map((doc) => Coach.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all coaches: $e');
    }
  }

  // Get all players
  Future<List<Player>> getAllPlayers() async {
    try {
      final snapshot = await _firebaseService.usersCollection
          .where('role', isEqualTo: 'player')
          .get();

      return snapshot.docs
          .map((doc) => Player.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all players: $e');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileName = '${const Uuid().v4()}.jpg';
      final Reference storageRef = _firebaseService.storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user's photo URL
      await _firebaseService.usersCollection.doc(userId).update({
        'photoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Create a new player
  Future<String> createPlayer(
    String name,
    String email,
    String password,
    PlayerPosition position, {
    DateTime? birthdate,
    int? height,
    int? weight,
    bool hasPreviousInjuries = false,
  }) async {
    try {
      // Create Firebase auth user first
      final userCredential =
          await _firebaseService.createUserWithEmailAndPassword(
        email,
        password,
      );

      final userId = userCredential.user!.uid;
      final now = DateTime.now();

      // Create Player in Firestore with physical attributes
      final player = Player(
        id: userId,
        name: name,
        email: email,
        position: position,
        createdAt: now,
        updatedAt: now,
        birthdate: birthdate,
        height: height,
        weight: weight,
        hasPreviousInjuries: hasPreviousInjuries,
      );

      await _firebaseService.usersCollection.doc(userId).set(player.toJson());

      return userId;
    } catch (e) {
      throw Exception('Failed to create player: $e');
    }
  }
}
