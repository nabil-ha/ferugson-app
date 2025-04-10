import 'package:uuid/uuid.dart';

class Performance {
  final String id;
  final String playerId;
  final String sessionId;
  final String playerPosition;
  final int speedRating;
  final int staminaRating;
  final int accuracyRating;
  final int tacticalRating;
  final int? strengthRating;
  final String? coachComments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Performance({
    String? id,
    required this.playerId,
    required this.sessionId,
    required this.playerPosition,
    required this.speedRating,
    required this.staminaRating,
    required this.accuracyRating,
    required this.tacticalRating,
    this.strengthRating,
    this.coachComments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      id: json['id'],
      playerId: json['playerId'],
      sessionId: json['sessionId'],
      playerPosition: json['playerPosition'],
      speedRating: json['speedRating'],
      staminaRating: json['staminaRating'],
      accuracyRating: json['accuracyRating'],
      tacticalRating: json['tacticalRating'],
      strengthRating: json['strengthRating'],
      coachComments: json['coachComments'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'playerId': playerId,
      'sessionId': sessionId,
      'playerPosition': playerPosition,
      'speedRating': speedRating,
      'staminaRating': staminaRating,
      'accuracyRating': accuracyRating,
      'tacticalRating': tacticalRating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (strengthRating != null) {
      data['strengthRating'] = strengthRating;
    }

    if (coachComments != null) {
      data['coachComments'] = coachComments;
    }

    return data;
  }

  Performance copyWith({
    String? id,
    String? playerId,
    String? sessionId,
    String? playerPosition,
    int? speedRating,
    int? staminaRating,
    int? accuracyRating,
    int? tacticalRating,
    int? strengthRating,
    String? coachComments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Performance(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      sessionId: sessionId ?? this.sessionId,
      playerPosition: playerPosition ?? this.playerPosition,
      speedRating: speedRating ?? this.speedRating,
      staminaRating: staminaRating ?? this.staminaRating,
      accuracyRating: accuracyRating ?? this.accuracyRating,
      tacticalRating: tacticalRating ?? this.tacticalRating,
      strengthRating: strengthRating ?? this.strengthRating,
      coachComments: coachComments ?? this.coachComments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
