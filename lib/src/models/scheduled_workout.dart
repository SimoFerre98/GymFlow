class ScheduledWorkout {
  final String id;
  final String userId;
  final String workoutTemplateId;
  final String workoutName;
  final DateTime scheduledDate;
  final bool isCompleted;

  ScheduledWorkout({
    required this.id,
    required this.userId,
    required this.workoutTemplateId,
    required this.workoutName,
    required this.scheduledDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'workoutTemplateId': workoutTemplateId,
      'workoutName': workoutName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory ScheduledWorkout.fromMap(Map<String, dynamic> map, String id) {
    return ScheduledWorkout(
      id: id,
      userId: map['userId'] ?? '',
      workoutTemplateId: map['workoutTemplateId'] ?? '',
      workoutName: map['workoutName'] ?? 'Unknown Workout',
      scheduledDate:
          DateTime.tryParse(map['scheduledDate'] ?? '') ?? DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
