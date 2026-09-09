import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/workout_type.dart';
class WorkoutSession {
  final String id;
  final String userId;
  final String workoutTemplateId; // ID of the template used (if any)
  final String workoutName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutExercise> exercises;
  final String? notes;
  final String workoutType; // 'strength', 'cardio', etc.
  /// Il nome della palestra dell'utente **al momento in cui questa sessione e
  /// stata salvata** (`UserProfile.gymName`), non un riferimento vivo: se
  /// l'utente cambia palestra, le sessioni vecchie restano con il nome di
  /// allora. Assente per ogni sessione registrata prima di questo campo — non
  /// va dedotto ne attribuito a posteriori, resta semplicemente fuori dal
  /// conteggio "sessioni qui" (vedi `gym_settings_screen.dart`): un numero
  /// mancante e onesto, uno inventato non lo sarebbe.
  final String? gymName;
  /// Tipo tipizzato dell'allenamento.
  WorkoutType get type => WorkoutType.fromString(workoutType);
  int get durationSeconds {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inSeconds;
  }
  WorkoutSession({
    required this.id,
    required this.userId,
    required this.workoutTemplateId,
    required this.workoutName,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.notes,
    this.workoutType = 'strength', // Default
    this.gymName,
  });
  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? workoutTemplateId,
    String? workoutName,
    DateTime? startTime,
    DateTime? endTime,
    List<WorkoutExercise>? exercises,
    String? notes,
    String? workoutType,
    String? gymName,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutTemplateId: workoutTemplateId ?? this.workoutTemplateId,
      workoutName: workoutName ?? this.workoutName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exercises: exercises ?? this.exercises,
      gymName: gymName ?? this.gymName,
      notes: notes ?? this.notes,
      workoutType: workoutType ?? this.workoutType,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'workoutTemplateId': workoutTemplateId,
      'workoutName': workoutName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'notes': notes,
      'workoutType': workoutType,
      'gymName': gymName,
    };
  }
  factory WorkoutSession.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutSession(
      id: id,
      userId: map['userId'] ?? '',
      workoutTemplateId: map['workoutTemplateId'] ?? '',
      workoutName: map['workoutName'] ?? '',
      startTime: DateTime.tryParse(map['startTime'] ?? '') ?? DateTime.now(),
      endTime: map['endTime'] != null
          ? DateTime.tryParse(map['endTime'])
          : null,
      exercises:
          (map['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromMap(e))
              .toList() ??
          [],
      notes: map['notes'],
      workoutType: map['workoutType'] ?? 'strength',
      gymName: map['gymName'],
    );
  }
}
