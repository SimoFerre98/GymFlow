import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/user_profile.dart';

void main() {
  group('US-086: UserRole enum & helpers', () {
    test('athlete ha isAthlete true e isTrainer false', () {
      const role = UserRole.athlete;
      expect(role.isAthlete, isTrue);
      expect(role.isTrainer, isFalse);
      expect(role.toMap(), 'athlete');
    });

    test('trainer ha isAthlete false e isTrainer true', () {
      const role = UserRole.trainer;
      expect(role.isAthlete, isFalse);
      expect(role.isTrainer, isTrue);
      expect(role.toMap(), 'trainer');
    });

    test('both ha sia isAthlete sia isTrainer true', () {
      const role = UserRole.both;
      expect(role.isAthlete, isTrue);
      expect(role.isTrainer, isTrue);
      expect(role.toMap(), 'both');
    });

    test('fromMap gestisce stringhe maiuscole/minuscole', () {
      expect(UserRole.fromMap('TRAINER'), UserRole.trainer);
      expect(UserRole.fromMap('Both'), UserRole.both);
      expect(UserRole.fromMap('athlete'), UserRole.athlete);
    });

    test('fromMap con valori null o non validi fa fallback su athlete', () {
      expect(UserRole.fromMap(null), UserRole.athlete);
      expect(UserRole.fromMap('ruolo_sconosciuto'), UserRole.athlete);
      expect(UserRole.fromMap(123), UserRole.athlete);
    });
  });

  group('US-086: UserProfile ruolo e retrocompatibilità dati storici', () {
    test('un profilo storico senza campo role viene letto come athlete (default)', () {
      final oldData = {
        'email': 'atleta@example.com',
        'displayName': 'Mario Rossi',
        'firstName': 'Mario',
        'lastName': 'Rossi',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'streakDays': 5,
      };

      final profile = UserProfile.fromMap(oldData, 'user-123');
      expect(profile.role, UserRole.athlete);
      expect(profile.role.isAthlete, isTrue);
      expect(profile.role.isTrainer, isFalse);
    });

    test('un profilo salvato con ruolo trainer o both viene deserializzato correttamente', () {
      final trainerData = {
        'email': 'trainer@example.com',
        'displayName': 'Coach Alex',
        'role': 'trainer',
        'createdAt': '2026-02-01T10:00:00.000Z',
      };

      final profileTrainer = UserProfile.fromMap(trainerData, 'user-456');
      expect(profileTrainer.role, UserRole.trainer);
      expect(profileTrainer.role.isTrainer, isTrue);

      final bothData = {
        'email': 'both@example.com',
        'displayName': 'Coach & Athlete',
        'role': 'both',
        'createdAt': '2026-02-01T10:00:00.000Z',
      };

      final profileBoth = UserProfile.fromMap(bothData, 'user-789');
      expect(profileBoth.role, UserRole.both);
      expect(profileBoth.role.isAthlete, isTrue);
      expect(profileBoth.role.isTrainer, isTrue);
    });

    test('toMap include il ruolo come stringa', () {
      final profile = UserProfile(
        id: 'u1',
        email: 'test@gymflow.com',
        displayName: 'Test',
        role: UserRole.trainer,
        createdAt: DateTime(2026, 1, 1),
      );

      final map = profile.toMap();
      expect(map['role'], 'trainer');
    });

    test('copyWith consente di cambiare il ruolo mantenendo invariati gli altri campi', () {
      final profile = UserProfile(
        id: 'u1',
        email: 'test@gymflow.com',
        displayName: 'Test',
        firstName: 'Nome',
        lastName: 'Cognome',
        role: UserRole.athlete,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = profile.copyWith(role: UserRole.both);
      expect(updated.role, UserRole.both);
      expect(updated.displayName, 'Test');
      expect(updated.firstName, 'Nome');
      expect(updated.lastName, 'Cognome');
    });
  });
}
