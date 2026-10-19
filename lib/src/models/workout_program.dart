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
  /// Chi ha scritto la scheda, se non e il proprietario: il trainer del cliente
  /// (US-113). **Assente** per ciò che scrive il proprietario.
  ///
  /// `toMap()` lo **omette** quando e nullo, e non scrive mai `authorId: null`:
  /// le schermate costruiscono un oggetto nuovo a ogni salvataggio e fanno
  /// `update(toMap())`, e una chiave nulla cancellerebbe l'autore di una scheda
  /// ricevuta — e le regole, che vietano di cambiarlo, negherebbero il salvataggio
  /// al cliente che la modifica.
  final String? authorId;

  /// Il nome dell'autore, copiato alla scrittura: mostrarlo non deve richiedere
  /// di leggere il profilo di un altro utente. Presente solo con [authorId].
  final String? authorName;
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
    this.authorId,
    this.authorName,
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
      if (authorId != null) 'authorId': authorId,
      if (authorId != null && authorName != null) 'authorName': authorName,
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
      authorId: map['authorId'],
      authorName: map['authorName'],
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
    String? authorId,
    String? authorName,
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
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
    );
  }
}
