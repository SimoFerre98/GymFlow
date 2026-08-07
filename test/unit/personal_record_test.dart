import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/utils/personal_record.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/workout.dart';

void main() {
  group('PersonalRecord.detectFromBest', () {
    test('carico superiore al massimo storico genera un PersonalRecord', () {
      final pb = PersonalBest(
        exerciseId: 'bench-press',
        exerciseName: 'Panca piana',
        weight: 60.0,
        reps: 8,
        date: DateTime(2026, 7, 21),
      );

      final record = PersonalRecord.detectFromBest(
        exerciseId: 'bench-press',
        exerciseName: 'Panca piana',
        candidate: WorkoutSet(weight: 62.5, reps: 8),
        previousBest: pb,
      );

      expect(record, isNotNull);
      expect(record!.diffWeight, 2.5);
      expect(record.newWeight, 62.5);
      expect(record.previousWeight, 60.0);
      expect(record.previousDate, DateTime(2026, 7, 21));
    });

    test('carico uguale al massimo storico non e record', () {
      final pb = PersonalBest(
        exerciseId: 'bench-press',
        exerciseName: 'Panca piana',
        weight: 60.0,
        reps: 8,
        date: DateTime(2026, 7, 21),
      );

      final record = PersonalRecord.detectFromBest(
        exerciseId: 'bench-press',
        exerciseName: 'Panca piana',
        candidate: WorkoutSet(weight: 60.0, reps: 10),
        previousBest: pb,
      );

      expect(record, isNull);
    });

    test('carico inferiore al massimo storico non e record', () {
      final pb = PersonalBest(
        exerciseId: 'bench-press',
        exerciseName: 'Panca piana',
        weight: 60.0,
        reps: 8,
        date: DateTime(2026, 7, 21),
      );

      final record = PersonalRecord.detectFromBest(
        exerciseId: 'bench-press',
        exerciseName: 'Panca piana',
        candidate: WorkoutSet(weight: 57.5, reps: 12),
        previousBest: pb,
      );

      expect(record, isNull);
    });

    test('zero ripetizioni non costituisce record anche con carico maggiore', () {
      final pb = PersonalBest(
        exerciseId: 'bench-press',
        exerciseName: 'Panca piana',
        weight: 60.0,
        reps: 8,
        date: DateTime(2026, 7, 21),
      );

      final record = PersonalRecord.detectFromBest(
        exerciseId: 'bench-press',
        exerciseName: 'Panca piana',
        candidate: WorkoutSet(weight: 70.0, reps: 0),
        previousBest: pb,
      );

      expect(record, isNull);
    });

    test('primo allenamento dell esercizio (nessun PB pregresso) non genera record', () {
      final record = PersonalRecord.detectFromBest(
        exerciseId: 'bench-press',
        exerciseName: 'Panca piana',
        candidate: WorkoutSet(weight: 60.0, reps: 8),
        previousBest: null,
      );

      expect(record, isNull);
    });
  });

  group('PersonalRecord.detect con lista storica', () {
    test('confronta con la storia delle serie', () {
      final history = [
        WorkoutSet(weight: 50.0, reps: 10),
        WorkoutSet(weight: 60.0, reps: 8),
      ];

      final record = PersonalRecord.detect(
        exerciseId: 'bench',
        candidate: WorkoutSet(weight: 65.0, reps: 6),
        history: history,
        previousDate: DateTime(2026, 7, 10),
      );

      expect(record, isNotNull);
      expect(record!.diffWeight, 5.0);
      expect(record.previousWeight, 60.0);
    });

    test('storia vuota non genera record', () {
      final record = PersonalRecord.detect(
        exerciseId: 'bench',
        candidate: WorkoutSet(weight: 65.0, reps: 6),
        history: const [],
      );

      expect(record, isNull);
    });
  });

  group('PersonalRecord.calculatePersonalBests', () {
    test('calcola il massimo carico per esercizio dalle sessioni storiche', () {
      final sessions = [
        WorkoutSession(
          id: 's1',
          userId: 'u1',
          workoutTemplateId: 'w1',
          workoutName: 'Petto',
          startTime: DateTime(2026, 7, 10),
          endTime: DateTime(2026, 7, 10, 1),
          exercises: [
            WorkoutExercise(
              exerciseId: 'bench',
              exerciseName: 'Panca',
              sets: [
                WorkoutSet(weight: 50.0, reps: 10, isCompleted: true),
                WorkoutSet(weight: 55.0, reps: 8, isCompleted: true),
              ],
            ),
            WorkoutExercise(
              exerciseId: 'squat',
              exerciseName: 'Squat',
              sets: [
                WorkoutSet(weight: 80.0, reps: 6, isCompleted: true),
              ],
            ),
          ],
        ),
        WorkoutSession(
          id: 's2',
          userId: 'u1',
          workoutTemplateId: 'w1',
          workoutName: 'Petto 2',
          startTime: DateTime(2026, 7, 21),
          endTime: DateTime(2026, 7, 21, 1),
          exercises: [
            WorkoutExercise(
              exerciseId: 'bench',
              exerciseName: 'Panca',
              sets: [
                WorkoutSet(weight: 60.0, reps: 8, isCompleted: true),
                WorkoutSet(weight: 55.0, reps: 8, isCompleted: true),
              ],
            ),
          ],
        ),
      ];

      final pbs = PersonalRecord.calculatePersonalBests(sessions);

      expect(pbs.containsKey('bench'), isTrue);
      expect(pbs['bench']!.weight, 60.0);
      expect(pbs['bench']!.reps, 8);
      expect(pbs['bench']!.date, DateTime(2026, 7, 21));

      expect(pbs.containsKey('squat'), isTrue);
      expect(pbs['squat']!.weight, 80.0);
      expect(pbs['squat']!.date, DateTime(2026, 7, 10));
    });

    test('le serie non completate non contano, anche col carico piu alto', () {
      // E il caso che il criterio distingue, e succede sempre: aprendo un
      // allenamento, `_loadLastSessionData` precompila i carichi della volta
      // prima lasciando `isCompleted` a false. Se contassero, il massimo
      // sarebbe quello che ti eri proposto di fare, non quello che hai fatto.
      final sessions = [
        WorkoutSession(
          id: 's1',
          userId: 'u1',
          workoutTemplateId: 'w1',
          workoutName: 'Petto',
          startTime: DateTime(2026, 7, 10),
          endTime: DateTime(2026, 7, 10, 1),
          exercises: [
            WorkoutExercise(
              exerciseId: 'bench',
              exerciseName: 'Panca',
              sets: [
                WorkoutSet(weight: 60.0, reps: 8, isCompleted: true),
                WorkoutSet(weight: 100.0, reps: 8, isCompleted: false),
              ],
            ),
          ],
        ),
      ];

      final pbs = PersonalRecord.calculatePersonalBests(sessions);

      expect(pbs['bench']!.weight, 60.0);
    });

    test('ignora serie con 0 ripetizioni o carico negativo/zero', () {
      final sessions = [
        WorkoutSession(
          id: 's1',
          userId: 'u1',
          workoutTemplateId: 'w1',
          workoutName: 'Test',
          startTime: DateTime(2026, 7, 10),
          endTime: DateTime(2026, 7, 10, 1),
          exercises: [
            WorkoutExercise(
              exerciseId: 'bench',
              exerciseName: 'Panca',
              sets: [
                WorkoutSet(weight: 100.0, reps: 0, isCompleted: true),
                WorkoutSet(weight: 0.0, reps: 10, isCompleted: true),
              ],
            ),
          ],
        ),
      ];

      final pbs = PersonalRecord.calculatePersonalBests(sessions);
      expect(pbs.isEmpty, isTrue);
    });
  });

  group('PersonalRecord.detectSessionRecords', () {
    test('individua i record battuti durante una sessione rispetto a quelle precedenti', () {
      final priorSession = WorkoutSession(
        id: 's1',
        userId: 'u1',
        workoutTemplateId: 'w1',
        workoutName: 'Sessione 1',
        startTime: DateTime(2026, 7, 21),
        endTime: DateTime(2026, 7, 21, 1),
        exercises: [
          WorkoutExercise(
            exerciseId: 'bench',
            exerciseName: 'Panca piana',
            sets: [WorkoutSet(weight: 60.0, reps: 8, isCompleted: true)],
          ),
          WorkoutExercise(
            exerciseId: 'military',
            exerciseName: 'Military press',
            sets: [WorkoutSet(weight: 40.0, reps: 8, isCompleted: true)],
          ),
        ],
      );

      final currentSession = WorkoutSession(
        id: 's2',
        userId: 'u1',
        workoutTemplateId: 'w1',
        workoutName: 'Sessione 2',
        startTime: DateTime(2026, 8, 6),
        endTime: DateTime(2026, 8, 6, 1),
        exercises: [
          WorkoutExercise(
            exerciseId: 'bench',
            exerciseName: 'Panca piana',
            sets: [
              WorkoutSet(weight: 60.0, reps: 8, isCompleted: true),
              WorkoutSet(weight: 62.5, reps: 8, isCompleted: true),
            ],
          ),
          WorkoutExercise(
            exerciseId: 'military',
            exerciseName: 'Military press',
            sets: [WorkoutSet(weight: 40.0, reps: 10, isCompleted: true)], // stesso peso, no record
          ),
          WorkoutExercise(
            exerciseId: 'curls',
            exerciseName: 'Curl bicipiti',
            sets: [WorkoutSet(weight: 16.0, reps: 10, isCompleted: true)], // primo allenamento, no record
          ),
        ],
      );

      final records = PersonalRecord.detectSessionRecords(
        session: currentSession,
        allSessions: [priorSession, currentSession],
      );

      expect(records, hasLength(1));
      expect(records.first.exerciseId, 'bench');
      expect(records.first.newWeight, 62.5);
      expect(records.first.previousWeight, 60.0);
      expect(records.first.diffWeight, 2.5);
      expect(records.first.previousDate, DateTime(2026, 7, 21));
    });
  });
}
