import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/local/local_workout_session.dart';
import 'package:gymflow/src/models/mappers/session_mapper.dart';

/// Andata e ritorno del mapper delle sessioni: e l'unico punto in cui i dati
/// dell'utente attraversano un confine, quindi un campo perso qui e un
/// allenamento perso per sempre.
///
/// Ogni campo e valorizzato con un valore **distinguibile** — non zeri, non
/// stringhe vuote — perche un campo che il mapper dimentica di copiare si nota
/// solo se il valore di partenza era diverso da quello di default.
///
/// Il tempo di recupero non compare fra i casi: `restSeconds` sta su
/// `WorkoutTemplateExercise`, cioe su cio che ti proponi di fare, non su
/// `WorkoutSet`, che e cio che hai fatto. Non attraversa questo mapper.
void main() {
  // ---------------------------------------------------------------------------
  // Helper: crea una sessione completa con tutti i campi valorizzati
  // ---------------------------------------------------------------------------
  WorkoutSession makeFullSession() {
    return WorkoutSession(
      id: 'session-abc-123',
      userId: 'user-42',
      workoutTemplateId: 'tmpl-99',
      workoutName: 'Push Day A',
      startTime: DateTime.utc(2026, 8, 9, 10, 0, 0),
      endTime: DateTime.utc(2026, 8, 9, 11, 30, 0),
      exercises: [
        WorkoutExercise(
          exerciseId: 'ex-1',
          exerciseName: 'Bench Press',
          type: ExerciseType.strength,
          sets: [
            WorkoutSet(
              weight: 80.5,
              reps: 10,
              distance: 0,
              durationSeconds: 45,
              calories: 12.3,
              level: 3,
              isCompleted: true,
              rpe: 8.5,
              notes: 'Felt strong',
            ),
            WorkoutSet(
              weight: 85.0,
              reps: 8,
              isCompleted: true,
              rpe: 9.0,
            ),
          ],
          notes: 'Warm up with bar first',
        ),
        WorkoutExercise(
          exerciseId: 'ex-2',
          exerciseName: 'Running',
          type: ExerciseType.cardio,
          sets: [
            WorkoutSet(
              weight: 0,
              reps: 0,
              distance: 5.2,
              durationSeconds: 1800,
              calories: 350.0,
              isCompleted: true,
            ),
          ],
          notes: 'Treadmill interval',
        ),
      ],
      notes: 'Good session overall',
      workoutType: 'strength',
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: crea una sessione minima (solo campi obbligatori, liste vuote)
  // ---------------------------------------------------------------------------
  WorkoutSession makeMinimalSession() {
    return WorkoutSession(
      id: 'session-min',
      userId: 'user-1',
      workoutTemplateId: '',
      workoutName: 'Quick',
      startTime: DateTime.utc(2026, 1, 1, 8, 0, 0),
      exercises: [],
    );
  }

  // ---------------------------------------------------------------------------
  // Gruppo 1: Round-trip Domain → Local → Domain  (session_mapper.dart)
  // ---------------------------------------------------------------------------
  group('Domain → Local → Domain round-trip', () {
    test('sessione completa: tutti i campi sopravvivono', () {
      final original = makeFullSession();
      final local = original.toLocal();
      final restored = local.toDomain();

      // --- Session-level ---
      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.workoutTemplateId, equals(original.workoutTemplateId));
      expect(restored.workoutName, equals(original.workoutName));
      expect(restored.startTime, equals(original.startTime));
      expect(restored.endTime, equals(original.endTime));
      expect(restored.notes, equals(original.notes),
          reason: 'notes della sessione devono sopravvivere');
      expect(restored.workoutType, equals(original.workoutType));
      expect(restored.durationSeconds, equals(original.durationSeconds),
          reason: 'duration è computed, ma dipende da startTime/endTime');
      expect(restored.exercises.length, equals(original.exercises.length));

      // --- Exercise-level ---
      for (var i = 0; i < original.exercises.length; i++) {
        final origEx = original.exercises[i];
        final restEx = restored.exercises[i];
        expect(restEx.exerciseId, equals(origEx.exerciseId));
        expect(restEx.exerciseName, equals(origEx.exerciseName));
        expect(restEx.type, equals(origEx.type));
        expect(restEx.notes, equals(origEx.notes),
            reason: 'notes dell\'esercizio $i devono sopravvivere');
        expect(restEx.sets.length, equals(origEx.sets.length));

        // --- Set-level ---
        for (var j = 0; j < origEx.sets.length; j++) {
          final origSet = origEx.sets[j];
          final restSet = restEx.sets[j];
          expect(restSet.weight, closeTo(origSet.weight, 1e-9),
              reason: 'weight set[$i][$j]');
          expect(restSet.reps, equals(origSet.reps),
              reason: 'reps set[$i][$j]');
          expect(restSet.distance, equals(origSet.distance),
              reason: 'distance set[$i][$j]');
          expect(restSet.durationSeconds, equals(origSet.durationSeconds),
              reason: 'durationSeconds set[$i][$j]');
          expect(restSet.calories, equals(origSet.calories),
              reason: 'calories set[$i][$j]');
          expect(restSet.level, equals(origSet.level),
              reason: 'level set[$i][$j]');
          expect(restSet.isCompleted, equals(origSet.isCompleted),
              reason: 'isCompleted set[$i][$j]');
          expect(restSet.rpe, equals(origSet.rpe),
              reason: 'rpe set[$i][$j]');
          expect(restSet.notes, equals(origSet.notes),
              reason: 'notes set[$i][$j]');
        }
      }
    });

    test('sessione minima: campi opzionali nulli, liste vuote', () {
      final original = makeMinimalSession();
      final local = original.toLocal();
      final restored = local.toDomain();

      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.workoutTemplateId, equals(original.workoutTemplateId));
      expect(restored.workoutName, equals(original.workoutName));
      expect(restored.startTime, equals(original.startTime));
      expect(restored.endTime, isNull);
      expect(restored.notes, isNull);
      // workoutType: il mapper restituisce null → toDomain() fallback 'strength'
      expect(restored.workoutType, equals('strength'));
      expect(restored.exercises, isEmpty);
      expect(restored.durationSeconds, equals(0),
          reason: 'nessun endTime → duration 0');
    });

    test('valori limite: peso zero', () {
      final session = WorkoutSession(
        id: 'lim-zero-weight',
        userId: 'u',
        workoutTemplateId: 't',
        workoutName: 'Zero Weight',
        startTime: DateTime.utc(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e',
            exerciseName: 'Bodyweight Squat',
            type: ExerciseType.bodyweight,
            sets: [WorkoutSet(weight: 0, reps: 20, isCompleted: true)],
          ),
        ],
      );

      final restored = session.toLocal().toDomain();
      final set = restored.exercises.first.sets.first;
      expect(set.weight, equals(0.0));
      expect(set.reps, equals(20));
      expect(set.isCompleted, isTrue,
          reason: 'isCompleted esplicito deve sopravvivere');
    });

    test('valori limite: peso con decimali di precisione', () {
      final session = WorkoutSession(
        id: 'lim-decimal-weight',
        userId: 'u',
        workoutTemplateId: 't',
        workoutName: 'Precise',
        startTime: DateTime.utc(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e',
            exerciseName: 'Cable Fly',
            sets: [WorkoutSet(weight: 17.25, reps: 12, isCompleted: false)],
          ),
        ],
      );

      final restored = session.toLocal().toDomain();
      final set = restored.exercises.first.sets.first;
      expect(set.weight, closeTo(17.25, 1e-9),
          reason: 'il peso decimale non deve perdere precisione');
      expect(set.isCompleted, isFalse,
          reason: 'isCompleted = false deve restare false');
    });

    test('valori limite: durationSeconds nullo vs valorizzato', () {
      final session = WorkoutSession(
        id: 'lim-duration',
        userId: 'u',
        workoutTemplateId: 't',
        workoutName: 'Duration mix',
        startTime: DateTime.utc(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e',
            exerciseName: 'Plank',
            type: ExerciseType.isometric,
            sets: [
              WorkoutSet(durationSeconds: 60, isCompleted: true),
              WorkoutSet(durationSeconds: null, isCompleted: false),
            ],
          ),
        ],
      );

      final restored = session.toLocal().toDomain();
      final sets = restored.exercises.first.sets;
      expect(sets[0].durationSeconds, equals(60),
          reason: 'durationSeconds valorizzato');
      expect(sets[1].durationSeconds, isNull,
          reason: 'durationSeconds nullo deve restare nullo');
    });

    test('valori limite: notes vuota vs nulla', () {
      final session = WorkoutSession(
        id: 'lim-notes',
        userId: 'u',
        workoutTemplateId: 't',
        workoutName: 'Notes test',
        startTime: DateTime.utc(2026, 1, 1),
        notes: '',
        exercises: [
          WorkoutExercise(
            exerciseId: 'e',
            exerciseName: 'Curl',
            sets: [
              WorkoutSet(notes: '', isCompleted: true),
              WorkoutSet(notes: null, isCompleted: false),
            ],
            notes: '',
          ),
        ],
      );

      final restored = session.toLocal().toDomain();
      // notes vuota della sessione
      expect(restored.notes, equals(''),
          reason: 'notes vuota deve restare stringa vuota, non null');
      // notes dell'esercizio
      expect(restored.exercises.first.notes, equals(''));
      // notes dei set
      expect(restored.exercises.first.sets[0].notes, equals(''));
      expect(restored.exercises.first.sets[1].notes, isNull);
    });

    test('ogni tipo di ExerciseType sopravvive al round-trip', () {
      for (final exType in ExerciseType.values) {
        final session = WorkoutSession(
          id: 'type-${exType.name}',
          userId: 'u',
          workoutTemplateId: 't',
          workoutName: exType.name,
          startTime: DateTime.utc(2026, 1, 1),
          exercises: [
            WorkoutExercise(
              exerciseId: 'e',
              exerciseName: exType.name,
              type: exType,
              sets: [WorkoutSet(isCompleted: true)],
            ),
          ],
        );

        final restored = session.toLocal().toDomain();
        expect(restored.exercises.first.type, equals(exType),
            reason: 'ExerciseType.${exType.name} deve sopravvivere');
      }
    });

    test('verifica esplicita di isCompleted, notes, durationSeconds, rpe', () {
      // Criterio 5: verifica esplicita campi specifici, non solo ==
      final set = WorkoutSet(
        weight: 50.0,
        reps: 10,
        isCompleted: true,
        notes: 'Note specifiche del set',
        durationSeconds: 120,
        rpe: 7.5,
      );
      final session = WorkoutSession(
        id: 'explicit-fields',
        userId: 'u',
        workoutTemplateId: 't',
        workoutName: 'Explicit',
        startTime: DateTime.utc(2026, 6, 15, 9, 0),
        endTime: DateTime.utc(2026, 6, 15, 10, 0),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e',
            exerciseName: 'Squat',
            sets: [set],
            notes: 'Note esercizio',
          ),
        ],
        notes: 'Note sessione',
      );

      final restored = session.toLocal().toDomain();
      final restoredSet = restored.exercises.first.sets.first;

      // isCompleted — verifica esplicita
      expect(restoredSet.isCompleted, isTrue,
          reason: 'isCompleted deve essere true');

      // notes — verifica esplicita a ogni livello
      expect(restored.notes, equals('Note sessione'),
          reason: 'notes sessione');
      expect(restored.exercises.first.notes, equals('Note esercizio'),
          reason: 'notes esercizio');
      expect(restoredSet.notes, equals('Note specifiche del set'),
          reason: 'notes set');

      // duration — campo computed dalla sessione
      expect(restored.durationSeconds, equals(3600),
          reason: 'duration = endTime - startTime = 1h = 3600s');

      // durationSeconds del set (campo diverso dalla duration della sessione)
      expect(restoredSet.durationSeconds, equals(120),
          reason: 'durationSeconds del singolo set');

      // rpe
      expect(restoredSet.rpe, equals(7.5), reason: 'rpe del set');
    });
  });

  // ---------------------------------------------------------------------------
  // Gruppo 2: Round-trip Domain → Map → Domain  (toMap/fromMap su modelli)
  // ---------------------------------------------------------------------------
  group('Domain → Map → Domain round-trip (toMap/fromMap)', () {
    test('sessione completa', () {
      final original = makeFullSession();
      final map = original.toMap();
      final restored = WorkoutSession.fromMap(map, original.id);

      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.workoutTemplateId, equals(original.workoutTemplateId));
      expect(restored.workoutName, equals(original.workoutName));
      expect(restored.startTime, equals(original.startTime));
      expect(restored.endTime, equals(original.endTime));
      expect(restored.notes, equals(original.notes));
      expect(restored.workoutType, equals(original.workoutType));
      expect(restored.exercises.length, equals(original.exercises.length));

      for (var i = 0; i < original.exercises.length; i++) {
        final origEx = original.exercises[i];
        final restEx = restored.exercises[i];
        expect(restEx.exerciseId, equals(origEx.exerciseId));
        expect(restEx.exerciseName, equals(origEx.exerciseName));
        expect(restEx.type, equals(origEx.type));
        expect(restEx.notes, equals(origEx.notes));
        expect(restEx.sets.length, equals(origEx.sets.length));

        for (var j = 0; j < origEx.sets.length; j++) {
          final origSet = origEx.sets[j];
          final restSet = restEx.sets[j];
          expect(restSet.weight, closeTo(origSet.weight, 1e-9));
          expect(restSet.reps, equals(origSet.reps));
          expect(restSet.distance, equals(origSet.distance));
          expect(restSet.durationSeconds, equals(origSet.durationSeconds));
          expect(restSet.calories, equals(origSet.calories));
          expect(restSet.level, equals(origSet.level));
          expect(restSet.isCompleted, equals(origSet.isCompleted));
          expect(restSet.rpe, equals(origSet.rpe));
          expect(restSet.notes, equals(origSet.notes));
        }
      }
    });

    test('sessione minima', () {
      final original = makeMinimalSession();
      final map = original.toMap();
      final restored = WorkoutSession.fromMap(map, original.id);

      expect(restored.id, equals(original.id));
      expect(restored.endTime, isNull);
      expect(restored.notes, isNull);
      expect(restored.exercises, isEmpty);
    });

    test('verifica esplicita isCompleted, notes, durationSeconds, rpe nel map round-trip', () {
      final session = WorkoutSession(
        id: 'map-explicit',
        userId: 'u',
        workoutTemplateId: 't',
        workoutName: 'Map Explicit',
        startTime: DateTime.utc(2026, 3, 15, 14, 0),
        endTime: DateTime.utc(2026, 3, 15, 15, 30),
        notes: 'Session note for map',
        exercises: [
          WorkoutExercise(
            exerciseId: 'e1',
            exerciseName: 'Deadlift',
            type: ExerciseType.strength,
            sets: [
              WorkoutSet(
                weight: 120.0,
                reps: 5,
                isCompleted: true,
                durationSeconds: 30,
                rpe: 9.5,
                notes: 'PR attempt',
              ),
              WorkoutSet(
                weight: 100.0,
                reps: 8,
                isCompleted: false,
                notes: null,
              ),
            ],
            notes: 'Focus on form',
          ),
        ],
      );

      final map = session.toMap();
      final restored = WorkoutSession.fromMap(map, session.id);
      final sets = restored.exercises.first.sets;

      // isCompleted esplicito
      expect(sets[0].isCompleted, isTrue);
      expect(sets[1].isCompleted, isFalse);

      // notes esplicite
      expect(restored.notes, equals('Session note for map'));
      expect(restored.exercises.first.notes, equals('Focus on form'));
      expect(sets[0].notes, equals('PR attempt'));
      expect(sets[1].notes, isNull);

      // durationSeconds del set
      expect(sets[0].durationSeconds, equals(30));

      // duration della sessione (computed)
      expect(restored.durationSeconds, equals(5400));

      // rpe
      expect(sets[0].rpe, equals(9.5));
    });

    test('peso zero nel map round-trip', () {
      final session = WorkoutSession(
        id: 'map-zero-w',
        userId: 'u',
        workoutTemplateId: 't',
        workoutName: 'Zero',
        startTime: DateTime.utc(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e',
            exerciseName: 'Push-up',
            type: ExerciseType.bodyweight,
            sets: [WorkoutSet(weight: 0, reps: 25, isCompleted: true)],
          ),
        ],
      );

      final restored = WorkoutSession.fromMap(session.toMap(), session.id);
      final set = restored.exercises.first.sets.first;
      expect(set.weight, equals(0.0));
      expect(set.isCompleted, isTrue);
    });

    test('peso con decimali nel map round-trip', () {
      final session = WorkoutSession(
        id: 'map-decimal-w',
        userId: 'u',
        workoutTemplateId: 't',
        workoutName: 'Decimal',
        startTime: DateTime.utc(2026, 1, 1),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e',
            exerciseName: 'Dumbbell Press',
            sets: [WorkoutSet(weight: 22.75, reps: 10, isCompleted: false)],
          ),
        ],
      );

      final restored = WorkoutSession.fromMap(session.toMap(), session.id);
      final set = restored.exercises.first.sets.first;
      expect(set.weight, closeTo(22.75, 1e-9));
    });

  });

  // ---------------------------------------------------------------------------
  // Gruppo 3: Simmetria Local → Domain → Local
  // ---------------------------------------------------------------------------
  group('Simmetria Local → Domain → Local', () {
    test('un LocalWorkoutSession popolato sopravvive al doppio salto', () {
      final local = LocalWorkoutSession()
        ..firestoreId = 'fs-id-567'
        ..userId = 'uid-1'
        ..workoutTemplateId = 'tmpl-1'
        ..workoutName = 'Pull Day'
        ..startTime = DateTime.utc(2026, 5, 1, 16, 0)
        ..endTime = DateTime.utc(2026, 5, 1, 17, 15)
        ..notes = 'Felt tired'
        ..workoutType = 'strength';

      final localEx = LocalWorkoutExercise()
        ..exerciseId = 'e-pull'
        ..exerciseName = 'Pull Up'
        ..type = 'bodyweight'
        ..notes = 'Wide grip';

      final localSet = LocalWorkoutSet()
        ..weight = 0
        ..reps = 12
        ..isCompleted = true
        ..rpe = 6.0
        ..notes = 'Easy';

      localEx.sets = [localSet];
      local.exercises = [localEx];

      // Local → Domain → Local
      final domain = local.toDomain();
      final backToLocal = domain.toLocal();

      expect(backToLocal.firestoreId, equals(local.firestoreId));
      expect(backToLocal.userId, equals(local.userId));
      expect(backToLocal.workoutTemplateId, equals(local.workoutTemplateId));
      expect(backToLocal.workoutName, equals(local.workoutName));
      expect(backToLocal.startTime, equals(local.startTime));
      expect(backToLocal.endTime, equals(local.endTime));
      expect(backToLocal.notes, equals(local.notes));
      expect(backToLocal.workoutType, equals(local.workoutType));

      final restoredEx = backToLocal.exercises.first;
      expect(restoredEx.exerciseId, equals(localEx.exerciseId));
      expect(restoredEx.exerciseName, equals(localEx.exerciseName));
      expect(restoredEx.type, equals(localEx.type));
      expect(restoredEx.notes, equals(localEx.notes));

      final restoredSet = restoredEx.sets.first;
      expect(restoredSet.weight, equals(localSet.weight));
      expect(restoredSet.reps, equals(localSet.reps));
      expect(restoredSet.isCompleted, equals(localSet.isCompleted));
      expect(restoredSet.rpe, equals(localSet.rpe));
      expect(restoredSet.notes, equals(localSet.notes));
    });
  });
}
