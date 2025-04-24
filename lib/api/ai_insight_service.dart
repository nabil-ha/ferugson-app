import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';
import 'package:uuid/uuid.dart';

class AIInsightService {
  final FirebaseService _firebaseService;

  AIInsightService(this._firebaseService);

  // Create a new AI insight
  Future<String> createAIInsight(AIInsight insight) async {
    try {
      await _firebaseService.aiInsightsCollection
          .doc(insight.id)
          .set(insight.toJson());

      return insight.id;
    } catch (e) {
      throw Exception('Failed to create AI insight: $e');
    }
  }

  // Get an AI insight by ID
  Future<AIInsight?> getAIInsightById(String insightId) async {
    try {
      final insightDoc =
          await _firebaseService.aiInsightsCollection.doc(insightId).get();
      if (!insightDoc.exists) return null;

      return AIInsight.fromJson(insightDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get AI insight: $e');
    }
  }

  // Update an existing AI insight
  Future<void> updateAIInsight(AIInsight insight) async {
    try {
      await _firebaseService.aiInsightsCollection
          .doc(insight.id)
          .update(insight.toJson());
    } catch (e) {
      throw Exception('Failed to update AI insight: $e');
    }
  }

  // Delete an AI insight
  Future<void> deleteAIInsight(String insightId) async {
    try {
      final insightDoc =
          await _firebaseService.aiInsightsCollection.doc(insightId).get();
      if (!insightDoc.exists) throw Exception('AI insight not found');

      await _firebaseService.aiInsightsCollection.doc(insightId).delete();
    } catch (e) {
      throw Exception('Failed to delete AI insight: $e');
    }
  }

  // Get all AI insights for a player
  Future<List<AIInsight>> getAIInsightsForPlayer(String playerId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firebaseService.aiInsightsCollection
          .where('playerId', isEqualTo: playerId)
          .where('expirationDate',
              isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('expirationDate')
          .get();

      return snapshot.docs
          .map((doc) => AIInsight.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get AI insights for player: $e');
    }
  }

  // Get all team-wide AI insights (where playerId is null)
  Future<List<AIInsight>> getTeamInsights() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firebaseService.aiInsightsCollection
          .where('playerId', isNull: true)
          .where('expirationDate',
              isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('expirationDate')
          .get();

      return snapshot.docs
          .map((doc) => AIInsight.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get team insights: $e');
    }
  }

  // Get all injury risk alerts (for coaches)
  Future<List<AIInsight>> getInjuryRiskAlerts() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firebaseService.aiInsightsCollection
          .where('type', isEqualTo: 'injuryRisk')
          .where('expirationDate',
              isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('expirationDate')
          .get();

      return snapshot.docs
          .map((doc) => AIInsight.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get injury risk alerts: $e');
    }
  }

  // Mark an insight as acknowledged
  Future<void> acknowledgeInsight(String insightId) async {
    try {
      await _firebaseService.aiInsightsCollection
          .doc(insightId)
          .update({'isAcknowledged': true});
    } catch (e) {
      throw Exception('Failed to acknowledge insight: $e');
    }
  }

  // Get all AI insights
  Future<List<AIInsight>> getAllInsights() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firebaseService.aiInsightsCollection
          .where('expirationDate',
              isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('expirationDate')
          .get();

      return snapshot.docs
          .map((doc) => AIInsight.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all insights: $e');
    }
  }

  // Save an insight to Firestore
  Future<void> saveInsight(AIInsight insight) async {
    try {
      await _firebaseService.aiInsightsCollection
          .doc(insight.id)
          .set(insight.toJson());
    } catch (e) {
      throw Exception('Failed to save insight: $e');
    }
  }
}
