import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { coach, player, owner }

class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.player,
      ),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Coach extends User {
  final int sessionCount;
  final List<String> pendingNotifications;
  final List<String> injuryAlerts;

  Coach({
    required super.id,
    required super.name,
    required super.email,
    super.photoUrl,
    required super.createdAt,
    required super.updatedAt,
    this.sessionCount = 0,
    this.pendingNotifications = const [],
    this.injuryAlerts = const [],
  }) : super(role: UserRole.coach);

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now()),
      sessionCount: json['sessionCount'] ?? 0,
      pendingNotifications:
          List<String>.from(json['pendingNotifications'] ?? []),
      injuryAlerts: List<String>.from(json['injuryAlerts'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data.addAll({
      'sessionCount': sessionCount,
      'pendingNotifications': pendingNotifications,
      'injuryAlerts': injuryAlerts,
    });
    return data;
  }

  Coach coachCopyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sessionCount,
    List<String>? pendingNotifications,
    List<String>? injuryAlerts,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionCount: sessionCount ?? this.sessionCount,
      pendingNotifications: pendingNotifications ?? this.pendingNotifications,
      injuryAlerts: injuryAlerts ?? this.injuryAlerts,
    );
  }

  @override
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionCount: sessionCount,
      pendingNotifications: pendingNotifications,
      injuryAlerts: injuryAlerts,
    );
  }
}

enum PlayerPosition { goalkeeper, defender, midfielder, forward }

class Player extends User {
  final PlayerPosition position;
  final List<String> upcomingSessions;
  final int fatigueStatus;
  final List<Map<String, dynamic>> personalPerformanceTrends;
  final DateTime? birthdate;
  final int? height; // in cm
  final int? weight; // in kg
  final int? previousInjuries;

  Player({
    required super.id,
    required super.name,
    required super.email,
    super.photoUrl,
    required super.createdAt,
    required super.updatedAt,
    required this.position,
    this.upcomingSessions = const [],
    this.fatigueStatus = 0,
    this.personalPerformanceTrends = const [],
    this.birthdate,
    this.height,
    this.weight,
    this.previousInjuries,
  }) : super(role: UserRole.player);

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : (json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now()),
      position: PlayerPosition.values.firstWhere(
        (e) => e.toString() == 'PlayerPosition.${json['position']}',
        orElse: () => PlayerPosition.midfielder,
      ),
      upcomingSessions: List<String>.from(json['upcomingSessions'] ?? []),
      fatigueStatus: json['fatigueStatus'] ?? 0,
      personalPerformanceTrends: List<Map<String, dynamic>>.from(
          json['personalPerformanceTrends'] ?? []),
      birthdate: json['birthdate'] is Timestamp
          ? (json['birthdate'] as Timestamp).toDate()
          : (json['birthdate'] is String
              ? DateTime.parse(json['birthdate'])
              : null),
      height: json['height'],
      weight: json['weight'],
      previousInjuries: json['previousInjuries'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data.addAll({
      'position': position.toString().split('.').last,
      'upcomingSessions': upcomingSessions,
      'fatigueStatus': fatigueStatus,
      'personalPerformanceTrends': personalPerformanceTrends,
    });

    if (birthdate != null) {
      data['birthdate'] = birthdate!.toIso8601String();
    }
    if (height != null) {
      data['height'] = height;
    }
    if (weight != null) {
      data['weight'] = weight;
    }
    if (previousInjuries != null) {
      data['previousInjuries'] = previousInjuries;
    }

    return data;
  }

  Player playerCopyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    PlayerPosition? position,
    List<String>? upcomingSessions,
    int? fatigueStatus,
    List<Map<String, dynamic>>? personalPerformanceTrends,
    DateTime? birthdate,
    int? height,
    int? weight,
    int? previousInjuries,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      position: position ?? this.position,
      upcomingSessions: upcomingSessions ?? this.upcomingSessions,
      fatigueStatus: fatigueStatus ?? this.fatigueStatus,
      personalPerformanceTrends:
          personalPerformanceTrends ?? this.personalPerformanceTrends,
      birthdate: birthdate ?? this.birthdate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      previousInjuries: previousInjuries ?? this.previousInjuries,
    );
  }

  @override
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      position: position,
      upcomingSessions: upcomingSessions,
      fatigueStatus: fatigueStatus,
      personalPerformanceTrends: personalPerformanceTrends,
      birthdate: birthdate,
      height: height,
      weight: weight,
      previousInjuries: previousInjuries,
    );
  }
}

class Owner extends User {
  Owner({
    required super.id,
    required super.name,
    required super.email,
    super.photoUrl,
    required super.createdAt,
    required super.updatedAt,
  }) : super(role: UserRole.owner);

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
