import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/utils/program_timeline.dart';
import 'package:gymflow/src/models/workout_program.dart';

WorkoutProgram scheda({DateTime? inizio, DateTime? fine}) => WorkoutProgram(
  id: 'p1',
  userId: 'u1',
  name: 'Forza',
  workoutIds: const [],
  createdAt: DateTime(2026, 1, 1),
  startDate: inizio,
  endDate: fine,
);

void main() {
  // Lunedi 5 ottobre 2026 -> domenica 29 novembre 2026: 8 settimane esatte.
  final inizio = DateTime(2026, 10, 5);
  final fine = DateTime(2026, 11, 29);

  group('senza date', () {
    test('senza inizio non c e una settimana da contare', () {
      final t = programTimeline(scheda(), DateTime(2026, 10, 18));
      expect(t.phase, ProgramPhase.undated);
      expect(t.week, isNull);
      expect(t.progress, isNull);
    });

    test('con la sola data di fine resta senza date: non si inventa l inizio', () {
      final t = programTimeline(scheda(fine: fine), DateTime(2026, 10, 18));
      expect(t.phase, ProgramPhase.undated);
    });
  });

  group('prima dell inizio', () {
    test('conta i giorni che mancano', () {
      final t = programTimeline(scheda(inizio: inizio, fine: fine), DateTime(2026, 9, 28));
      expect(t.phase, ProgramPhase.upcoming);
      expect(t.daysToStart, 7);
      expect(t.week, isNull);
    });

    test('la sera prima manca un giorno', () {
      final t = programTimeline(scheda(inizio: inizio), DateTime(2026, 10, 4, 23, 59));
      expect(t.phase, ProgramPhase.upcoming);
      expect(t.daysToStart, 1);
    });
  });

  group('in corso', () {
    test('il giorno stesso dell inizio e gia la settimana 1', () {
      final t = programTimeline(scheda(inizio: inizio, fine: fine), DateTime(2026, 10, 5, 0, 1));
      expect(t.phase, ProgramPhase.running);
      expect(t.week, 1);
      expect(t.totalWeeks, 8);
    });

    test('la settimana cambia dopo sette giorni, non prima', () {
      expect(
        programTimeline(scheda(inizio: inizio, fine: fine), DateTime(2026, 10, 11)).week,
        1,
        reason: 'domenica e ancora la settimana 1',
      );
      expect(
        programTimeline(scheda(inizio: inizio, fine: fine), DateTime(2026, 10, 12)).week,
        2,
        reason: 'lunedi successivo e la settimana 2',
      );
    });

    test('a meta percorso, 3 settimane su 8', () {
      final t = programTimeline(scheda(inizio: inizio, fine: fine), DateTime(2026, 10, 20));
      expect(t.week, 3);
      expect(t.totalWeeks, 8);
      expect(t.progress, closeTo(3 / 8, 1e-9));
    });

    test('l ultimo giorno e la settimana 8 su 8, non conclusa', () {
      final t = programTimeline(scheda(inizio: inizio, fine: fine), DateTime(2026, 11, 29, 23, 0));
      expect(t.phase, ProgramPhase.running);
      expect(t.week, 8);
      expect(t.progress, 1.0);
    });

    test('senza data di fine conta le settimane ma non ha un totale', () {
      final t = programTimeline(scheda(inizio: inizio), DateTime(2026, 10, 20));
      expect(t.phase, ProgramPhase.running);
      expect(t.week, 3);
      expect(t.totalWeeks, isNull);
      expect(t.progress, isNull);
    });

    test('una fine a meta settimana arrotonda per eccesso', () {
      // 5 -> 12 ottobre inclusi: 8 giorni = 2 settimane.
      final t = programTimeline(
        scheda(inizio: inizio, fine: DateTime(2026, 10, 12)),
        DateTime(2026, 10, 6),
      );
      expect(t.totalWeeks, 2);
    });
  });

  group('finita', () {
    test('il giorno dopo la fine e conclusa', () {
      final t = programTimeline(scheda(inizio: inizio, fine: fine), DateTime(2026, 11, 30));
      expect(t.phase, ProgramPhase.ended);
      expect(t.totalWeeks, 8);
      expect(t.week, isNull);
    });
  });

  group('dati sbagliati', () {
    test('una fine precedente all inizio non fa dichiarare la scheda conclusa', () {
      final t = programTimeline(
        scheda(inizio: inizio, fine: DateTime(2026, 9, 1)),
        DateTime(2026, 10, 20),
      );
      expect(t.phase, ProgramPhase.running);
      expect(t.totalWeeks, isNull);
      expect(t.week, 3);
    });

    test('inizio e fine nello stesso giorno: una settimana', () {
      final t = programTimeline(
        scheda(inizio: inizio, fine: inizio),
        DateTime(2026, 10, 5, 12),
      );
      expect(t.phase, ProgramPhase.running);
      expect(t.week, 1);
      expect(t.totalWeeks, 1);
    });
  });

  group('ora legale', () {
    test('il passaggio all ora solare non sposta la settimana', () {
      // Il 25 ottobre 2026 si torna all'ora solare: un giorno di 25 ore.
      final t = programTimeline(
        scheda(inizio: DateTime(2026, 10, 19), fine: DateTime(2026, 12, 13)),
        DateTime(2026, 10, 26),
      );
      expect(t.week, 2, reason: 'sette giorni dopo l inizio, a prescindere dalle ore');
    });
  });
}
