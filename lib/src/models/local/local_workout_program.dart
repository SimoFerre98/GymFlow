import 'package:isar/isar.dart';
part 'local_workout_program.g.dart';
@Collection()
class LocalWorkoutProgram {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String? firestoreId;
  @Index()
  late String userId;
  late String name;
  String? description;
  List<String> workoutIds = [];
  bool isActive = false;
  late DateTime createdAt;
  DateTime? startDate;
  DateTime? endDate;
  late int color;
}
