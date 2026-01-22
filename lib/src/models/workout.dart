import 'package:gymflow/src/models/exercise.dart';

class WorkoutSet {
  double weight;
  int reps;
  bool isCompleted;

  WorkoutSet({
    required this.weight,
    required this.reps,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {'weight': weight, 'reps': reps, 'isCompleted': isCompleted};
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: (map['weight'] ?? 0).toDouble(),
      reps: map['reps'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName; // Cached for checking
  final List<WorkoutSet> sets;
  String? notes;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((s) => s.toMap()).toList(),
      'notes': notes,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      sets:
          (map['sets'] as List<dynamic>?)
              ?.map((s) => WorkoutSet.fromMap(s))
              .toList() ??
          [],
      notes: map['notes'],
    );
  }
}

class WorkoutTemplate {
  final String id;
  final String userId; // Creator
  final String name;
  final String? description;
  final List<WorkoutExercise> exercises;
  final ExerciseType category; // Main focus

  WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.exercises,
    required this.category,
  });

  // Serialization methods...
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'category': category.toString().split('.').last,
    };
  }

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutTemplate(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      exercises:
          (map['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromMap(e))
              .toList() ??
          [],
      category: Exercise.fromMap({
        'type': map['category'],
      }, '').type, // Reusing parse logic or duplicate it
    );
  }
}
