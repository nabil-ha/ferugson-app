import '../models/models.dart';
import 'firebase_service.dart';
import 'ai_service.dart';

class SelfAssessmentService {
  final FirebaseService _firebaseService;
  final AIService _aiService;

  SelfAssessmentService(this._firebaseService)
      : _aiService = AIService(_firebaseService);

  // Collection reference
  final String _collectionPath = 'selfAssessments';

  // Create a new self-assessment
  Future<SelfAssessment> createSelfAssessment({
    required String playerId,
    required String sessionId,
    required int speed,
    required int stamina,
    required int strength,
    String? comments,
  }) async {
    try {
      // Calculate fatigue percentage using AI service
      final fatiguePercentage = await _aiService.calculateFatiguePercentage(
        speed,
        stamina,
        strength,
      );

      final selfAssessment = SelfAssessment(
        playerId: playerId,
        sessionId: sessionId,
        speed: speed,
        stamina: stamina,
        strength: strength,
        fatiguePercentage: fatiguePercentage,
        comments: comments,
      );

      // Save to Firestore
      await _firebaseService.firestore
          .collection(_collectionPath)
          .doc(selfAssessment.id)
          .set(selfAssessment.toJson());

      // Also update the player's fatigue status in their profile
      await _updatePlayerFatigueStatus(playerId, fatiguePercentage);

      return selfAssessment;
    } catch (e) {
      throw Exception('Failed to create self-assessment: $e');
    }
  }

  // Update player's fatigue status in their profile
  Future<void> _updatePlayerFatigueStatus(
      String playerId, int fatiguePercentage) async {
    try {
      // Convert percentage to a 0-3 scale
      // 0-25% = 0 (No fatigue)
      // 26-50% = 1 (Low fatigue)
      // 51-75% = 2 (Moderate fatigue)
      // 76-100% = 3 (High fatigue)
      int fatigueStatus = 0;
      if (fatiguePercentage > 25) fatigueStatus = 1;
      if (fatiguePercentage > 50) fatigueStatus = 2;
      if (fatiguePercentage > 75) fatigueStatus = 3;

      await _firebaseService.usersCollection.doc(playerId).update({
        'fatigueStatus': fatigueStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating player fatigue status: $e');
      // Continue anyway, the main assessment is saved
    }
  }

  // Get a self-assessment by ID
  Future<SelfAssessment?> getSelfAssessmentById(String id) async {
    try {
      final doc = await _firebaseService.firestore
          .collection(_collectionPath)
          .doc(id)
          .get();

      if (!doc.exists) return null;

      return SelfAssessment.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get self-assessment: $e');
    }
  }

  // Get all self-assessments for a player
  Future<List<SelfAssessment>> getSelfAssessmentsForPlayer(
      String playerId) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_collectionPath)
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              SelfAssessment.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get player self-assessments: $e');
    }
  }

  // Get a self-assessment for a specific session and player
  Future<SelfAssessment?> getSelfAssessmentForSession(
      String playerId, String sessionId) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_collectionPath)
          .where('playerId', isEqualTo: playerId)
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return SelfAssessment.fromJson(
          snapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get session self-assessment: $e');
    }
  }

  // Update an existing self-assessment
  Future<void> updateSelfAssessment(SelfAssessment assessment) async {
    try {
      await _firebaseService.firestore
          .collection(_collectionPath)
          .doc(assessment.id)
          .update(assessment.toJson());
    } catch (e) {
      throw Exception('Failed to update self-assessment: $e');
    }
  }

  // Delete a self-assessment
  Future<void> deleteSelfAssessment(String id) async {
    try {
      await _firebaseService.firestore
          .collection(_collectionPath)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete self-assessment: $e');
    }
  }
}
