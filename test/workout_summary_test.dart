import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/utils/workout_summary.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/workout.dart';

void main() {
  group('WorkoutSummary.of', () {
    test('calcola volume, serie, sforzo medio e durata su sessione completa', () {
      final startTime = DateTime(2026, 8, 6, 10, 0);
      final endTime = DateTime(2026, 8, 6, 10, 48);

      final session = WorkoutSession(
        id: 's1',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Spinte',
        startTime: startTime,
        endTime: endTime,
        exercises: [
          WorkoutExercise(
            exerciseId: 'e1',
            exerciseName: 'Panca piana',
            type: ExerciseType.strength,
            sets: [
              WorkoutSet(weight: 60, reps: 10, rpe: 7.0, isCompleted: true),
              WorkoutSet(weight: 60, reps: 10, rpe: 8.0, isCompleted: true),
            ],
          ),
          WorkoutExercise(
            exerciseId: 'e2',
            exerciseName: 'Croci manubri',
            type: ExerciseType.strength,
            sets: [
              WorkoutSet(weight: 15, reps: 12, rpe: 7.5, isCompleted: true),
            ],
          ),
        ],
      );

      final summary = WorkoutSummary.of(
        session,
        calories: 412,
        avgHeartRate: 131,
      );

      expect(summary.workoutName, 'Spinte');
      expect(summary.durationMinutes, 48);
      // Volume: (60*10) + (60*10) + (15*12) = 600 + 600 + 180 = 1380
      expect(summary.totalVolume, 1380);
      expect(summary.completedSets, 3);
      expect(summary.totalSets, 3);
      // RPE medio: (7.0 + 8.0 + 7.5) / 3 = 7.5
      expect(summary.averageRpe, closeTo(7.5, 0.01));
      expect(summary.calories, 412);
      expect(summary.avgHeartRate, 131);
    });

    test('interrompendo a meta, le serie non completate non entrano nel volume ma sono nel totale', () {
      final startTime = DateTime(2026, 8, 6, 10, 0);
      final endTime = DateTime(2026, 8, 6, 10, 30);

      final session = WorkoutSession(
        id: 's2',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Spinte',
        startTime: startTime,
        endTime: endTime,
        exercises: [
          WorkoutExercise(
            exerciseId: 'e1',
            exerciseName: 'Panca piana',
            sets: [
              WorkoutSet(weight: 60, reps: 10, isCompleted: true),
              WorkoutSet(weight: 60, reps: 10, isCompleted: true),
              WorkoutSet(weight: 60, reps: 10, isCompleted: false), // non completata
            ],
          ),
          WorkoutExercise(
            exerciseId: 'e2',
            exerciseName: 'Spinte manubri',
            sets: [
              WorkoutSet(weight: 20, reps: 10, isCompleted: false), // non completata
            ],
          ),
        ],
      );

      final summary = WorkoutSummary.of(session);

      // Solo le due completate contano nel volume: 600 + 600 = 1200
      expect(summary.totalVolume, 1200);
      expect(summary.completedSets, 2);
      expect(summary.totalSets, 4);
    });

    test('le serie senza RPE non abbassano la media', () {
      final session = WorkoutSession(
        id: 's3',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Gambe',
        startTime: DateTime.now(),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e1',
            exerciseName: 'Squat',
            sets: [
              WorkoutSet(weight: 100, reps: 5, rpe: 8.0, isCompleted: true),
              WorkoutSet(weight: 100, reps: 5, isCompleted: true), // nessun RPE
              WorkoutSet(weight: 100, reps: 5, rpe: 9.0, isCompleted: true),
            ],
          ),
        ],
      );

      final summary = WorkoutSummary.of(session);

      // Media solo tra 8.0 e 9.0 = 8.5
      expect(summary.averageRpe, closeTo(8.5, 0.01));
    });

    test('senza alcun RPE registrato, averageRpe e null', () {
      final session = WorkoutSession(
        id: 's4',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Braccia',
        startTime: DateTime.now(),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e1',
            exerciseName: 'Curl bicipiti',
            sets: [
              WorkoutSet(weight: 14, reps: 10, isCompleted: true),
            ],
          ),
        ],
      );

      final summary = WorkoutSummary.of(session);
      expect(summary.averageRpe, isNull);
    });

    test('calorie e battito assenti o zero risultano null, non zero', () {
      final session = WorkoutSession(
        id: 's5',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Dorso',
        startTime: DateTime.now(),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e1',
            exerciseName: 'Trazioni',
            sets: [
              WorkoutSet(weight: 0, reps: 8, isCompleted: true),
            ],
          ),
        ],
      );

      final summary = WorkoutSummary.of(session, calories: 0, avgHeartRate: 0);

      expect(summary.calories, isNull);
      expect(summary.avgHeartRate, isNull);
    });

    test('calorie nei set vengono sommate se non passate esplicitamente', () {
      final session = WorkoutSession(
        id: 's6',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Cardio Mix',
        startTime: DateTime.now(),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e1',
            exerciseName: 'Cyclette',
            sets: [
              WorkoutSet(calories: 120.5, isCompleted: true),
              WorkoutSet(calories: 130.5, isCompleted: true),
            ],
          ),
        ],
      );

      final summary = WorkoutSummary.of(session);
      expect(summary.calories, 251);
    });

    test('i mezzi chili non si perdono: 62,5 per 7 vale 437,5 e non 437', () {
      // Con `toInt()` a ogni serie si troncava: su tre serie si perdevano
      // 1,5 kg. Il passo da 2,5 kg di US-046 rende i decimali la norma.
      final session = WorkoutSession(
        id: 's6',
        userId: 'u1',
        workoutTemplateId: 't6',
        workoutName: 'Panca',
        startTime: DateTime(2026, 8, 6, 9, 0),
        endTime: DateTime(2026, 8, 6, 10, 0),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e1',
            exerciseName: 'Panca piana',
            type: ExerciseType.strength,
            sets: [
              WorkoutSet(weight: 62.5, reps: 7, isCompleted: true),
              WorkoutSet(weight: 62.5, reps: 7, isCompleted: true),
              WorkoutSet(weight: 62.5, reps: 7, isCompleted: true),
            ],
          ),
        ],
      );

      final summary = WorkoutSummary.of(session);

      // 437,5 x 3 = 1312,5 -> 1313 arrotondato una volta sola.
      // Troncando a ogni serie sarebbero stati 1311.
      expect(summary.totalVolume, 1313);
    });

    test('sessione vuota non fallisce e riporta zeri e null coerenti', () {
      final session = WorkoutSession(
        id: 's7',
        userId: 'u1',
        workoutTemplateId: '',
        workoutName: '',
        startTime: DateTime.now(),
        exercises: [],
      );

      final summary = WorkoutSummary.of(session);

      // Il ripiego non sta piu qui: il modello non conosce la lingua, e il
      // nome mancante lo risolve il widget con una chiave tradotta.
      expect(summary.workoutName, isEmpty);
      expect(summary.totalVolume, 0);
      expect(summary.completedSets, 0);
      expect(summary.totalSets, 0);
      expect(summary.averageRpe, isNull);
      expect(summary.calories, isNull);
      expect(summary.avgHeartRate, isNull);
      expect(summary.durationMinutes, 0);
    });
  });
}
