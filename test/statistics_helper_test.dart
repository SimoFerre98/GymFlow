import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/utils/statistics_helper.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/workout.dart';

/// Costruisce una sessione con un solo esercizio e le serie indicate.
WorkoutSession _session(DateTime start, {List<WorkoutSet> sets = const []}) {
  return WorkoutSession(
    id: 's-${start.microsecondsSinceEpoch}',
    userId: 'u1',
    workoutTemplateId: 't1',
    workoutName: 'Test',
    startTime: start,
    exercises: [
      WorkoutExercise(exerciseId: 'e1', exerciseName: 'Panca', sets: sets),
    ],
  );
}

void main() {
  final today = DateTime.now();
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  group('calculateCurrentStreak', () {
    test('senza sessioni la serie e zero', () {
      expect(StatisticsHelper.calculateCurrentStreak([]), 0);
    });

    test('un allenamento oggi vale una serie di un giorno', () {
      expect(StatisticsHelper.calculateCurrentStreak([_session(today)]), 1);
    });

    test('giorni consecutivi si sommano', () {
      final sessions = [_session(today), _session(daysAgo(1)), _session(daysAgo(2))];
      expect(StatisticsHelper.calculateCurrentStreak(sessions), 3);
    });

    test('due allenamenti nello stesso giorno contano una volta sola', () {
      final sessions = [
        _session(today),
        _session(today.subtract(const Duration(hours: 3))),
        _session(daysAgo(1)),
      ];
      expect(StatisticsHelper.calculateCurrentStreak(sessions), 2);
    });

    test('un giorno saltato interrompe la serie', () {
      final sessions = [_session(today), _session(daysAgo(2)), _session(daysAgo(3))];
      expect(StatisticsHelper.calculateCurrentStreak(sessions), 1);
    });

    test('la serie resta viva se l ultimo allenamento e di ieri', () {
      expect(StatisticsHelper.calculateCurrentStreak([_session(daysAgo(1))]), 1);
    });

    test('la serie e interrotta se l ultimo allenamento e piu vecchio di ieri', () {
      expect(StatisticsHelper.calculateCurrentStreak([_session(daysAgo(5))]), 0);
    });
  });

  group('calculateTotalVolume', () {
    test('senza sessioni il volume e zero', () {
      expect(StatisticsHelper.calculateTotalVolume([]), 0);
    });

    test('somma peso per ripetizioni delle serie completate', () {
      final sessions = [
        _session(today, sets: [
          WorkoutSet(weight: 50, reps: 10, isCompleted: true),
          WorkoutSet(weight: 60, reps: 5, isCompleted: true),
        ]),
      ];
      expect(StatisticsHelper.calculateTotalVolume(sessions), 800);
    });

    test('le serie non completate sono escluse', () {
      final sessions = [
        _session(today, sets: [
          WorkoutSet(weight: 50, reps: 10, isCompleted: true),
          WorkoutSet(weight: 100, reps: 10, isCompleted: false),
        ]),
      ];
      expect(StatisticsHelper.calculateTotalVolume(sessions), 500);
    });

    test('i mezzi chili non si perdono a ogni serie', () {
      // E il test che mancava, e la ragione per cui il difetto e vissuto a lungo:
      // tutti gli altri usano pesi interi, dove il troncamento non si vede.
      //
      // Il passo dei cursori di US-046 e 2,5 kg, quindi i mezzi chili sono la
      // norma. Tre serie da 62,5 x 3 fanno 562,5 esatti: troncando **a ogni
      // serie** si otteneva 187 x 3 = 561, sempre verso il basso e sempre di
      // piu al crescere dello storico.
      final sessions = [
        _session(today, sets: [
          WorkoutSet(weight: 62.5, reps: 3, isCompleted: true),
          WorkoutSet(weight: 62.5, reps: 3, isCompleted: true),
          WorkoutSet(weight: 62.5, reps: 3, isCompleted: true),
        ]),
      ];
      expect(
        StatisticsHelper.calculateTotalVolume(sessions),
        563,
        reason: '562,5 arrotondato una volta sola, non 561 troncato tre volte',
      );
    });

    test('un solo mezzo chilo si arrotonda alla fine, non si butta', () {
      final sessions = [
        _session(today, sets: [
          WorkoutSet(weight: 2.5, reps: 3, isCompleted: true),
        ]),
      ];
      // 7,5 -> 8. Troncando faceva 7.
      expect(StatisticsHelper.calculateTotalVolume(sessions), 8);
    });
  });

  group('calculateAverageRPE', () {
    test('senza valori la media e zero', () {
      expect(StatisticsHelper.calculateAverageRPE([]), 0.0);
    });

    test('media dei valori presenti', () {
      final sessions = [
        _session(today, sets: [
          WorkoutSet(weight: 50, reps: 10, rpe: 6),
          WorkoutSet(weight: 50, reps: 10, rpe: 8),
        ]),
      ];
      expect(StatisticsHelper.calculateAverageRPE(sessions), 7.0);
    });

    test('le serie senza RPE non abbassano la media', () {
      final sessions = [
        _session(today, sets: [
          WorkoutSet(weight: 50, reps: 10, rpe: 8),
          WorkoutSet(weight: 50, reps: 10),
        ]),
      ];
      expect(StatisticsHelper.calculateAverageRPE(sessions), 8.0);
    });
  });

  group('getWorkoutTypeDistribution', () {
    test('senza sessioni la distribuzione e vuota', () {
      expect(StatisticsHelper.getWorkoutTypeDistribution([]), isEmpty);
    });

    test('conta le sessioni per tipo con iniziale maiuscola', () {
      final sessions = [_session(today), _session(daysAgo(1))];
      expect(StatisticsHelper.getWorkoutTypeDistribution(sessions), {'Strength': 2});
    });
  });
}
