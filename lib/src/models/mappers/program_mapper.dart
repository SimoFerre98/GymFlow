import '../workout_program.dart';
import '../local/local_workout_program.dart';
extension WorkoutProgramToLocal on WorkoutProgram {
  LocalWorkoutProgram toLocal() {
    return LocalWorkoutProgram()
      ..firestoreId = id
      ..userId = userId
      ..name = name
      ..description = description
      ..workoutIds = workoutIds
      ..isActive = isActive
      ..createdAt = createdAt
      ..startDate = startDate
      ..endDate = endDate
      ..color = color;
  }
}
extension LocalWorkoutProgramToDomain on LocalWorkoutProgram {
  WorkoutProgram toDomain() {
    return WorkoutProgram(
      id: firestoreId ?? id.toString(),
      userId: userId,
      name: name,
      description: description,
      workoutIds: workoutIds,
      isActive: isActive,
      createdAt: createdAt,
      startDate: startDate,
      endDate: endDate,
      color: color,
    );
  }
}
