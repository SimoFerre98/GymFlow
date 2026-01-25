import 'package:gymflow/src/models/exercise.dart';

// --- Session Models (Runtime) ---

class WorkoutSet {
  double weight;
  int reps;
  bool isCompleted;
  double? rpe; // New: Rate of Perceived Exertion (1-10)
  String? notes; // New: Per-set notes

  WorkoutSet({
    required this.weight,
    required this.reps,
    this.isCompleted = false,
    this.rpe,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
      'isCompleted': isCompleted,
      'rpe': rpe,
      'notes': notes,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: (map['weight'] ?? 0).toDouble(),
      reps: map['reps'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      rpe: map['rpe']?.toDouble(),
      notes: map['notes'],
    );
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
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

// --- Template Models (Configuration) ---

class WorkoutTemplateExercise {
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final String targetReps; // e.g., "8-12", "5"
  final double? targetRPE;
  final int? restSeconds;
  final String? notes;

  WorkoutTemplateExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    this.targetReps = "10",
    this.targetRPE,
    this.restSeconds,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetRPE': targetRPE,
      'restSeconds': restSeconds,
      'notes': notes,
    };
  }

  factory WorkoutTemplateExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutTemplateExercise(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      targetSets: map['targetSets'] ?? 3,
      targetReps: map['targetReps'] ?? "10",
      targetRPE: map['targetRPE']?.toDouble(),
      restSeconds: map['restSeconds'],
      notes: map['notes'],
    );
  }
}

class WorkoutTemplate {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? parentProgramId; // Link to "Scheda"
  final List<WorkoutTemplateExercise> exercises; // New structure
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
}
