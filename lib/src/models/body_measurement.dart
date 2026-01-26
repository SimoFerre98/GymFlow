import 'package:cloud_firestore/cloud_firestore.dart';

class BodyMeasurement {
  final String id;
  final String userId;
  final DateTime date;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? biceps;
  final double? thighs;
  final double? calves;
  final double? shoulders;
  final double? neck;
  final double? bodyFatPercentage;

  BodyMeasurement({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.chest,
    this.waist,
    this.hips,
    this.biceps,
    this.thighs,
    this.calves,
    this.shoulders,
    this.neck,
    this.bodyFatPercentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'biceps': biceps,
      'thighs': thighs,
      'calves': calves,
      'shoulders': shoulders,
      'neck': neck,
      'bodyFatPercentage': bodyFatPercentage,
    };
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map, String documentId) {
    return BodyMeasurement(
      id: documentId,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      weight: map['weight']?.toDouble(),
      chest: map['chest']?.toDouble(),
      waist: map['waist']?.toDouble(),
      hips: map['hips']?.toDouble(),
      biceps: map['biceps']?.toDouble(),
      thighs: map['thighs']?.toDouble(),
      calves: map['calves']?.toDouble(),
      shoulders: map['shoulders']?.toDouble(),
      neck: map['neck']?.toDouble(),
      bodyFatPercentage: map['bodyFatPercentage']?.toDouble(),
    );
  }
}
