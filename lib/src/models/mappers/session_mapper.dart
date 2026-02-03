import '../session.dart';
import '../workout.dart';
import '../local/local_workout_session.dart';
import 'package:gymflow/src/models/exercise.dart';

extension WorkoutSessionToLocal on WorkoutSession {
  LocalWorkoutSession toLocal() {
    final local = LocalWorkoutSession()
      ..firestoreId = id
      ..userId = userId
      ..workoutTemplateId = workoutTemplateId
      ..workoutName = workoutName
      ..startTime = startTime
      ..endTime = endTime
      ..notes = notes
      ..workoutType = workoutType;

    local.exercises = exercises.map((e) => e.toLocal()).toList();
    return local;
  }
}

extension WorkoutExerciseToLocal on WorkoutExercise {
  LocalWorkoutExercise toLocal() {
    final local = LocalWorkoutExercise()
      ..exerciseId = exerciseId
      ..exerciseName = exerciseName
      ..type = type.name
      ..notes = notes;
    
    local.sets = sets.map((s) => s.toLocal()).toList();
    return local;
  }
}

extension WorkoutSetToLocal on WorkoutSet {
  LocalWorkoutSet toLocal() {
    return LocalWorkoutSet()
      ..weight = weight
      ..reps = reps
      ..distance = distance
      ..durationSeconds = durationSeconds
      ..calories = calories
      ..level = level
      ..isCompleted = isCompleted
      ..rpe = rpe
      ..notes = notes;
  }
}

extension LocalWorkoutSessionToDomain on LocalWorkoutSession {
  WorkoutSession toDomain() {
    return WorkoutSession(
      id: firestoreId ?? id.toString(), // Fallback to local ID if not synced
      userId: userId,
      workoutTemplateId: workoutTemplateId,
      workoutName: workoutName,
      startTime: startTime,
      endTime: endTime,
      exercises: exercises.map((e) => e.toDomain()).toList(),
      notes: notes,
      workoutType: workoutType ?? 'strength',
    );
  }
}

extension LocalWorkoutExerciseToDomain on LocalWorkoutExercise {
  WorkoutExercise toDomain() {
    return WorkoutExercise(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      type: ExerciseType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => ExerciseType.strength,
      ),
      sets: sets.map((s) => s.toDomain()).toList(),
      notes: notes,
    );
  }
}

extension LocalWorkoutSetToDomain on LocalWorkoutSet {
  WorkoutSet toDomain() {
    return WorkoutSet(
      weight: weight,
      reps: reps,
      distance: distance,
      durationSeconds: durationSeconds,
      calories: calories,
      level: level,
      isCompleted: isCompleted,
      rpe: rpe,
      notes: notes,
    );
  }
}
