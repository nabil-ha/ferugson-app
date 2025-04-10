import 'package:uuid/uuid.dart';

enum FatigueLevel { none, mild, moderate, severe }

enum BodyArea {
  head,
  neck,
  shoulder,
  upperArm,
  elbow,
  forearm,
  wrist,
  hand,
  chest,
  abdomen,
  back,
  hip,
  thigh,
  knee,
  calf,
  ankle,
  foot
}

class FatigueReport {
  final String id;
  final String playerId;
  final String sessionId;
  final FatigueLevel fatigueLevel;
  final List<BodyArea> painAreas;
  final String? comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  FatigueReport({
    String? id,
    required this.playerId,
    required this.sessionId,
    required this.fatigueLevel,
    this.painAreas = const [],
    this.comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory FatigueReport.fromJson(Map<String, dynamic> json) {
    return FatigueReport(
      id: json['id'],
      playerId: json['playerId'],
      sessionId: json['sessionId'],
      fatigueLevel: FatigueLevel.values.firstWhere(
        (e) => e.toString() == 'FatigueLevel.${json['fatigueLevel']}',
        orElse: () => FatigueLevel.none,
      ),
      painAreas: (json['painAreas'] as List<dynamic>?)
              ?.map((area) => BodyArea.values.firstWhere(
                    (e) => e.toString() == 'BodyArea.$area',
                    orElse: () => throw Exception('Invalid body area: $area'),
                  ))
              .toList() ??
          [],
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
      'fatigueLevel': fatigueLevel.toString().split('.').last,
      'painAreas':
          painAreas.map((area) => area.toString().split('.').last).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (comments != null) {
      data['comments'] = comments;
    }

    return data;
  }

  FatigueReport copyWith({
    String? id,
    String? playerId,
    String? sessionId,
    FatigueLevel? fatigueLevel,
    List<BodyArea>? painAreas,
    String? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FatigueReport(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      sessionId: sessionId ?? this.sessionId,
      fatigueLevel: fatigueLevel ?? this.fatigueLevel,
      painAreas: painAreas ?? this.painAreas,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
