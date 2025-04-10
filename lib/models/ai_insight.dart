import 'package:uuid/uuid.dart';

enum InsightType {
  injuryRisk,
  fatigueManagement,
  performanceImprovement,
  restRecommendation,
  teamPerformance
}

enum RiskLevel { low, moderate, high, critical }

class AIInsight {
  final String id;
  final String? playerId; // Null if this is a team insight
  final InsightType type;
  final String title;
  final String description;
  final RiskLevel? riskLevel; // Null if not risk-related
  final Map<String, dynamic>? supportingData;
  final DateTime expirationDate;
  final bool isAcknowledged;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIInsight({
    String? id,
    this.playerId,
    required this.type,
    required this.title,
    required this.description,
    this.riskLevel,
    this.supportingData,
    required this.expirationDate,
    this.isAcknowledged = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id'],
      playerId: json['playerId'],
      type: InsightType.values.firstWhere(
        (e) => e.toString() == 'InsightType.${json['type']}',
        orElse: () => InsightType.performanceImprovement,
      ),
      title: json['title'],
      description: json['description'],
      riskLevel: json['riskLevel'] != null
          ? RiskLevel.values.firstWhere(
              (e) => e.toString() == 'RiskLevel.${json['riskLevel']}',
              orElse: () => RiskLevel.low,
            )
          : null,
      supportingData: json['supportingData'],
      expirationDate: DateTime.parse(json['expirationDate']),
      isAcknowledged: json['isAcknowledged'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'expirationDate': expirationDate.toIso8601String(),
      'isAcknowledged': isAcknowledged,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (playerId != null) {
      data['playerId'] = playerId;
    }

    if (riskLevel != null) {
      data['riskLevel'] = riskLevel.toString().split('.').last;
    }

    if (supportingData != null) {
      data['supportingData'] = supportingData;
    }

    return data;
  }

  AIInsight copyWith({
    String? id,
    String? playerId,
    InsightType? type,
    String? title,
    String? description,
    RiskLevel? riskLevel,
    Map<String, dynamic>? supportingData,
    DateTime? expirationDate,
    bool? isAcknowledged,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIInsight(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      riskLevel: riskLevel ?? this.riskLevel,
      supportingData: supportingData ?? this.supportingData,
      expirationDate: expirationDate ?? this.expirationDate,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
