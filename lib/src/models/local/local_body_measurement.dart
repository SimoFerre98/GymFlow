import 'package:isar/isar.dart';
part 'local_body_measurement.g.dart';
@Collection()
class LocalBodyMeasurement {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String? firestoreId;
  @Index()
  late String userId;
  late DateTime date;
  double? weight;
  double? height;
  double? chest;
  double? waist;
  double? hips;
  double? biceps;
  double? thighs;
  double? calves;
  double? shoulders;
  double? neck;
  double? bodyFatPercentage;
}
