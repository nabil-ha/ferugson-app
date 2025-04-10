import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'firebase_service.dart';
import 'ai_api_service.dart';
import 'package:uuid/uuid.dart';

class AIInsightService {
  final FirebaseService _firebaseService;
  final AIApiService _aiApiService;

  AIInsightService(this._firebaseService) : _aiApiService = AIApiService();

  // Create a new AI insight
  Future<String> createAIInsight(AIInsight insight) async {
    try {
      await _firebaseService.aiInsightsCollection
          .doc(insight.id)
          .set(insight.toJson());

      // If this is an injury risk alert for a player, update the coach's injury alerts
      if (insight.type == InsightType.injuryRisk &&
              insight.playerId != null &&
              insight.riskLevel == RiskLevel.high ||
          insight.riskLevel == RiskLevel.critical) {
        // Get the player data to get their name
        final playerDoc =
            await _firebaseService.usersCollection.doc(insight.playerId).get();
        if (playerDoc.exists) {
          final playerData = playerDoc.data() as Map<String, dynamic>;

          // Find all coaches to notify them
          final coachesSnapshot = await _firebaseService.usersCollection
              .where('role', isEqualTo: 'coach')
              .get();

          for (var coachDoc in coachesSnapshot.docs) {
            await _firebaseService.usersCollection.doc(coachDoc.id).update({
              'injuryAlerts': FieldValue.arrayUnion([insight.id]),
              'pendingNotifications': FieldValue.arrayUnion([
                '${playerData['name']} may be at risk of injury. Risk Level: ${insight.riskLevel.toString().split('.').last}'
              ])
            });
          }
        }
      }

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

      final insightData = insightDoc.data() as Map<String, dynamic>;
      final insight = AIInsight.fromJson(insightData);

      // If this was an injury risk alert, update coaches
      if (insight.type == InsightType.injuryRisk && insight.playerId != null) {
        final coachesSnapshot = await _firebaseService.usersCollection
            .where('role', isEqualTo: 'coach')
            .get();

        for (var coachDoc in coachesSnapshot.docs) {
          await _firebaseService.usersCollection.doc(coachDoc.id).update({
            'injuryAlerts': FieldValue.arrayRemove([insightId])
          });
        }
      }

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

  // Generate injury risk insight for a player
  Future<AIInsight?> generateInjuryRiskInsight(Player player,
      {int? previousInjuries}) async {
    try {
      // Call the AI API to predict injury risk
      final isHighRisk = await _aiApiService.predictInjuryRisk(player,
          previousInjuries: previousInjuries);

      // Only create an insight if the risk is high
      if (isHighRisk) {
        final insight = AIInsight(
          playerId: player.id,
          type: InsightType.injuryRisk,
          title: 'Injury Risk Alert for ${player.name}',
          description:
              'Based on our AI analysis, ${player.name} may be at increased risk of injury. '
              'Consider modifying training intensity or giving additional rest days.',
          riskLevel: RiskLevel.high,
          supportingData: {
            'previous_injuries': previousInjuries ?? 0,
            'position': player.position.toString().split('.').last,
          },
          expirationDate: DateTime.now().add(const Duration(days: 7)),
        );

        // Save the insight to Firestore
        final insightId = await createAIInsight(insight);

        // Fetch the created insight
        return await getAIInsightById(insightId);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to generate injury risk insight: $e');
    }
  }

  // Generate fatigue management insight based on performance data
  Future<AIInsight?> generateFatigueInsight(Performance performance) async {
    try {
      // Get player data
      final playerDoc = await _firebaseService.usersCollection
          .doc(performance.playerId)
          .get();

      if (!playerDoc.exists) {
        throw Exception('Player not found');
      }

      final player = Player.fromJson(playerDoc.data() as Map<String, dynamic>);

      // Call the AI API to predict fatigue level
      final fatigueLevel = await _aiApiService.predictFatigueLevel(performance);

      // Only create an insight if fatigue level is significant (above 6)
      if (fatigueLevel > 6) {
        final insight = AIInsight(
          playerId: player.id,
          type: InsightType.fatigueManagement,
          title: 'Fatigue Management Alert for ${player.name}',
          description:
              'Our AI has detected high fatigue levels (${fatigueLevel}/10) for ${player.name}. '
              'Consider reducing training intensity or providing additional recovery time.',
          riskLevel: fatigueLevel >= 8 ? RiskLevel.high : RiskLevel.moderate,
          supportingData: {
            'fatigue_level': fatigueLevel,
            'stamina_rating': performance.staminaRating,
            'speed_rating': performance.speedRating,
            'tactical_rating': performance.tacticalRating,
          },
          expirationDate: DateTime.now().add(const Duration(days: 3)),
        );

        // Save the insight to Firestore
        final insightId = await createAIInsight(insight);

        // Fetch the created insight
        return await getAIInsightById(insightId);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to generate fatigue insight: $e');
    }
  }

  // Generate insights for all players in a team
  Future<List<AIInsight>> generateTeamInsights(List<Player> players) async {
    final insights = <AIInsight>[];

    try {
      for (final player in players) {
        // Generate injury risk insights
        final injuryInsight = await generateInjuryRiskInsight(player);
        if (injuryInsight != null) {
          insights.add(injuryInsight);
        }

        // Get latest performance for fatigue insights
        final performanceSnapshot = await _firebaseService
            .performancesCollection
            .where('playerId', isEqualTo: player.id)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (performanceSnapshot.docs.isNotEmpty) {
          final latestPerformance = Performance.fromJson(
              performanceSnapshot.docs.first.data() as Map<String, dynamic>);

          // Generate fatigue insights
          final fatigueInsight =
              await generateFatigueInsight(latestPerformance);
          if (fatigueInsight != null) {
            insights.add(fatigueInsight);
          }
        }
      }

      return insights;
    } catch (e) {
      throw Exception('Failed to generate team insights: $e');
    }
  }

  // Generate performance improvement insights based on multiple performances
  Future<AIInsight?> generatePerformanceImprovement(String playerId) async {
    try {
      // Get player data
      final playerDoc =
          await _firebaseService.usersCollection.doc(playerId).get();

      if (!playerDoc.exists) {
        return null;
      }

      final player = Player.fromJson(playerDoc.data() as Map<String, dynamic>);

      // Get last 5 performances
      final performancesSnapshot = await _firebaseService.performancesCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (performancesSnapshot.docs.isEmpty) {
        return null;
      }

      final performances = performancesSnapshot.docs
          .map(
              (doc) => Performance.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Analyze performances to find weak areas
      int totalSpeed = 0;
      int totalStamina = 0;
      int totalAccuracy = 0;
      int totalTactical = 0;

      for (final perf in performances) {
        totalSpeed += perf.speedRating;
        totalStamina += perf.staminaRating;
        totalAccuracy += perf.accuracyRating;
        totalTactical += perf.tacticalRating;
      }

      final avgSpeed = totalSpeed / performances.length;
      final avgStamina = totalStamina / performances.length;
      final avgAccuracy = totalAccuracy / performances.length;
      final avgTactical = totalTactical / performances.length;

      // Find the weakest area
      final ratings = [
        {'area': 'speed', 'value': avgSpeed},
        {'area': 'stamina', 'value': avgStamina},
        {'area': 'accuracy', 'value': avgAccuracy},
        {'area': 'tactical', 'value': avgTactical},
      ];

      ratings.sort(
          (a, b) => (a['value'] as double).compareTo(b['value'] as double));
      final weakestArea = ratings[0]['area'] as String;

      // Create improvement insight
      String improvementTitle = '';
      String improvementDesc = '';

      switch (weakestArea) {
        case 'speed':
          improvementTitle = 'Speed Improvement Opportunity';
          improvementDesc =
              'Focus on sprint training and explosive movements to improve speed.';
          break;
        case 'stamina':
          improvementTitle = 'Stamina Enhancement Needed';
          improvementDesc =
              'Increase endurance training with longer workout sessions and cardio drills.';
          break;
        case 'accuracy':
          improvementTitle = 'Accuracy Development Required';
          improvementDesc =
              'Dedicate more practice time to precision drills and technique refinement.';
          break;
        case 'tactical':
          improvementTitle = 'Tactical Understanding Improvement';
          improvementDesc =
              'Schedule additional tactical sessions and video analysis of match scenarios.';
          break;
      }

      final insight = AIInsight(
        playerId: playerId,
        type: InsightType.performanceImprovement,
        title: '$improvementTitle for ${player.name}',
        description:
            'Analysis shows ${player.name} could improve in $weakestArea. $improvementDesc',
        supportingData: {
          'avg_speed': avgSpeed,
          'avg_stamina': avgStamina,
          'avg_accuracy': avgAccuracy,
          'avg_tactical': avgTactical,
          'weakest_area': weakestArea,
        },
        expirationDate: DateTime.now().add(const Duration(days: 14)),
      );

      // Save the insight to Firestore
      final insightId = await createAIInsight(insight);

      // Fetch the created insight
      return await getAIInsightById(insightId);
    } catch (e) {
      throw Exception('Failed to generate performance improvement insight: $e');
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
