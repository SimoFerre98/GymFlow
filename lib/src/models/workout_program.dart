import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutProgram {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> workoutIds; // IDs of WorkoutTemplates in this program
  final bool isActive;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int color; // Color value

  WorkoutProgram({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.workoutIds,
    this.isActive = false,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.color = 0xFF2196F3, // Default Blue
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
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'color': color,
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
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'])
          : null,
      color: map['color'] ?? 0xFF2196F3,
    );
  }

  WorkoutProgram copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<String>? workoutIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    int? color,
  }) {
    return WorkoutProgram(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      workoutIds: workoutIds ?? this.workoutIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
    );
  }
}
