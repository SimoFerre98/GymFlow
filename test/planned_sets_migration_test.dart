import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/workout.dart';

void main() {
  group('PlannedSet Legacy Migration Tests', () {
    test('Migrazione da mappa in formato vecchio (targetSets, targetReps, targetWeight)', () {
      // Mappa scritta a mano nel formato legacy
      final legacyMap = <String, dynamic>{
        'exerciseId': 'ex_legacy_1',
        'exerciseName': 'Panca Inclinata',
        'type': 'strength',
        'targetSets': 4,
        'targetReps': '8-12',
        'targetWeight': 50.0,
        'restSeconds': 90,
        'notes': 'Impugnatura media',
      };

      final exercise = WorkoutTemplateExercise.fromMap(legacyMap);

      expect(exercise.exerciseId, equals('ex_legacy_1'));
      expect(exercise.exerciseName, equals('Panca Inclinata'));
      expect(exercise.plannedSets.length, equals(4));

      for (int i = 0; i < 4; i++) {
        final set = exercise.plannedSets[i];
        expect(set.reps, equals(8));
        expect(set.repsMax, equals(12));
        expect(set.weight, equals(50.0));
        expect(set.kind, equals(PlannedSetKind.normal));
      }

      // Verifica che toMap esporti sia plannedSets che i campi legacy per retrocompatibilita
      final exportedMap = exercise.toMap();
      expect(exportedMap.containsKey('plannedSets'), isTrue);
      expect(exportedMap['targetSets'], equals(4));
      expect(exportedMap['targetReps'], equals('8-12'));
      expect(exportedMap['targetWeight'], equals(50.0));
    });

    test('Migrazione da formato legacy con reps max / cedimento', () {
      final legacyMap = <String, dynamic>{
        'exerciseId': 'ex_legacy_2',
        'exerciseName': 'Dips parallele',
        'type': 'strength',
        'targetSets': 3,
        'targetReps': 'max',
        'targetWeight': null,
      };

      final exercise = WorkoutTemplateExercise.fromMap(legacyMap);

      expect(exercise.plannedSets.length, equals(3));
      for (final set in exercise.plannedSets) {
        expect(set.reps, isNull);
        expect(set.kind, equals(PlannedSetKind.toFailure));
      }
    });

    test('Template completo con schede vecchie e nuove viene letto correttamente', () {
      final legacyTemplateMap = <String, dynamic>{
        'userId': 'user_123',
        'name': 'Scheda Forzata',
        'category': 'strength',
        'exercises': [
          {
            'exerciseId': 'ex_1',
            'exerciseName': 'Squat',
            'targetSets': 3,
            'targetReps': '10',
            'targetWeight': 80.0,
          },
          {
            'exerciseId': 'ex_2',
            'exerciseName': 'Affondi',
            'plannedSets': [
              {'reps': 12, 'weight': 14.0, 'perSide': true, 'kind': 'normal'},
              {'reps': 10, 'weight': 16.0, 'perSide': true, 'kind': 'normal'},
            ],
          }
        ],
      };

      final template = WorkoutTemplate.fromMap(legacyTemplateMap, 'template_1');

      expect(template.exercises.length, equals(2));
      
      // Primo esercizio (legacy): convertito in 3 plannedSets
      expect(template.exercises[0].plannedSets.length, equals(3));
      expect(template.exercises[0].plannedSets[0].weight, equals(80.0));

      // Secondo esercizio (nuovo): 2 plannedSets con perSide = true
      expect(template.exercises[1].plannedSets.length, equals(2));
      expect(template.exercises[1].plannedSets[0].perSide, isTrue);
      expect(template.exercises[1].plannedSets[0].weight, equals(14.0));
      expect(template.exercises[1].plannedSets[1].weight, equals(16.0));
    });
  });
}
