import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'firebase_service.dart';
import 'user_service.dart';

class AIService {
  final FirebaseService _firebaseService;

  AIService(this._firebaseService);

  // Predict injury risk for a player
  // Returns risk level: 0 (low), 1 (medium), 2 (high)
  Future<int> predictInjuryRisk(Player player, Session session) async {
    try {
      // Calculate BMI - skip API call if BMI is missing
      final bmi = player.bmi;
      if (bmi == null) {
        return 0; // Default to low risk
      }

      // Convert hasPreviousInjuries bool to int (1 or 0)
      final previousInjuriesValue = player.hasPreviousInjuries ? 1 : 0;

      // For API call, API would accept intensity as 0-10 value
      final intensityValue = session.intensity;

      // Skip getting fatigue report for now to improve speed
      const int defaultFatigueLevel = 5; // Default to medium fatigue

      // API call to injury prediction model with timeout
      try {
        final response = await http
            .post(
              Uri.parse('https://fatigue-injury.onrender.com/predict-injury'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'Previous_Injuries': previousInjuriesValue,
                'Training_Intensity': intensityValue,
                'BMI': bmi,
                'Fatigue_Level': defaultFatigueLevel,
              }),
            )
            .timeout(const Duration(
                seconds: 5)); // Add timeout to prevent long waits

        return jsonDecode(response.body)['class'];
      } catch (e) {
        print('Error calling injury prediction API for ${player.name}: $e');
        // Use our own risk algorithm as fallback if API fails
        return _calculateLocalRiskScore(player, session.intensity);
      }
    } catch (e) {
      print('Error predicting injury risk: $e');
      return 0; // Default to low risk if there's an error
    }
  }

  // Local risk calculation as fallback when API fails
  int _calculateLocalRiskScore(Player player, int intensity) {
    // Simple algorithm: previous injuries + high intensity = higher risk
    int riskScore = 0;

    // Previous injuries are a major factor
    if (player.hasPreviousInjuries) {
      riskScore += 1;
    }

    // High intensity increases risk
    if (intensity >= 8) {
      riskScore += 1;
    }

    // BMI outside normal range is a risk factor
    final bmi = player.bmi;
    if (bmi != null && (bmi < 18.5 || bmi > 25)) {
      riskScore += 1;
    }

    // Cap at 2 (our risk levels are 0, 1, 2)
    return riskScore > 2 ? 2 : riskScore;
  }

  // Helper method to get the latest fatigue report for a player
  Future<FatigueReport?> _getLatestFatigueReport(String playerId) async {
    try {
      final snapshot = await _firebaseService.fatigueReportsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return FatigueReport.fromJson(data);
    } catch (e) {
      print('Error getting latest fatigue report: $e');
      return null;
    }
  }

  // Helper method to convert player position to numerical value for the model
  int _convertPositionToValue(PlayerPosition? position) {
    if (position == null) return 0;

    switch (position) {
      case PlayerPosition.goalkeeper:
        return 0;
      case PlayerPosition.defender:
        return 1;
      case PlayerPosition.midfielder:
        return 2;
      case PlayerPosition.forward:
        return 3;
      default:
        return 0;
    }
  }

  // Calculate player fatigue percentage based on player-reported metrics
  Future<int> calculateFatiguePercentage(
      int speed, int stamina, int strength) async {
    try {
      // API call to fatigue prediction model
      try {
        final response = await http.post(
          Uri.parse('https://fatigue-injury.onrender.com/predict-fatigue'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'Speed': speed,
            'Stamina': stamina,
            'Strength': strength,
          }),
        );
        print(response.body);
        final fatigueDouble = jsonDecode(response.body)['fatigue_percent'];

        // Convert double to int
        final fatigue = fatigueDouble is double
            ? fatigueDouble.round()
            : int.tryParse(fatigueDouble.toString()) ?? 50;

        // Ensure value is between 0 and 100
        if (fatigue < 0) return 0;
        if (fatigue > 100) return 100;

        return fatigue;
      } catch (e) {
        print('Error calling fatigue prediction API: $e');
        return 50; // Default to 50% on API failure
      }
    } catch (e) {
      print('Error calculating fatigue percentage: $e');
      return 50; // Default to 50% if there's an error
    }
  }

  // Process injury predictions for all players in a session
  Future<Map<String, int>> processSessionInjuryRisks(Session session) async {
    final Map<String, int> results = {};
    final userService = UserService(_firebaseService);

    // Get all players in a single query rather than one-by-one
    final List<String> playerIds = session.invitedPlayersIds;
    final players = <Player>[];

    for (final playerId in playerIds) {
      try {
        final player = await userService.getUserById(playerId);
        if (player != null && player is Player) {
          players.add(player);
        }
      } catch (e) {
        print('Error fetching player $playerId: $e');
      }
    }

    // Fast-track: For small player count (under 5), process sequentially
    if (players.length < 5) {
      for (final player in players) {
        try {
          final riskLevel = await predictInjuryRisk(player, session);
          results[player.id] = riskLevel;
        } catch (e) {
          print('Error processing risk for player ${player.id}: $e');
        }
      }
      return results;
    }

    // Batch process: For larger player groups, use multiple concurrent API calls
    // Use a semaphore to limit concurrent API calls to 3 at a time
    final futures = <Future<void>>[];

    for (final player in players) {
      final future = () async {
        try {
          final riskLevel = await predictInjuryRisk(player, session);
          results[player.id] = riskLevel;
        } catch (e) {
          print('Error processing risk for player ${player.id}: $e');
        }
      }();
      futures.add(future);

      // If we've queued 3 futures, wait for them to complete
      if (futures.length >= 3) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    // Wait for any remaining futures
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    return results;
  }

  // Store injury insights for high-risk players and return the created insights
  Future<List<AIInsight>> storeInjuryInsights(
      Session session, Map<String, int> riskLevels) async {
    final now = DateTime.now();
    final expirationDate = now.add(const Duration(days: 7)); // Expire in a week
    final List<AIInsight> createdInsights = [];

    for (final entry in riskLevels.entries) {
      if (entry.value >= 1) {
        // Store medium and high risks
        final playerId = entry.key;
        final riskLevel = entry.value;

        // Create risk level text
        String riskText = 'Low';
        if (riskLevel == 1) riskText = 'Medium';
        if (riskLevel == 2) riskText = 'High';

        final insight = AIInsight(
          playerId: playerId,
          type: InsightType.injuryRisk,
          title: '$riskText Injury Risk Detected',
          description:
              'Based on analysis of physical attributes and training intensity, '
              'this player has a $riskText risk of injury in the upcoming session.',
          riskLevel: riskLevel == 0
              ? RiskLevel.low
              : (riskLevel == 1 ? RiskLevel.moderate : RiskLevel.high),
          supportingData: {
            'sessionId': session.id,
            'riskScore': riskLevel,
            'sessionDate': session.dateTime.toIso8601String(),
          },
          expirationDate: expirationDate,
        );

        await _firebaseService.aiInsightsCollection
            .doc(insight.id)
            .set(insight.toJson());

        createdInsights.add(insight);
      }
    }

    return createdInsights;
  }

  // Get player names by IDs for display purposes
  Future<Map<String, String>> getPlayerNamesByIds(
      List<String> playerIds) async {
    final Map<String, String> playerNames = {};
    final userService = UserService(_firebaseService);

    for (final playerId in playerIds) {
      try {
        final player = await userService.getUserById(playerId);
        if (player != null) {
          playerNames[playerId] = player.name;
        }
      } catch (e) {
        print('Error getting name for player $playerId: $e');
      }
    }

    return playerNames;
  }
}
