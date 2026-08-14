import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/exercise.dart';

void main() {
  group('PlannedSet Model Tests', () {
    test('4x10 in un solo gesto genera 4 serie pianificate identiche', () {
      final exercise = WorkoutTemplateExercise(
        exerciseId: 'ex_1',
        exerciseName: 'Panca Piana',
        targetSets: 4,
        targetReps: '10',
        targetWeight: 60.0,
      );

      expect(exercise.plannedSets.length, equals(4));
      for (final set in exercise.plannedSets) {
        expect(set.reps, equals(10));
        expect(set.repsMax, isNull);
        expect(set.weight, equals(60.0));
        expect(set.kind, equals(PlannedSetKind.normal));
      }
    });

    test('Supporta l intervallo di ripetizioni 8-12', () {
      final exercise = WorkoutTemplateExercise(
        exerciseId: 'ex_2',
        exerciseName: 'Squat',
        targetSets: 3,
        targetReps: '8-12',
        targetWeight: 80.0,
      );

      expect(exercise.plannedSets.length, equals(3));
      expect(exercise.plannedSets.first.reps, equals(8));
      expect(exercise.plannedSets.first.repsMax, equals(12));
      expect(exercise.targetReps, equals('8-12'));
    });

    test('Supporta serie a cedimento (Max / Cedimento)', () {
      final set = PlannedSet(
        reps: null,
        kind: PlannedSetKind.toFailure,
        weight: 50.0,
      );

      expect(set.reps, isNull);
      expect(set.kind, equals(PlannedSetKind.toFailure));

      final exercise = WorkoutTemplateExercise(
        exerciseId: 'ex_3',
        exerciseName: 'Trazioni',
        plannedSets: [set, set],
      );

      expect(exercise.targetReps, equals('Cedimento'));
    });

    test('Piramide 4x(15-12-10-8) con carichi crescenti', () {
      final plannedSets = [
        PlannedSet(reps: 15, weight: 45.0),
        PlannedSet(reps: 12, weight: 50.0),
        PlannedSet(reps: 10, weight: 55.0),
        PlannedSet(reps: 8, weight: 60.0),
      ];

      final exercise = WorkoutTemplateExercise(
        exerciseId: 'ex_4',
        exerciseName: 'Leg Press',
        plannedSets: plannedSets,
      );

      expect(exercise.plannedSets.length, equals(4));
      expect(exercise.plannedSets[0].weight, equals(45.0));
      expect(exercise.plannedSets[1].weight, equals(50.0));
      expect(exercise.plannedSets[2].weight, equals(55.0));
      expect(exercise.plannedSets[3].weight, equals(60.0));
    });

    test('Carico per lato (perSide) raddoppia il peso calcolato al momento della sessione', () {
      final setPerSide = PlannedSet(
        reps: 10,
        weight: 10.0,
        perSide: true,
      );

      expect(setPerSide.perSide, isTrue);

      final rawWeight = setPerSide.weight ?? 0.0;
      final effectiveWeight = setPerSide.perSide ? rawWeight * 2.0 : rawWeight;
      final totalVolume = effectiveWeight * (setPerSide.reps ?? 0);

      // 10 kg per lato * 2 * 10 rep = 200 kg
      expect(totalVolume, equals(200.0));
    });

    test('Recupero per singola serie sovrascrive quello dell esercizio', () {
      final setCustomRest = PlannedSet(
        reps: 5,
        weight: 100.0,
        restSeconds: 180,
      );

      final setInheritedRest = PlannedSet(
        reps: 5,
        weight: 100.0,
        restSeconds: null,
      );

      final exercise = WorkoutTemplateExercise(
        exerciseId: 'ex_5',
        exerciseName: 'Stacco da Terra',
        restSeconds: 90,
        plannedSets: [setCustomRest, setInheritedRest],
      );

      expect(exercise.plannedSets[0].restSeconds, equals(180));
      expect(exercise.plannedSets[1].restSeconds, isNull);
      
      // Il recupero effettivo per la serie 1 e 180s, per la serie 2 e l eredita 90s
      final effectiveRest1 = exercise.plannedSets[0].restSeconds ?? exercise.restSeconds;
      final effectiveRest2 = exercise.plannedSets[1].restSeconds ?? exercise.restSeconds;

      expect(effectiveRest1, equals(180));
      expect(effectiveRest2, equals(90));
    });

    test('US-084: Supporta il raggruppamento di esercizi in Superserie o Circuito (superSetGroup)', () {
      final ex1 = WorkoutTemplateExercise(
        exerciseId: 'ex_ss_1',
        exerciseName: 'Curl Bicipiti',
        targetSets: 3,
        superSetGroup: 'A',
      );

      final ex2 = WorkoutTemplateExercise(
        exerciseId: 'ex_ss_2',
        exerciseName: 'French Press',
        targetSets: 3,
        superSetGroup: 'A',
      );

      final exSingle = WorkoutTemplateExercise(
        exerciseId: 'ex_single',
        exerciseName: 'Leg Extension',
        targetSets: 4,
        superSetGroup: null,
      );

      expect(ex1.superSetGroup, equals('A'));
      expect(ex2.superSetGroup, equals('A'));
      expect(exSingle.superSetGroup, isNull);

      final template = WorkoutTemplate(
        id: 't1',
        userId: 'u1',
        name: 'Scheda Braccia SS',
        exercises: [ex1, ex2, exSingle],
        category: ExerciseType.strength,
      );

      final exported = template.toMap();
      final reimported = WorkoutTemplate.fromMap(exported, 't1');

      expect(reimported.exercises[0].superSetGroup, equals('A'));
      expect(reimported.exercises[1].superSetGroup, equals('A'));
      expect(reimported.exercises[2].superSetGroup, isNull);
    });
  });
}
