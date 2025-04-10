import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class PerformanceService {
  final FirebaseService _firebaseService;

  PerformanceService(this._firebaseService);

  // Create a new performance evaluation
  Future<String> createPerformance(Performance performance) async {
    try {
      await _firebaseService.performancesCollection
          .doc(performance.id)
          .set(performance.toJson());

      // Update player's performance trends
      final performanceData = {
        'date': performance.createdAt.toIso8601String(),
        'sessionId': performance.sessionId,
        'speedRating': performance.speedRating,
        'staminaRating': performance.staminaRating,
        'accuracyRating': performance.accuracyRating,
        'tacticalRating': performance.tacticalRating,
      };

      await _firebaseService.usersCollection.doc(performance.playerId).update({
        'personalPerformanceTrends': FieldValue.arrayUnion([performanceData])
      });

      return performance.id;
    } catch (e) {
      throw Exception('Failed to create performance evaluation: $e');
    }
  }

  // Get a performance evaluation by ID
  Future<Performance?> getPerformanceById(String performanceId) async {
    try {
      final performanceDoc = await _firebaseService.performancesCollection
          .doc(performanceId)
          .get();
      if (!performanceDoc.exists) return null;

      return Performance.fromJson(
          performanceDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get performance evaluation: $e');
    }
  }

  // Update an existing performance evaluation
  Future<void> updatePerformance(Performance performance) async {
    try {
      await _firebaseService.performancesCollection
          .doc(performance.id)
          .update(performance.toJson());

      // TODO: Update player's performance trends data
    } catch (e) {
      throw Exception('Failed to update performance evaluation: $e');
    }
  }

  // Delete a performance evaluation
  Future<void> deletePerformance(String performanceId) async {
    try {
      final performanceDoc = await _firebaseService.performancesCollection
          .doc(performanceId)
          .get();
      if (!performanceDoc.exists)
        throw Exception('Performance evaluation not found');

      // TODO: Remove from player's performance trends data

      await _firebaseService.performancesCollection.doc(performanceId).delete();
    } catch (e) {
      throw Exception('Failed to delete performance evaluation: $e');
    }
  }

  // Get all performance evaluations for a player
  Future<List<Performance>> getPerformancesForPlayer(String playerId) async {
    try {
      final snapshot = await _firebaseService.performancesCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
              (doc) => Performance.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get performances for player: $e');
    }
  }

  // Get all performance evaluations for a session
  Future<List<Performance>> getPerformancesForSession(String sessionId) async {
    try {
      final snapshot = await _firebaseService.performancesCollection
          .where('sessionId', isEqualTo: sessionId)
          .get();

      return snapshot.docs
          .map(
              (doc) => Performance.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get performances for session: $e');
    }
  }
}
