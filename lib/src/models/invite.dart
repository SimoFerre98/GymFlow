import 'package:cloud_firestore/cloud_firestore.dart';
enum InviteStatus {
  pending,
  accepted,
  declined,
  revoked;
  String toMap() => name;
  static InviteStatus fromMap(dynamic value) {
    if (value is String) {
      for (final status in InviteStatus.values) {
        if (status.name == value) return status;
      }
    }
    return InviteStatus.pending;
  }
}
enum RelationshipType {
  friend,
  trainerClient;
  String toMap() => switch (this) {
    RelationshipType.friend => 'friend',
    RelationshipType.trainerClient => 'trainer_client',
  };
  static RelationshipType fromMap(dynamic value) {
    if (value == 'trainer_client') return RelationshipType.trainerClient;
    return RelationshipType.friend;
  }
}
/// Il patto fra due utenti (US-087): nasce da chi invita, vive qui — non sul
/// documento utente di nessuno dei due — e solo chi lo riceve puo accettarlo.
/// Regge sia l'amico per codice sia il legame trainer→cliente, con lo stesso
/// meccanismo (`relationshipType` distingue solo come mostrarlo a schermo).
class Invite {
  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String fromRole;
  final String toUserId;
  final String toDisplayName;
  final String code;
  final RelationshipType relationshipType;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  const Invite({
    required this.id,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.fromRole,
    required this.toUserId,
    required this.toDisplayName,
    required this.code,
    required this.relationshipType,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
  });
  bool get isExpired => status == InviteStatus.pending && DateTime.now().isAfter(expiresAt);
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromDisplayName': fromDisplayName,
      'fromRole': fromRole,
      'toUserId': toUserId,
      'toDisplayName': toDisplayName,
      'code': code,
      'relationshipType': relationshipType.toMap(),
      'status': status.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }
  factory Invite.fromMap(Map<String, dynamic> map, String id) {
    return Invite(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      fromDisplayName: map['fromDisplayName'] ?? '',
      fromRole: map['fromRole'] ?? 'athlete',
      toUserId: map['toUserId'] ?? '',
      toDisplayName: map['toDisplayName'] ?? '',
      code: map['code'] ?? '',
      relationshipType: RelationshipType.fromMap(map['relationshipType']),
      status: InviteStatus.fromMap(map['status']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
    );
  }
}
