import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout_type.dart';

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

  /// Ritmo calcolato in minuti al chilometro (min/km) per attività cardio.
  ///
  /// Restituisce null se la distanza o la durata sono assenti o non positive.
  double? get paceMinPerKm {
    if (distance == null || distance! <= 0 || durationSeconds == null || durationSeconds! <= 0) {
      return null;
    }
    return (durationSeconds! / 60.0) / distance!;
  }

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

enum PlannedSetKind { normal, toFailure }

class PlannedSet {
  final int? reps; // null solo se kind == toFailure
  final int? repsMax; // per intervalli: es. 8-12 -> reps 8, repsMax 12
  final double? weight;
  final bool perSide; // «10 kg per parte»
  final PlannedSetKind kind;
  final int? restSeconds; // sovrascrive il recupero dell'esercizio
  final String? note; // «4 iso 3"»

  PlannedSet({
    this.reps = 10,
    this.repsMax,
    this.weight,
    this.perSide = false,
    this.kind = PlannedSetKind.normal,
    this.restSeconds,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'repsMax': repsMax,
      'weight': weight,
      'perSide': perSide,
      'kind': kind.name,
      'restSeconds': restSeconds,
      'note': note,
    };
  }

  factory PlannedSet.fromMap(Map<String, dynamic> map) {
    return PlannedSet(
      reps: map['reps'],
      repsMax: map['repsMax'],
      weight: map['weight']?.toDouble(),
      perSide: map['perSide'] ?? false,
      kind: PlannedSetKind.values.firstWhere(
        (k) => k.name == map['kind'],
        orElse: () => PlannedSetKind.normal,
      ),
      restSeconds: map['restSeconds'],
      note: map['note'],
    );
  }

  PlannedSet copyWith({
    int? reps,
    int? repsMax,
    double? weight,
    bool? perSide,
    PlannedSetKind? kind,
    int? restSeconds,
    String? note,
  }) {
    return PlannedSet(
      reps: reps ?? this.reps,
      repsMax: repsMax ?? this.repsMax,
      weight: weight ?? this.weight,
      perSide: perSide ?? this.perSide,
      kind: kind ?? this.kind,
      restSeconds: restSeconds ?? this.restSeconds,
      note: note ?? this.note,
    );
  }
}

class WorkoutTemplateExercise {
  final String exerciseId;
  final String exerciseName;
  final ExerciseType type;
  final List<PlannedSet> plannedSets;
  final double? targetDistance;
  final int? targetDurationSeconds;
  final double? targetRPE;
  final int? restSeconds;
  final String? notes;
  final String? superSetGroup; // es. "A", "B" per raggruppare in superserie/circuiti

  WorkoutTemplateExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.type = ExerciseType.strength,
    List<PlannedSet>? plannedSets,
    int? targetSets,
    String? targetReps,
    double? targetWeight,
    this.targetDistance,
    this.targetDurationSeconds,
    this.targetRPE,
    this.restSeconds,
    this.notes,
    this.superSetGroup,
  }) : plannedSets = plannedSets ??
            _generatePlannedSetsFromLegacy(
              setsCount: targetSets ?? 3,
              targetReps: targetReps ?? "10",
              targetWeight: targetWeight,
            );

  int get targetSets => plannedSets.isNotEmpty ? plannedSets.length : 3;

  String get targetReps {
    if (plannedSets.isEmpty) return "10";
    final first = plannedSets.first;
    if (first.kind == PlannedSetKind.toFailure) return "Cedimento";
    if (first.repsMax != null) return "${first.reps}-${first.repsMax}";
    return (first.reps ?? 10).toString();
  }

  double? get targetWeight => plannedSets.isNotEmpty ? plannedSets.first.weight : null;

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'type': type.toString().split('.').last,
      'plannedSets': plannedSets.map((s) => s.toMap()).toList(),
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'targetDistance': targetDistance,
      'targetDurationSeconds': targetDurationSeconds,
      'targetRPE': targetRPE,
      'restSeconds': restSeconds,
      'notes': notes,
      'superSetGroup': superSetGroup,
    };
  }

  factory WorkoutTemplateExercise.fromMap(Map<String, dynamic> map) {
    List<PlannedSet> sets = [];
    if (map['plannedSets'] != null && (map['plannedSets'] as List).isNotEmpty) {
      sets = (map['plannedSets'] as List)
          .map((item) => PlannedSet.fromMap(item as Map<String, dynamic>))
          .toList();
    } else {
      final setsCount = map['targetSets'] ?? 3;
      final repsStr = (map['targetReps'] ?? "10").toString();
      final weight = map['targetWeight']?.toDouble();
      sets = _generatePlannedSetsFromLegacy(
        setsCount: setsCount,
        targetReps: repsStr,
        targetWeight: weight,
      );
    }

    return WorkoutTemplateExercise(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      type: _parseType(map['type']),
      plannedSets: sets,
      targetDistance: map['targetDistance']?.toDouble(),
      targetDurationSeconds: map['targetDurationSeconds'],
      targetRPE: map['targetRPE']?.toDouble(),
      restSeconds: map['restSeconds'],
      notes: map['notes'],
      superSetGroup: map['superSetGroup'],
    );
  }

  static List<PlannedSet> _generatePlannedSetsFromLegacy({
    required int setsCount,
    required String targetReps,
    double? targetWeight,
  }) {
    final clean = targetReps.trim().toLowerCase();
    int? reps = 10;
    int? repsMax;
    PlannedSetKind kind = PlannedSetKind.normal;

    if (clean == 'max' || clean == 'cedimento' || clean == 'failure') {
      reps = null;
      kind = PlannedSetKind.toFailure;
    } else if (clean.contains('-')) {
      final parts = clean.split('-');
      reps = int.tryParse(parts[0].trim()) ?? 8;
      repsMax = int.tryParse(parts[1].trim()) ?? 12;
    } else {
      reps = int.tryParse(clean) ?? 10;
    }

    final count = setsCount <= 0 ? 3 : setsCount;
    return List.generate(
      count,
      (_) => PlannedSet(
        reps: reps,
        repsMax: repsMax,
        weight: targetWeight,
        kind: kind,
      ),
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
    List<PlannedSet>? plannedSets,
    int? targetSets,
    String? targetReps,
    double? targetWeight,
    double? targetDistance,
    int? targetDurationSeconds,
    double? targetRPE,
    int? restSeconds,
    String? notes,
    String? superSetGroup,
  }) {
    return WorkoutTemplateExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      type: type ?? this.type,
      plannedSets: plannedSets ?? this.plannedSets,
      targetDistance: targetDistance ?? this.targetDistance,
      targetDurationSeconds:
          targetDurationSeconds ?? this.targetDurationSeconds,
      targetRPE: targetRPE ?? this.targetRPE,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      superSetGroup: superSetGroup ?? this.superSetGroup,
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

  /// Tipo di allenamento ricavato dalla categoria della scheda.
  WorkoutType get workoutType => WorkoutType.fromString(category.name);

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
