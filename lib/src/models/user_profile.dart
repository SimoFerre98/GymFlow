class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final double? weight;
  final double? height; // in cm
  final String? profileImageUrl;
  final DateTime createdAt;
  final int streakDays;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.weight,
    this.height,
    this.profileImageUrl,
    required this.createdAt,
    this.streakDays = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'weight': weight,
      'height': height,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'streakDays': streakDays,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfile(
      id: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'User',
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      streakDays: map['streakDays'] ?? 0,
    );
  }
}
