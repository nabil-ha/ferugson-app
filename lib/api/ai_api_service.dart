import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AIApiService {
  static const String _baseUrl = 'https://fatigue-injury.onrender.com';

  // Predict injury risk for a player
  Future<bool> predictInjuryRisk(Player player, {int? previousInjuries}) async {
    final url = Uri.parse('$_baseUrl/predict_injury');

    // Calculate player's age from birthdate
    int age = 25; // Default fallback
    if (player.birthdate != null) {
      final currentDate = DateTime.now();
      age = currentDate.year - player.birthdate!.year;
      if (currentDate.month < player.birthdate!.month ||
          (currentDate.month == player.birthdate!.month &&
              currentDate.day < player.birthdate!.day)) {
        age--;
      }
    }

    // Get player's physical attributes
    final int height = player.height ?? 180; // Height in cm
    final int weight = player.weight ?? 75; // Weight in kg

    // Use provided previous injuries or fetch from player data
    final int injuries =
        previousInjuries ?? (player.hasPreviousInjuries == true ? 1 : 0);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "Player_Age": age,
          "Player_Weight": weight,
          "Player_Height": height,
          "Previous_Injuries": injuries,
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Return true if high injury risk (1), false otherwise (0)
        return result['injury'] == 1;
      } else {
        throw Exception('Failed to predict injury: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to injury prediction service: $e');
    }
  }

  // Predict fatigue level for a player based on recent performance
  Future<int> predictFatigueLevel(Performance performance) async {
    final url = Uri.parse('$_baseUrl/predict_fatigue');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "stamina_rating": performance.staminaRating,
          "speed_rating": performance.speedRating,
          "strength_rating": performance.strengthRating ??
              performance
                  .tacticalRating, // Use strength if available, fallback to tactical
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Return the fatigue level (0-10)
        return result['fatigue'];
      } else {
        throw Exception('Failed to predict fatigue: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to fatigue prediction service: $e');
    }
  }
}
