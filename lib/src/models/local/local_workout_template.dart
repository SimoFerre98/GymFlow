import 'package:isar/isar.dart';
part 'local_workout_template.g.dart';
@Collection()
class LocalWorkoutTemplate {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String? firestoreId;
  @Index()
  late String userId;
  late String name;
  String? description;
  String? parentProgramId;
  late String category;
  List<LocalWorkoutTemplateExercise> exercises = [];
}
@Embedded()
class LocalWorkoutTemplateExercise {
  late String exerciseId;
  late String exerciseName;
  late String type;
  List<LocalPlannedSet> plannedSets = [];
  double? targetDistance;
  int? targetDurationSeconds;
  double? targetRPE;
  int? restSeconds;
  String? notes;
  String? superSetGroup;
}
@Embedded()
class LocalPlannedSet {
  int? reps;
  int? repsMax;
  double? weight;
  bool perSide = false;
  late String kind;
  int? restSeconds;
  String? note;
}
