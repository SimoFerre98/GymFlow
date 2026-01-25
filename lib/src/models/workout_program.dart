import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutProgram {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> workoutIds; // IDs of WorkoutTemplates in this program
  final bool isActive;
  final DateTime createdAt;

  WorkoutProgram({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.workoutIds,
    this.isActive = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'workoutIds': workoutIds,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WorkoutProgram.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutProgram(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      workoutIds: List<String>.from(map['workoutIds'] ?? []),
      isActive: map['isActive'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
