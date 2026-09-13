import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/invite.dart';

void main() {
  Invite makeFullInvite() {
    return Invite(
      id: 'inv-abc-123',
      fromUserId: 'user-42',
      fromDisplayName: 'Alice',
      fromRole: 'trainer',
      toUserId: 'user-99',
      toDisplayName: 'Bruno',
      code: 'ABC123',
      relationshipType: RelationshipType.trainerClient,
      status: InviteStatus.accepted,
      createdAt: DateTime.utc(2026, 9, 1, 10, 0),
      expiresAt: DateTime.utc(2026, 9, 8, 10, 0),
      respondedAt: DateTime.utc(2026, 9, 2, 12, 30),
    );
  }

  group('Domain → Map → Domain round-trip', () {
    test('invito completo: tutti i campi sopravvivono', () {
      final original = makeFullInvite();
      final restored = Invite.fromMap(original.toMap(), original.id);

      expect(restored.id, equals(original.id));
      expect(restored.fromUserId, equals(original.fromUserId));
      expect(restored.fromDisplayName, equals(original.fromDisplayName));
      expect(restored.fromRole, equals(original.fromRole));
      expect(restored.toUserId, equals(original.toUserId));
      expect(restored.toDisplayName, equals(original.toDisplayName));
      expect(restored.code, equals(original.code));
      expect(restored.relationshipType, equals(original.relationshipType));
      expect(restored.status, equals(original.status));
      // Timestamp.toDate() (cloud_firestore) restituisce sempre un DateTime
      // locale, mai UTC: confrontare lo stesso istante con .toUtc() invece
      // di un'uguaglianza diretta, che in Dart considera diversi un istante
      // UTC e lo stesso istante in locale (isAtSameMomentAs sì, == no).
      expect(restored.createdAt.toUtc(), equals(original.createdAt.toUtc()));
      expect(restored.expiresAt.toUtc(), equals(original.expiresAt.toUtc()));
      expect(restored.respondedAt?.toUtc(), equals(original.respondedAt?.toUtc()));
    });

    test('invito appena creato: respondedAt nullo, in sospeso', () {
      final original = Invite(
        id: 'inv-min',
        fromUserId: 'u1',
        fromDisplayName: 'Carla',
        fromRole: 'athlete',
        toUserId: 'u2',
        toDisplayName: 'Dario',
        code: 'XYZ999',
        relationshipType: RelationshipType.friend,
        status: InviteStatus.pending,
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 8),
      );
      final restored = Invite.fromMap(original.toMap(), original.id);

      expect(restored.respondedAt, isNull);
      expect(restored.status, equals(InviteStatus.pending));
      expect(restored.relationshipType, equals(RelationshipType.friend));
    });

    test('ogni InviteStatus sopravvive al round-trip', () {
      for (final status in InviteStatus.values) {
        final invite = Invite(
          id: 'status-${status.name}',
          fromUserId: 'u1',
          fromDisplayName: 'A',
          fromRole: 'athlete',
          toUserId: 'u2',
          toDisplayName: 'B',
          code: 'CODE01',
          relationshipType: RelationshipType.friend,
          status: status,
          createdAt: DateTime.utc(2026, 1, 1),
          expiresAt: DateTime.utc(2026, 1, 8),
        );
        final restored = Invite.fromMap(invite.toMap(), invite.id);
        expect(restored.status, equals(status),
            reason: 'InviteStatus.${status.name} deve sopravvivere');
      }
    });

    test('ogni RelationshipType sopravvive al round-trip', () {
      for (final type in RelationshipType.values) {
        final invite = Invite(
          id: 'type-${type.name}',
          fromUserId: 'u1',
          fromDisplayName: 'A',
          fromRole: 'athlete',
          toUserId: 'u2',
          toDisplayName: 'B',
          code: 'CODE01',
          relationshipType: type,
          status: InviteStatus.pending,
          createdAt: DateTime.utc(2026, 1, 1),
          expiresAt: DateTime.utc(2026, 1, 8),
        );
        final restored = Invite.fromMap(invite.toMap(), invite.id);
        expect(restored.relationshipType, equals(type),
            reason: 'RelationshipType.${type.name} deve sopravvivere');
      }
    });
  });

  group('isExpired', () {
    test('un invito pending con scadenza nel passato è scaduto', () {
      final invite = Invite(
        id: 'i',
        fromUserId: 'u1',
        fromDisplayName: 'A',
        fromRole: 'athlete',
        toUserId: 'u2',
        toDisplayName: 'B',
        code: 'CODE01',
        relationshipType: RelationshipType.friend,
        status: InviteStatus.pending,
        createdAt: DateTime.utc(2020, 1, 1),
        expiresAt: DateTime.utc(2020, 1, 8),
      );
      expect(invite.isExpired, isTrue);
    });

    test('un invito pending con scadenza futura non è scaduto', () {
      final invite = Invite(
        id: 'i',
        fromUserId: 'u1',
        fromDisplayName: 'A',
        fromRole: 'athlete',
        toUserId: 'u2',
        toDisplayName: 'B',
        code: 'CODE01',
        relationshipType: RelationshipType.friend,
        status: InviteStatus.pending,
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2100, 1, 8),
      );
      expect(invite.isExpired, isFalse);
    });

    test('un invito già accettato non è mai "scaduto", anche con expiresAt nel passato', () {
      final invite = Invite(
        id: 'i',
        fromUserId: 'u1',
        fromDisplayName: 'A',
        fromRole: 'athlete',
        toUserId: 'u2',
        toDisplayName: 'B',
        code: 'CODE01',
        relationshipType: RelationshipType.friend,
        status: InviteStatus.accepted,
        createdAt: DateTime.utc(2020, 1, 1),
        expiresAt: DateTime.utc(2020, 1, 8),
      );
      expect(invite.isExpired, isFalse);
    });
  });
}
