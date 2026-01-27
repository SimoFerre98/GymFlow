import 'package:gymflow/src/models/exercise.dart';

// --- Session Models (Runtime) ---

class WorkoutSet {
  double weight;
  int reps;
  double? distance; // km or miles
  int? durationSeconds; // time in seconds
  double? calories;
  int? level;
  bool isCompleted;
  double? rpe;
  String? notes;

  WorkoutSet({
    this.weight = 0,
    this.reps = 0,
    this.distance,
    this.durationSeconds,
    this.calories,
    this.level,
    this.isCompleted = false,
    this.rpe,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
      'distance': distance,
      'durationSeconds': durationSeconds,
      'calories': calories,
      'level': level,
      'isCompleted': isCompleted,
      'rpe': rpe,
      'notes': notes,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: (map['weight'] ?? 0).toDouble(),
      reps: map['reps'] ?? 0,
      distance: map['distance']?.toDouble(),
      durationSeconds: map['durationSeconds'],
      calories: map['calories']?.toDouble(),
      level: map['level'],
      isCompleted: map['isCompleted'] ?? false,
      rpe: map['rpe']?.toDouble(),
      notes: map['notes'],
    );
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final ExerciseType type;
  final List<WorkoutSet> sets;
  String? notes;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.type = ExerciseType.strength, // Default
    required this.sets,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'type': type.toString().split('.').last,
      'sets': sets.map((s) => s.toMap()).toList(),
      'notes': notes,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      type: _parseType(map['type']),
      sets:
          (map['sets'] as List<dynamic>?)
              ?.map((s) => WorkoutSet.fromMap(s))
              .toList() ??
          [],
      notes: map['notes'],
    );
  }

  static ExerciseType _parseType(String? type) {
    return ExerciseType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => ExerciseType.strength,
    );
  }
}

// --- Template Models (Configuration) ---

class WorkoutTemplateExercise {
  final String exerciseId;
  final String exerciseName;
  final ExerciseType type; // New field
  final int targetSets;
  final String targetReps; // e.g., "8-12", "5"
  final double? targetWeight;
  final double? targetDistance; // New
  final int? targetDurationSeconds; // New
  final double? targetRPE;
  final int? restSeconds;
  final String? notes;

  WorkoutTemplateExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.type = ExerciseType.strength,
    required this.targetSets,
    this.targetReps = "10",
    this.targetWeight,
    this.targetDistance,
    this.targetDurationSeconds,
    this.targetRPE,
    this.restSeconds,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'type': type.toString().split('.').last,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'targetDistance': targetDistance,
      'targetDurationSeconds': targetDurationSeconds,
      'targetRPE': targetRPE,
      'restSeconds': restSeconds,
      'notes': notes,
    };
  }

  factory WorkoutTemplateExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutTemplateExercise(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      type: _parseType(map['type']),
      targetSets: map['targetSets'] ?? 3,
      targetReps: map['targetReps'] ?? "10",
      targetWeight: map['targetWeight']?.toDouble(),
      targetDistance: map['targetDistance']?.toDouble(),
      targetDurationSeconds: map['targetDurationSeconds'],
      targetRPE: map['targetRPE']?.toDouble(),
      restSeconds: map['restSeconds'],
      notes: map['notes'],
    );
  }
  static ExerciseType _parseType(String? type) {
    return ExerciseType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => ExerciseType.strength,
    );
  }

  WorkoutTemplateExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    ExerciseType? type,
    int? targetSets,
    String? targetReps,
    double? targetWeight,
    double? targetDistance,
    int? targetDurationSeconds,
    double? targetRPE,
    int? restSeconds,
    String? notes,
  }) {
    return WorkoutTemplateExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      type: type ?? this.type,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetDistance: targetDistance ?? this.targetDistance,
      targetDurationSeconds:
          targetDurationSeconds ?? this.targetDurationSeconds,
      targetRPE: targetRPE ?? this.targetRPE,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
    );
  }
}

class WorkoutTemplate {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? parentProgramId;
  final List<WorkoutTemplateExercise> exercises;
  final ExerciseType category;

  WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.parentProgramId,
    required this.exercises,
    required this.category,
  });

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'parentProgramId': parentProgramId,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'category': category.toString().split('.').last,
    };
  }

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map, String id) {
    // Backward compatibility for old 'WorkoutExercise' structure in templates
    List<WorkoutTemplateExercise> parsedExercises = [];
    if (map['exercises'] != null) {
      final list = map['exercises'] as List<dynamic>;
      if (list.isNotEmpty) {
        // Check if first item looks like old structure (has 'sets' list) or new (has 'targetSets')
        final first = list.first as Map<String, dynamic>;
        if (first.containsKey('sets')) {
          // Old structure: Convert to new
          parsedExercises = list.map((e) {
            final oldSets = (e['sets'] as List?)?.length ?? 3;
            return WorkoutTemplateExercise(
              exerciseId: e['exerciseId'] ?? '',
              exerciseName: e['exerciseName'] ?? '',
              targetSets: oldSets == 0 ? 3 : oldSets,
              targetReps: "10", // Default
              notes: e['notes'],
            );
          }).toList();
        } else {
          // New structure
          parsedExercises = list
              .map((e) => WorkoutTemplateExercise.fromMap(e))
              .toList();
        }
      }
    }

    return WorkoutTemplate(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      parentProgramId: map['parentProgramId'],
      exercises: parsedExercises,
      category: Exercise.fromMap({'type': map['category']}, '').type,
    );
  }

  WorkoutTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? parentProgramId,
    List<WorkoutTemplateExercise>? exercises,
    ExerciseType? category,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      parentProgramId: parentProgramId ?? this.parentProgramId,
      exercises: exercises ?? this.exercises,
      category: category ?? this.category,
    );
  }
}
