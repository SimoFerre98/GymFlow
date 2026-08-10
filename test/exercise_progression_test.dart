import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/utils/exercise_progression.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/workout.dart';

void main() {
  final now = DateTime(2026, 8, 10, 12, 0);

  WorkoutSession createSession({
    required String id,
    required DateTime startTime,
    required String exerciseId,
    required List<WorkoutSet> sets,
  }) {
    return WorkoutSession(
      id: id,
      userId: 'user1',
      workoutTemplateId: 'template1',
      workoutName: 'Workout $id',
      startTime: startTime,
      exercises: [
        WorkoutExercise(
          exerciseId: exerciseId,
          exerciseName: 'Bench Press',
          sets: sets,
        ),
      ],
    );
  }

  group('ExerciseProgression.calculateProgressionPoints', () {
    test('il grafico riporta l\'andamento del massimo per sessione, non la somma o la media', () {
      final sessions = [
        createSession(
          id: 's1',
          startTime: now.subtract(const Duration(days: 10)),
          exerciseId: 'bench',
          sets: [
            WorkoutSet(weight: 50.0, reps: 10, isCompleted: true),
            WorkoutSet(weight: 60.0, reps: 8, isCompleted: true),
            WorkoutSet(weight: 55.0, reps: 10, isCompleted: true),
          ],
        ),
        createSession(
          id: 's2',
          startTime: now.subtract(const Duration(days: 5)),
          exerciseId: 'bench',
          sets: [
            WorkoutSet(weight: 65.0, reps: 5, isCompleted: true),
            WorkoutSet(weight: 70.0, reps: 3, isCompleted: true),
          ],
        ),
        createSession(
          id: 's3',
          startTime: now.subtract(const Duration(days: 1)),
          exerciseId: 'bench',
          sets: [
            WorkoutSet(weight: 75.0, reps: 2, isCompleted: true),
          ],
        ),
      ];

      final points = ExerciseProgression.calculateProgressionPoints(
        sessions: sessions,
        exerciseId: 'bench',
        period: ProgressionPeriod.all,
        referenceDate: now,
      );

      expect(points.length, 3);
      expect(points[0].weight, 60.0);
      expect(points[1].weight, 70.0);
      expect(points[2].weight, 75.0);
    });

    test('solo le serie completate contano', () {
      final sessions = [
        createSession(
          id: 's1',
          startTime: now.subtract(const Duration(days: 2)),
          exerciseId: 'bench',
          sets: [
            WorkoutSet(weight: 60.0, reps: 8, isCompleted: true),
            WorkoutSet(weight: 120.0, reps: 10, isCompleted: false), // Non completata
          ],
        ),
      ];

      final points = ExerciseProgression.calculateProgressionPoints(
        sessions: sessions,
        exerciseId: 'bench',
        period: ProgressionPeriod.all,
        referenceDate: now,
      );

      expect(points.length, 1);
      expect(points[0].weight, 60.0);
    });

    test('i mezzi chili sopravvivono (test obbligatorio con 62.5 kg)', () {
      final sessions = [
        createSession(
          id: 's1',
          startTime: now.subtract(const Duration(days: 2)),
          exerciseId: 'bench',
          sets: [
            WorkoutSet(weight: 62.5, reps: 8, isCompleted: true),
          ],
        ),
      ];

      final points = ExerciseProgression.calculateProgressionPoints(
        sessions: sessions,
        exerciseId: 'bench',
        period: ProgressionPeriod.all,
        referenceDate: now,
      );

      expect(points.length, 1);
      expect(points[0].weight, 62.5);
    });

    test('il periodo filtra correttamente le sessioni vecchie', () {
      final sessions = [
        createSession(
          id: 's_old',
          startTime: now.subtract(const Duration(days: 40)), // Oltre 30 giorni
          exerciseId: 'bench',
          sets: [WorkoutSet(weight: 50.0, reps: 10, isCompleted: true)],
        ),
        createSession(
          id: 's_recent',
          startTime: now.subtract(const Duration(days: 10)), // Entro 30 giorni
          exerciseId: 'bench',
          sets: [WorkoutSet(weight: 60.0, reps: 8, isCompleted: true)],
        ),
      ];

      final points1M = ExerciseProgression.calculateProgressionPoints(
        sessions: sessions,
        exerciseId: 'bench',
        period: ProgressionPeriod.oneMonth,
        referenceDate: now,
      );

      expect(points1M.length, 1);
      expect(points1M[0].sessionId, 's_recent');

      final pointsAll = ExerciseProgression.calculateProgressionPoints(
        sessions: sessions,
        exerciseId: 'bench',
        period: ProgressionPeriod.all,
        referenceDate: now,
      );

      expect(pointsAll.length, 2);
    });

    test('senza storico restituisce un elenco vuoto', () {
      final points = ExerciseProgression.calculateProgressionPoints(
        sessions: [],
        exerciseId: 'bench',
        period: ProgressionPeriod.all,
        referenceDate: now,
      );

      expect(points, isEmpty);
    });
  });

  group('ExerciseProgression.getLastSession & getLastExerciseData', () {
    test('estrae l\'ultima sessione in ordine temporale decrescente', () {
      final s1 = createSession(
        id: 's1',
        startTime: now.subtract(const Duration(days: 5)),
        exerciseId: 'bench',
        sets: [WorkoutSet(weight: 50.0, reps: 10, isCompleted: true)],
      );
      final s2 = createSession(
        id: 's2',
        startTime: now.subtract(const Duration(days: 1)),
        exerciseId: 'bench',
        sets: [WorkoutSet(weight: 65.0, reps: 8, isCompleted: true)],
      );

      final last = ExerciseProgression.getLastSession(
        sessions: [s1, s2],
        exerciseId: 'bench',
      );

      expect(last, isNotNull);
      expect(last!.id, 's2');

      final exData = ExerciseProgression.getLastExerciseData(
        session: last,
        exerciseId: 'bench',
      );
      expect(exData, isNotNull);
      expect(exData!.sets.first.weight, 65.0);
    });
  });
}
