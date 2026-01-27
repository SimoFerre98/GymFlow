class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? firstName;
  final String? lastName;

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

  final DateTime? birthDate;
  final String? gender; // 'male', 'female', 'other'
  final String? friendCode;
  final List<String> friends;
  final List<String> calendarSharedWith;
  final List<String> programsSharedWith;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.friendCode,
    this.friends = const [],
    this.calendarSharedWith = const [],
    this.programsSharedWith = const [],
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
    this.birthDate,
    this.gender,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'friendCode': friendCode,
      'friends': friends,
      'calendarSharedWith': calendarSharedWith,
      'programsSharedWith': programsSharedWith,
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
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfile(
      id: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'User',
      firstName: map['firstName'],
      lastName: map['lastName'],
      friendCode: map['friendCode'],
      friends: List<String>.from(map['friends'] ?? []),
      calendarSharedWith: List<String>.from(map['calendarSharedWith'] ?? []),
      programsSharedWith: List<String>.from(map['programsSharedWith'] ?? []),
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
      birthDate: map['birthDate'] != null
          ? DateTime.tryParse(map['birthDate'])
          : null,
      gender: map['gender'],
    );
  }
}
