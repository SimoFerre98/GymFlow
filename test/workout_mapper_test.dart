import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/local/local_workout_template.dart';
import 'package:gymflow/src/models/mappers/workout_mapper.dart';

/// Round-trip del mapper degli allenamenti (schede): ogni campo valorizzato
/// con un valore distinguibile, così un campo dimenticato dal mapper si nota.
void main() {
  WorkoutTemplate makeFullTemplate() {
    return WorkoutTemplate(
      id: 'tpl-abc-123',
      userId: 'user-42',
      name: 'Push Day A',
      description: 'Petto e tricipiti',
      parentProgramId: 'prog-1',
      category: ExerciseType.strength,
      exercises: [
        WorkoutTemplateExercise(
          exerciseId: 'ex-1',
          exerciseName: 'Bench Press',
          type: ExerciseType.strength,
          plannedSets: [
            PlannedSet(
              reps: 8,
              repsMax: 12,
              weight: 60.5,
              perSide: false,
              kind: PlannedSetKind.normal,
              restSeconds: 90,
              note: 'Controllato in negativa',
            ),
            PlannedSet(
              reps: null,
              kind: PlannedSetKind.toFailure,
              weight: 40.0,
            ),
          ],
          targetDistance: null,
          targetDurationSeconds: null,
          targetRPE: 8.5,
          restSeconds: 90,
          notes: 'Scaldarsi prima con il bilanciere vuoto',
          superSetGroup: 'A',
        ),
        WorkoutTemplateExercise(
          exerciseId: 'ex-2',
          exerciseName: 'Running',
          type: ExerciseType.cardio,
          plannedSets: [],
          targetDistance: 5.2,
          targetDurationSeconds: 1800,
          notes: null,
        ),
      ],
    );
  }

  WorkoutTemplate makeMinimalTemplate() {
    return WorkoutTemplate(
      id: 'tpl-min',
      userId: 'user-1',
      name: 'Quick',
      category: ExerciseType.bodyweight,
      exercises: [],
    );
  }

  group('Domain → Local → Domain round-trip', () {
    test('scheda completa: tutti i campi sopravvivono', () {
      final original = makeFullTemplate();
      final restored = original.toLocal().toDomain();

      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.name, equals(original.name));
      expect(restored.description, equals(original.description));
      expect(restored.parentProgramId, equals(original.parentProgramId));
      expect(restored.category, equals(original.category));
      expect(restored.exercises.length, equals(original.exercises.length));

      for (var i = 0; i < original.exercises.length; i++) {
        final origEx = original.exercises[i];
        final restEx = restored.exercises[i];
        expect(restEx.exerciseId, equals(origEx.exerciseId));
        expect(restEx.exerciseName, equals(origEx.exerciseName));
        expect(restEx.type, equals(origEx.type));
        expect(restEx.targetDistance, equals(origEx.targetDistance));
        expect(restEx.targetDurationSeconds, equals(origEx.targetDurationSeconds));
        expect(restEx.targetRPE, equals(origEx.targetRPE));
        expect(restEx.restSeconds, equals(origEx.restSeconds));
        expect(restEx.notes, equals(origEx.notes));
        expect(restEx.superSetGroup, equals(origEx.superSetGroup));
        expect(restEx.plannedSets.length, equals(origEx.plannedSets.length));

        for (var j = 0; j < origEx.plannedSets.length; j++) {
          final origSet = origEx.plannedSets[j];
          final restSet = restEx.plannedSets[j];
          expect(restSet.reps, equals(origSet.reps), reason: 'reps set[$i][$j]');
          expect(restSet.repsMax, equals(origSet.repsMax), reason: 'repsMax set[$i][$j]');
          expect(restSet.weight, equals(origSet.weight), reason: 'weight set[$i][$j]');
          expect(restSet.perSide, equals(origSet.perSide), reason: 'perSide set[$i][$j]');
          expect(restSet.kind, equals(origSet.kind), reason: 'kind set[$i][$j]');
          expect(restSet.restSeconds, equals(origSet.restSeconds), reason: 'restSeconds set[$i][$j]');
          expect(restSet.note, equals(origSet.note), reason: 'note set[$i][$j]');
        }
      }
    });

    test('scheda minima: campi opzionali nulli, esercizi vuoti', () {
      final original = makeMinimalTemplate();
      final restored = original.toLocal().toDomain();

      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.name, equals(original.name));
      expect(restored.description, isNull);
      expect(restored.parentProgramId, isNull);
      expect(restored.category, equals(ExerciseType.bodyweight));
      expect(restored.exercises, isEmpty);
    });

    test('set "a cedimento" senza reps sopravvive', () {
      final template = WorkoutTemplate(
        id: 'tpl-failure',
        userId: 'u',
        name: 'Failure set',
        category: ExerciseType.strength,
        exercises: [
          WorkoutTemplateExercise(
            exerciseId: 'e',
            exerciseName: 'Curl',
            plannedSets: [
              PlannedSet(reps: null, kind: PlannedSetKind.toFailure, weight: 20),
            ],
          ),
        ],
      );

      final restored = template.toLocal().toDomain();
      final set = restored.exercises.first.plannedSets.first;
      expect(set.reps, isNull);
      expect(set.kind, equals(PlannedSetKind.toFailure));
      expect(set.weight, equals(20.0));
    });

    test('ogni tipo di ExerciseType sopravvive al round-trip', () {
      for (final exType in ExerciseType.values) {
        final template = WorkoutTemplate(
          id: 'type-${exType.name}',
          userId: 'u',
          name: exType.name,
          category: exType,
          exercises: [],
        );
        final restored = template.toLocal().toDomain();
        expect(restored.category, equals(exType),
            reason: 'ExerciseType.${exType.name} deve sopravvivere');
      }
    });
  });

  group('Simmetria Local → Domain → Local', () {
    test('un LocalWorkoutTemplate popolato sopravvive al doppio salto', () {
      final local = LocalWorkoutTemplate()
        ..firestoreId = 'fs-tpl-1'
        ..userId = 'uid-1'
        ..name = 'Pull Day'
        ..description = 'Schiena e bicipiti'
        ..parentProgramId = 'prog-9'
        ..category = 'strength';
      final localEx = LocalWorkoutTemplateExercise()
        ..exerciseId = 'e-pull'
        ..exerciseName = 'Pull Up'
        ..type = 'bodyweight'
        ..targetRPE = 7.0
        ..restSeconds = 60
        ..notes = 'Presa larga'
        ..superSetGroup = 'B';
      final localSet = LocalPlannedSet()
        ..reps = 10
        ..weight = 0
        ..perSide = false
        ..kind = 'normal'
        ..note = 'Facile';
      localEx.plannedSets = [localSet];
      local.exercises = [localEx];

      final domain = local.toDomain();
      final backToLocal = domain.toLocal();

      expect(backToLocal.firestoreId, equals(local.firestoreId));
      expect(backToLocal.userId, equals(local.userId));
      expect(backToLocal.name, equals(local.name));
      expect(backToLocal.description, equals(local.description));
      expect(backToLocal.parentProgramId, equals(local.parentProgramId));
      expect(backToLocal.category, equals(local.category));

      final restoredEx = backToLocal.exercises.first;
      expect(restoredEx.exerciseId, equals(localEx.exerciseId));
      expect(restoredEx.type, equals(localEx.type));
      expect(restoredEx.superSetGroup, equals(localEx.superSetGroup));

      final restoredSet = restoredEx.plannedSets.first;
      expect(restoredSet.reps, equals(localSet.reps));
      expect(restoredSet.kind, equals(localSet.kind));
      expect(restoredSet.note, equals(localSet.note));
    });
  });
}
