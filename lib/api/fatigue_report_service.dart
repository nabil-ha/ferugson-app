import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class FatigueReportService {
  final FirebaseService _firebaseService;

  FatigueReportService(this._firebaseService);

  // Create a new fatigue report
  Future<String> createFatigueReport(FatigueReport report) async {
    try {
      await _firebaseService.fatigueReportsCollection
          .doc(report.id)
          .set(report.toJson());

      // Update player's fatigue status
      await _firebaseService.usersCollection.doc(report.playerId).update(
          {'fatigueStatus': _getFatigueStatusValue(report.fatigueLevel)});

      return report.id;
    } catch (e) {
      throw Exception('Failed to create fatigue report: $e');
    }
  }

  // Get a fatigue report by ID
  Future<FatigueReport?> getFatigueReportById(String reportId) async {
    try {
      final reportDoc =
          await _firebaseService.fatigueReportsCollection.doc(reportId).get();
      if (!reportDoc.exists) return null;

      return FatigueReport.fromJson(reportDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get fatigue report: $e');
    }
  }

  // Update an existing fatigue report
  Future<void> updateFatigueReport(FatigueReport report) async {
    try {
      await _firebaseService.fatigueReportsCollection
          .doc(report.id)
          .update(report.toJson());

      // Update player's fatigue status
      await _firebaseService.usersCollection.doc(report.playerId).update(
          {'fatigueStatus': _getFatigueStatusValue(report.fatigueLevel)});
    } catch (e) {
      throw Exception('Failed to update fatigue report: $e');
    }
  }

  // Delete a fatigue report
  Future<void> deleteFatigueReport(String reportId) async {
    try {
      final reportDoc =
          await _firebaseService.fatigueReportsCollection.doc(reportId).get();
      if (!reportDoc.exists) throw Exception('Fatigue report not found');

      // TODO: Update player's fatigue status if this is the latest report

      await _firebaseService.fatigueReportsCollection.doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete fatigue report: $e');
    }
  }

  // Get all fatigue reports for a player
  Future<List<FatigueReport>> getFatigueReportsForPlayer(
      String playerId) async {
    try {
      final snapshot = await _firebaseService.fatigueReportsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              FatigueReport.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get fatigue reports for player: $e');
    }
  }

  // Get all fatigue reports for a session
  Future<List<FatigueReport>> getFatigueReportsForSession(
      String sessionId) async {
    try {
      final snapshot = await _firebaseService.fatigueReportsCollection
          .where('sessionId', isEqualTo: sessionId)
          .get();

      return snapshot.docs
          .map((doc) =>
              FatigueReport.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get fatigue reports for session: $e');
    }
  }

  // Get latest fatigue report for a player
  Future<FatigueReport?> getLatestFatigueReportForPlayer(
      String playerId) async {
    try {
      final snapshot = await _firebaseService.fatigueReportsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return FatigueReport.fromJson(
          snapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get latest fatigue report for player: $e');
    }
  }

  // Helper method to convert enum to numeric value
  int _getFatigueStatusValue(FatigueLevel level) {
    switch (level) {
      case FatigueLevel.none:
        return 0;
      case FatigueLevel.mild:
        return 3;
      case FatigueLevel.moderate:
        return 7;
      case FatigueLevel.severe:
        return 10;
      default:
        return 0;
    }
  }
}
