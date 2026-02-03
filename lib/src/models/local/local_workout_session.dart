import 'package:isar/isar.dart';

part 'local_workout_session.g.dart';

@Collection()
class LocalWorkoutSession {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? firestoreId;

  @Index()
  late String userId;

  late String workoutTemplateId;
  late String workoutName;
  late DateTime startTime;
  DateTime? endTime;

  String? notes;
  String? workoutType;

  List<LocalWorkoutExercise> exercises = [];
}

@Embedded()
class LocalWorkoutExercise {
  late String exerciseId;
  late String exerciseName;

  // Stored as string for simplicity, or we check if Isar supports Enum properly in Embedded
  // String is safer for now
  late String type;

  List<LocalWorkoutSet> sets = [];
  String? notes;
}

@Embedded()
class LocalWorkoutSet {
  double weight = 0;
  int reps = 0;
  double? distance;
  int? durationSeconds;
  double? calories;
  int? level;
  bool isCompleted = false;
  double? rpe;
  String? notes;
}
