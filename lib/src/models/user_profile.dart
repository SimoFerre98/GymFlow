enum UserRole {
  athlete,
  trainer,
  both;

  String toMap() => name;

  static UserRole fromMap(dynamic value) {
    if (value is String) {
      for (final role in UserRole.values) {
        if (role.name.toLowerCase() == value.toLowerCase()) {
          return role;
        }
      }
    }
    return UserRole.athlete;
  }

  bool get isTrainer => this == UserRole.trainer || this == UserRole.both;
  bool get isAthlete => this == UserRole.athlete || this == UserRole.both;
}

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final UserRole role;

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
    this.role = UserRole.athlete,
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
      'role': role.toMap(),
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
      role: UserRole.fromMap(map['role']),
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
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    UserRole? role,
    double? weight,
    double? height,
    String? photoUrl,
    DateTime? createdAt,
    int? streakDays,
    String? gymName,
    String? gymAddress,
    double? gymLat,
    double? gymLng,
    DateTime? subscriptionExpiry,
    DateTime? birthDate,
    String? gender,
    String? friendCode,
    List<String>? friends,
    List<String>? calendarSharedWith,
    List<String>? programsSharedWith,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      streakDays: streakDays ?? this.streakDays,
      gymName: gymName ?? this.gymName,
      gymAddress: gymAddress ?? this.gymAddress,
      gymLat: gymLat ?? this.gymLat,
      gymLng: gymLng ?? this.gymLng,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      friendCode: friendCode ?? this.friendCode,
      friends: friends ?? this.friends,
      calendarSharedWith: calendarSharedWith ?? this.calendarSharedWith,
      programsSharedWith: programsSharedWith ?? this.programsSharedWith,
    );
  }
}
