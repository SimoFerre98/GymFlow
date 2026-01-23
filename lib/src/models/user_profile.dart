class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final double? weight;
  final double? height; // in cm
  final String? photoUrl;
  final DateTime createdAt;
  final int streakDays;
  final String? gymName;
  final String? gymAddress;
  final double? gymLat;
  final double? gymLng;
  final DateTime? subscriptionExpiry;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.weight,
    this.height,
    this.photoUrl,
    required this.createdAt,
    this.streakDays = 0,
    this.gymName,
    this.gymAddress,
    this.gymLat,
    this.gymLng,
    this.subscriptionExpiry,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'weight': weight,
      'height': height,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'streakDays': streakDays,
      'gymName': gymName,
      'gymAddress': gymAddress,
      'gymLat': gymLat,
      'gymLng': gymLng,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfile(
      id: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'User',
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      photoUrl: map['photoUrl'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      streakDays: map['streakDays'] ?? 0,
      gymName: map['gymName'],
      gymAddress: map['gymAddress'],
      gymLat: map['gymLat']?.toDouble(),
      gymLng: map['gymLng']?.toDouble(),
      subscriptionExpiry: map['subscriptionExpiry'] != null
          ? DateTime.tryParse(map['subscriptionExpiry'])
          : null,
    );
  }
}
