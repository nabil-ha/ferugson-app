import 'package:uuid/uuid.dart';

class SelfAssessment {
  final String id;
  final String playerId;
  final String sessionId;
  final int speed;
  final int stamina;
  final int strength;
  final int fatiguePercentage;
  final String? comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  SelfAssessment({
    String? id,
    required this.playerId,
    required this.sessionId,
    required this.speed,
    required this.stamina,
    required this.strength,
    required this.fatiguePercentage,
    this.comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory SelfAssessment.fromJson(Map<String, dynamic> json) {
    return SelfAssessment(
      id: json['id'],
      playerId: json['playerId'],
      sessionId: json['sessionId'],
      speed: json['speed'],
      stamina: json['stamina'],
      strength: json['strength'],
      fatiguePercentage: json['fatiguePercentage'],
      comments: json['comments'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'playerId': playerId,
      'sessionId': sessionId,
      'speed': speed,
      'stamina': stamina,
      'strength': strength,
      'fatiguePercentage': fatiguePercentage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (comments != null) {
      data['comments'] = comments;
    }

    return data;
  }

  SelfAssessment copyWith({
    String? id,
    String? playerId,
    String? sessionId,
    int? speed,
    int? stamina,
    int? strength,
    int? fatiguePercentage,
    String? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SelfAssessment(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      sessionId: sessionId ?? this.sessionId,
      speed: speed ?? this.speed,
      stamina: stamina ?? this.stamina,
      strength: strength ?? this.strength,
      fatiguePercentage: fatiguePercentage ?? this.fatiguePercentage,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
