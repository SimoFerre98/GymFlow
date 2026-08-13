import 'package:flutter/foundation.dart';

enum GoalType {
  workoutFrequency,
  targetLoad,
  bodyWeight,
}

@immutable
class UserGoal {
  final String id;
  final String userId;
  final String title;
  final GoalType type;
  final double targetValue;
  final double currentValue;
  final String unit;
  final String? exerciseId;
  final DateTime? deadline;
  final bool isAchieved;
  final DateTime createdAt;
  final DateTime? achievedAt;

  const UserGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.targetValue,
    this.currentValue = 0.0,
    required this.unit,
    this.exerciseId,
    this.deadline,
    this.isAchieved = false,
    required this.createdAt,
    this.achievedAt,
  });

  double get progressFraction {
    if (targetValue <= 0) return 0.0;
    final frac = currentValue / targetValue;
    return frac.clamp(0.0, 1.0);
  }

  UserGoal copyWith({
    String? id,
    String? userId,
    String? title,
    GoalType? type,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? exerciseId,
    DateTime? deadline,
    bool? isAchieved,
    DateTime? createdAt,
    DateTime? achievedAt,
  }) {
    return UserGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      exerciseId: exerciseId ?? this.exerciseId,
      deadline: deadline ?? this.deadline,
      isAchieved: isAchieved ?? this.isAchieved,
      createdAt: createdAt ?? this.createdAt,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'exerciseId': exerciseId,
      'deadline': deadline?.toIso8601String(),
      'isAchieved': isAchieved,
      'createdAt': createdAt.toIso8601String(),
      'achievedAt': achievedAt?.toIso8601String(),
    };
  }

  factory UserGoal.fromMap(Map<String, dynamic> map, String docId) {
    GoalType parseType(String? val) {
      if (val == 'targetLoad') return GoalType.targetLoad;
      if (val == 'bodyWeight') return GoalType.bodyWeight;
      return GoalType.workoutFrequency;
    }

    return UserGoal(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? 'Obiettivo',
      type: parseType(map['type'] as String?),
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0.0,
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
      exerciseId: map['exerciseId'] as String?,
      deadline: map['deadline'] != null ? DateTime.tryParse(map['deadline'] as String) : null,
      isAchieved: map['isAchieved'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      achievedAt: map['achievedAt'] != null ? DateTime.tryParse(map['achievedAt'] as String) : null,
    );
  }
}
