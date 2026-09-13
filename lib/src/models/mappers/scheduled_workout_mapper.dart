import '../scheduled_workout.dart';
import '../local/local_scheduled_workout.dart';
extension ScheduledWorkoutToLocal on ScheduledWorkout {
  LocalScheduledWorkout toLocal() {
    return LocalScheduledWorkout()
      ..firestoreId = id
      ..userId = userId
      ..workoutTemplateId = workoutTemplateId
      ..workoutName = workoutName
      ..scheduledDate = scheduledDate
      ..isCompleted = isCompleted;
  }
}
extension LocalScheduledWorkoutToDomain on LocalScheduledWorkout {
  ScheduledWorkout toDomain() {
    return ScheduledWorkout(
      id: firestoreId ?? id.toString(),
      userId: userId,
      workoutTemplateId: workoutTemplateId,
      workoutName: workoutName,
      scheduledDate: scheduledDate,
      isCompleted: isCompleted,
    );
  }
}
