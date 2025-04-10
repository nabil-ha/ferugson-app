import 'package:uuid/uuid.dart';

enum SessionType { training, match }

enum TrainingFocus {
  endurance,
  speed,
  tactical,
  strength,
  technical,
  recovery,
  mixed
}

enum ConfirmationStatus { pending, confirmed, declined }

class Session {
  final String id;
  final String title;
  final SessionType type;
  final DateTime dateTime;
  final String location;
  final String coachId;
  final List<String> invitedPlayersIds;
  final Map<String, ConfirmationStatus> confirmationStatus;
  final TrainingFocus? trainingFocus;
  final String? opponentTeam;
  final String? coachComments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Session({
    String? id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.location,
    required this.coachId,
    required this.invitedPlayersIds,
    Map<String, ConfirmationStatus>? confirmationStatus,
    this.trainingFocus,
    this.opponentTeam,
    this.coachComments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        confirmationStatus = confirmationStatus ??
            Map.fromIterable(invitedPlayersIds,
                key: (player) => player,
                value: (player) => ConfirmationStatus.pending),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      title: json['title'],
      type: SessionType.values.firstWhere(
        (e) => e.toString() == 'SessionType.${json['type']}',
        orElse: () => SessionType.training,
      ),
      dateTime: DateTime.parse(json['dateTime']),
      location: json['location'],
      coachId: json['coachId'],
      invitedPlayersIds: List<String>.from(json['invitedPlayersIds'] ?? []),
      confirmationStatus:
          (json['confirmationStatus'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(
                  key,
                  ConfirmationStatus.values.firstWhere(
                    (e) => e.toString() == 'ConfirmationStatus.$value',
                    orElse: () => ConfirmationStatus.pending,
                  ),
                ),
              ) ??
              {},
      trainingFocus: json['trainingFocus'] != null
          ? TrainingFocus.values.firstWhere(
              (e) => e.toString() == 'TrainingFocus.${json['trainingFocus']}',
              orElse: () => TrainingFocus.mixed,
            )
          : null,
      opponentTeam: json['opponentTeam'],
      coachComments: json['coachComments'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'coachId': coachId,
      'invitedPlayersIds': invitedPlayersIds,
      'confirmationStatus': confirmationStatus.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (trainingFocus != null) {
      data['trainingFocus'] = trainingFocus.toString().split('.').last;
    }

    if (opponentTeam != null) {
      data['opponentTeam'] = opponentTeam;
    }

    if (coachComments != null && coachComments!.isNotEmpty) {
      data['coachComments'] = coachComments;
    }

    return data;
  }

  Session copyWith({
    String? id,
    String? title,
    SessionType? type,
    DateTime? dateTime,
    String? location,
    String? coachId,
    List<String>? invitedPlayersIds,
    Map<String, ConfirmationStatus>? confirmationStatus,
    TrainingFocus? trainingFocus,
    String? opponentTeam,
    String? coachComments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      coachId: coachId ?? this.coachId,
      invitedPlayersIds: invitedPlayersIds ?? this.invitedPlayersIds,
      confirmationStatus: confirmationStatus ?? this.confirmationStatus,
      trainingFocus: trainingFocus ?? this.trainingFocus,
      opponentTeam: opponentTeam ?? this.opponentTeam,
      coachComments: coachComments ?? this.coachComments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
