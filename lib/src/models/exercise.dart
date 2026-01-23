enum ExerciseType { strength, cardio, hypertrophy, mobility }

class Exercise {
  final String id;
  final String? userId; // Null for default exercises
  final String name;
  final String description;
  final ExerciseType type;
  final String? videoUrl;
  final List<String> musclesTargeted;
  final bool isCustom;

  Exercise({
    required this.id,
    this.userId,
    required this.name,
    required this.description,
    required this.type,
    this.videoUrl,
    required this.musclesTargeted,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'videoUrl': videoUrl,
      'musclesTargeted': musclesTargeted,
      'isCustom': isCustom,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map, String id) {
    return Exercise(
      id: id,
      userId: map['userId'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: _parseType(map['type']),
      videoUrl: map['videoUrl'],
      musclesTargeted: List<String>.from(map['musclesTargeted'] ?? []),
      isCustom: map['isCustom'] ?? false,
    );
  }

  static ExerciseType _parseType(String? type) {
    return ExerciseType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => ExerciseType.strength,
    );
  }
}
