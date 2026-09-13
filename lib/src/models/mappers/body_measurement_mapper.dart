import '../body_measurement.dart';
import '../local/local_body_measurement.dart';
extension BodyMeasurementToLocal on BodyMeasurement {
  LocalBodyMeasurement toLocal() {
    return LocalBodyMeasurement()
      ..firestoreId = id
      ..userId = userId
      ..date = date
      ..weight = weight
      ..height = height
      ..chest = chest
      ..waist = waist
      ..hips = hips
      ..biceps = biceps
      ..thighs = thighs
      ..calves = calves
      ..shoulders = shoulders
      ..neck = neck
      ..bodyFatPercentage = bodyFatPercentage;
  }
}
extension LocalBodyMeasurementToDomain on LocalBodyMeasurement {
  BodyMeasurement toDomain() {
    return BodyMeasurement(
      id: firestoreId ?? id.toString(),
      userId: userId,
      date: date,
      weight: weight,
      height: height,
      chest: chest,
      waist: waist,
      hips: hips,
      biceps: biceps,
      thighs: thighs,
      calves: calves,
      shoulders: shoulders,
      neck: neck,
      bodyFatPercentage: bodyFatPercentage,
    );
  }
}
