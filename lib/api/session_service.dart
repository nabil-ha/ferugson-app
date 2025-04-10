import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class SessionService {
  final FirebaseService _firebaseService;

  SessionService(this._firebaseService);

  // Create a new session
  Future<String> createSession(Session session) async {
    try {
      await _firebaseService.sessionsCollection
          .doc(session.id)
          .set(session.toJson());

      // Update session counts for coach
      await _firebaseService.usersCollection
          .doc(session.coachId)
          .update({'sessionCount': FieldValue.increment(1)});

      // Update upcoming sessions for players
      for (String playerId in session.invitedPlayersIds) {
        await _firebaseService.usersCollection.doc(playerId).update({
          'upcomingSessions': FieldValue.arrayUnion([session.id])
        });
      }

      return session.id;
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  // Get a session by ID
  Future<Session?> getSessionById(String sessionId) async {
    try {
      final sessionDoc =
          await _firebaseService.sessionsCollection.doc(sessionId).get();
      if (!sessionDoc.exists) return null;

      return Session.fromJson(sessionDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  // Update an existing session
  Future<void> updateSession(Session session) async {
    try {
      await _firebaseService.sessionsCollection
          .doc(session.id)
          .update(session.toJson());
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  // Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      final sessionDoc =
          await _firebaseService.sessionsCollection.doc(sessionId).get();
      if (!sessionDoc.exists) throw Exception('Session not found');

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final session = Session.fromJson(sessionData);

      // Remove from coach's sessions count
      await _firebaseService.usersCollection
          .doc(session.coachId)
          .update({'sessionCount': FieldValue.increment(-1)});

      // Remove from players' upcoming sessions
      for (String playerId in session.invitedPlayersIds) {
        await _firebaseService.usersCollection.doc(playerId).update({
          'upcomingSessions': FieldValue.arrayRemove([sessionId])
        });
      }

      // Delete related performances and fatigue reports
      final performancesSnapshot = await _firebaseService.performancesCollection
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (var doc in performancesSnapshot.docs) {
        await doc.reference.delete();
      }

      final fatigueReportsSnapshot = await _firebaseService
          .fatigueReportsCollection
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (var doc in fatigueReportsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Finally delete the session
      await _firebaseService.sessionsCollection.doc(sessionId).delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // Get upcoming sessions for a coach
  Future<List<Session>> getUpcomingSessionsForCoach(String coachId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firebaseService.sessionsCollection
          .where('coachId', isEqualTo: coachId)
          .where('dateTime', isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('dateTime')
          .get();

      return snapshot.docs
          .map((doc) => Session.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming sessions for coach: $e');
    }
  }

  // Get upcoming sessions for a player
  Future<List<Session>> getUpcomingSessionsForPlayer(String playerId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firebaseService.sessionsCollection
          .where('invitedPlayersIds', arrayContains: playerId)
          .where('dateTime', isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('dateTime')
          .get();

      return snapshot.docs
          .map((doc) => Session.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming sessions for player: $e');
    }
  }

  // Update player confirmation status
  Future<void> updatePlayerConfirmation(
      String sessionId, String playerId, ConfirmationStatus status) async {
    try {
      await _firebaseService.sessionsCollection.doc(sessionId).update(
          {'confirmationStatus.$playerId': status.toString().split('.').last});
    } catch (e) {
      throw Exception('Failed to update player confirmation: $e');
    }
  }
}
