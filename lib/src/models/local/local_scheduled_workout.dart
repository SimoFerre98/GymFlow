import 'package:isar/isar.dart';
part 'local_scheduled_workout.g.dart';
@Collection()
class LocalScheduledWorkout {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String? firestoreId;
  @Index()
  late String userId;
  late String workoutTemplateId;
  late String workoutName;
  late DateTime scheduledDate;
  bool isCompleted = false;
}
