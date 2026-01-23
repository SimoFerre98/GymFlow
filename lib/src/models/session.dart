import 'package:gymflow/src/models/workout.dart';

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
  });

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
    );
  }
}
