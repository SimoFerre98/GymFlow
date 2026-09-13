import '../workout.dart';
import '../exercise.dart';
import '../local/local_workout_template.dart';
extension WorkoutTemplateToLocal on WorkoutTemplate {
  LocalWorkoutTemplate toLocal() {
    final local = LocalWorkoutTemplate()
      ..firestoreId = id
      ..userId = userId
      ..name = name
      ..description = description
      ..parentProgramId = parentProgramId
      ..category = category.name;
    local.exercises = exercises.map((e) => e.toLocal()).toList();
    return local;
  }
}
extension WorkoutTemplateExerciseToLocal on WorkoutTemplateExercise {
  LocalWorkoutTemplateExercise toLocal() {
    final local = LocalWorkoutTemplateExercise()
      ..exerciseId = exerciseId
      ..exerciseName = exerciseName
      ..type = type.name
      ..targetDistance = targetDistance
      ..targetDurationSeconds = targetDurationSeconds
      ..targetRPE = targetRPE
      ..restSeconds = restSeconds
      ..notes = notes
      ..superSetGroup = superSetGroup;
    local.plannedSets = plannedSets.map((s) => s.toLocal()).toList();
    return local;
  }
}
extension PlannedSetToLocal on PlannedSet {
  LocalPlannedSet toLocal() {
    return LocalPlannedSet()
      ..reps = reps
      ..repsMax = repsMax
      ..weight = weight
      ..perSide = perSide
      ..kind = kind.name
      ..restSeconds = restSeconds
      ..note = note;
  }
}
extension LocalWorkoutTemplateToDomain on LocalWorkoutTemplate {
  WorkoutTemplate toDomain() {
    return WorkoutTemplate(
      id: firestoreId ?? id.toString(),
      userId: userId,
      name: name,
      description: description,
      parentProgramId: parentProgramId,
      exercises: exercises.map((e) => e.toDomain()).toList(),
      category: ExerciseType.values.firstWhere(
        (t) => t.name == category,
        orElse: () => ExerciseType.strength,
      ),
    );
  }
}
extension LocalWorkoutTemplateExerciseToDomain on LocalWorkoutTemplateExercise {
  WorkoutTemplateExercise toDomain() {
    return WorkoutTemplateExercise(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      type: ExerciseType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => ExerciseType.strength,
      ),
      plannedSets: plannedSets.map((s) => s.toDomain()).toList(),
      targetDistance: targetDistance,
      targetDurationSeconds: targetDurationSeconds,
      targetRPE: targetRPE,
      restSeconds: restSeconds,
      notes: notes,
      superSetGroup: superSetGroup,
    );
  }
}
extension LocalPlannedSetToDomain on LocalPlannedSet {
  PlannedSet toDomain() {
    return PlannedSet(
      reps: reps,
      repsMax: repsMax,
      weight: weight,
      perSide: perSide,
      kind: PlannedSetKind.values.firstWhere(
        (k) => k.name == kind,
        orElse: () => PlannedSetKind.normal,
      ),
      restSeconds: restSeconds,
      note: note,
    );
  }
}
