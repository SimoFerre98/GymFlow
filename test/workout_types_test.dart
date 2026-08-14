import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/utils/statistics_helper.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/workout_type.dart';

void main() {
  group('WorkoutType enum', () {
    test('contiene i 4 tipi fondamentali', () {
      expect(WorkoutType.values, containsAll([
        WorkoutType.strength,
        WorkoutType.cardio,
        WorkoutType.mobility,
        WorkoutType.sport,
      ]));
    });

    test('fromString converte nomi noti e alias', () {
      expect(WorkoutType.fromString('strength'), WorkoutType.strength);
      expect(WorkoutType.fromString('palestra'), WorkoutType.strength);
      expect(WorkoutType.fromString('hypertrophy'), WorkoutType.strength);
      expect(WorkoutType.fromString('bodyweight'), WorkoutType.strength);

      expect(WorkoutType.fromString('cardio'), WorkoutType.cardio);
      expect(WorkoutType.fromString('running'), WorkoutType.cardio);
      expect(WorkoutType.fromString('cycling'), WorkoutType.cardio);

      expect(WorkoutType.fromString('mobility'), WorkoutType.mobility);
      expect(WorkoutType.fromString('flexibility'), WorkoutType.mobility);
      expect(WorkoutType.fromString('stretching'), WorkoutType.mobility);

      expect(WorkoutType.fromString('sport'), WorkoutType.sport);
      expect(WorkoutType.fromString('sports'), WorkoutType.sport);
    });

    test('fromString ricade su strength per null o valori sconosciuti (retrocompatibilità)', () {
      expect(WorkoutType.fromString(null), WorkoutType.strength);
      expect(WorkoutType.fromString(''), WorkoutType.strength);
      expect(WorkoutType.fromString('unknown_type_xyz'), WorkoutType.strength);
    });

    test('dichiara i campi caratteristici per ciascun tipo', () {
      // Strength
      expect(WorkoutType.strength.usesWeightAndReps, isTrue);
      expect(WorkoutType.strength.usesDistance, isFalse);
      expect(WorkoutType.strength.usesPace, isFalse);

      // Cardio
      expect(WorkoutType.cardio.usesWeightAndReps, isFalse);
      expect(WorkoutType.cardio.usesDistance, isTrue);
      expect(WorkoutType.cardio.usesPace, isTrue);
      expect(WorkoutType.cardio.usesHeartRate, isTrue);

      // Mobility
      expect(WorkoutType.mobility.usesWeightAndReps, isFalse);
      expect(WorkoutType.mobility.usesDistance, isFalse);
      expect(WorkoutType.mobility.usesDuration, isTrue);
      expect(WorkoutType.mobility.usesRpe, isTrue);

      // Sport
      expect(WorkoutType.sport.usesWeightAndReps, isFalse);
      expect(WorkoutType.sport.usesCalories, isTrue);
      expect(WorkoutType.sport.usesHeartRate, isTrue);
      expect(WorkoutType.sport.usesDuration, isTrue);
    });

    test('restituisce la localizationKey corretta', () {
      expect(WorkoutType.strength.localizationKey, 'workout_type_strength');
      expect(WorkoutType.cardio.localizationKey, 'workout_type_cardio');
      expect(WorkoutType.mobility.localizationKey, 'workout_type_mobility');
      expect(WorkoutType.sport.localizationKey, 'workout_type_sport');
    });
  });

  group('WorkoutSet pace calculation', () {
    test('calcola il ritmo in min/km quando distanza e durata sono valide', () {
      // 5 km in 25 minuti (1500 secondi) -> 5.0 min/km
      final set = WorkoutSet(
        distance: 5.0,
        durationSeconds: 1500,
      );
      expect(set.paceMinPerKm, closeTo(5.0, 0.001));

      // 10 km in 50 minuti (3000 secondi) -> 5.0 min/km
      final set2 = WorkoutSet(
        distance: 10.0,
        durationSeconds: 3000,
      );
      expect(set2.paceMinPerKm, closeTo(5.0, 0.001));

      // 8 km in 36 minuti (2160 secondi) -> 4.5 min/km (4:30 /km)
      final set3 = WorkoutSet(
        distance: 8.0,
        durationSeconds: 2160,
      );
      expect(set3.paceMinPerKm, closeTo(4.5, 0.001));
    });

    test('restituisce null per distanza o durata nulle o non positive', () {
      expect(WorkoutSet(distance: null, durationSeconds: 600).paceMinPerKm, isNull);
      expect(WorkoutSet(distance: 5.0, durationSeconds: null).paceMinPerKm, isNull);
      expect(WorkoutSet(distance: 0.0, durationSeconds: 600).paceMinPerKm, isNull);
      expect(WorkoutSet(distance: 5.0, durationSeconds: 0).paceMinPerKm, isNull);
    });
  });

  group('WorkoutSession model & Firestore conversion', () {
    test('serializza e deserializza correttamente tutti i tipi di sessione', () {
      for (final type in WorkoutType.values) {
        final session = WorkoutSession(
          id: 'sess-1',
          userId: 'user-1',
          workoutTemplateId: 'tpl-1',
          workoutName: '${type.name} Workout',
          startTime: DateTime(2026, 8, 14, 10, 0),
          endTime: DateTime(2026, 8, 14, 11, 0),
          workoutType: type.name,
          exercises: [
            WorkoutExercise(
              exerciseId: 'ex-1',
              exerciseName: 'Test Exercise',
              type: type == WorkoutType.strength ? ExerciseType.strength : ExerciseType.cardio,
              sets: [
                WorkoutSet(
                  weight: type == WorkoutType.strength ? 80.0 : 0.0,
                  reps: type == WorkoutType.strength ? 10 : 0,
                  distance: type == WorkoutType.cardio ? 5.0 : null,
                  durationSeconds: 1800,
                  isCompleted: true,
                ),
              ],
            ),
          ],
        );

        final map = session.toMap();
        expect(map['workoutType'], type.name);

        final deserialized = WorkoutSession.fromMap(map, 'sess-1');
        expect(deserialized.workoutType, type.name);
        expect(deserialized.type, type);
      }
    });

    test('sessioni storiche senza workoutType vengono lette come strength', () {
      final legacyMap = {
        'userId': 'user-old',
        'workoutTemplateId': 'tpl-old',
        'workoutName': 'Old Session',
        'startTime': '2026-01-01T10:00:00.000',
        'exercises': [],
      };

      final session = WorkoutSession.fromMap(legacyMap, 'legacy-1');
      expect(session.workoutType, 'strength');
      expect(session.type, WorkoutType.strength);
    });
  });

  group('WorkoutProgram con giorni di tipi diversi', () {
    test('un programma può raggruppare template di tipo palestra, cardio e mobilità', () {
      final tplStrength = WorkoutTemplate(
        id: 't-strength',
        userId: 'u1',
        name: 'Giorno A - Upper Body',
        category: ExerciseType.strength,
        exercises: [],
      );

      final tplCardio = WorkoutTemplate(
        id: 't-cardio',
        userId: 'u1',
        name: 'Giorno B - Corsa 5K',
        category: ExerciseType.cardio,
        exercises: [],
      );

      final tplMobility = WorkoutTemplate(
        id: 't-mobility',
        userId: 'u1',
        name: 'Giorno C - Mobilità e Recupero',
        category: ExerciseType.timed,
        exercises: [],
      );

      expect(tplStrength.workoutType, WorkoutType.strength);
      expect(tplCardio.workoutType, WorkoutType.cardio);
      expect(tplMobility.workoutType, WorkoutType.mobility);

      final program = WorkoutProgram(
        id: 'prog-1',
        userId: 'u1',
        name: 'Programma Ibrido Completo',
        workoutIds: [tplStrength.id, tplCardio.id, tplMobility.id],
        createdAt: DateTime.now(),
      );

      expect(program.workoutIds.length, 3);
    });
  });

  group('Statistics aggregation per workout type', () {
    test('il volume totale include solo serie con pesi e ripetizioni senza inquinamento da cardio', () {
      final strengthSession = WorkoutSession(
        id: 's1',
        userId: 'u1',
        workoutTemplateId: '',
        workoutName: 'Palestra',
        startTime: DateTime.now(),
        workoutType: 'strength',
        exercises: [
          WorkoutExercise(
            exerciseId: 'ex1',
            exerciseName: 'Panca Piana',
            sets: [
              WorkoutSet(weight: 100, reps: 5, isCompleted: true), // 500 kg
              WorkoutSet(weight: 80, reps: 8, isCompleted: true),  // 640 kg
            ],
          ),
        ],
      );

      final cardioSession = WorkoutSession(
        id: 's2',
        userId: 'u1',
        workoutTemplateId: '',
        workoutName: 'Corsa',
        startTime: DateTime.now(),
        workoutType: 'cardio',
        exercises: [
          WorkoutExercise(
            exerciseId: 'ex2',
            exerciseName: 'Corsa sul Tapis',
            type: ExerciseType.cardio,
            sets: [
              WorkoutSet(distance: 5.0, durationSeconds: 1500, isCompleted: true),
            ],
          ),
        ],
      );

      final sessions = [strengthSession, cardioSession];

      // Volume: 500 + 640 = 1140 kg
      expect(StatisticsHelper.calculateTotalVolume(sessions), 1140);

      // Distance: 5.0 km
      expect(StatisticsHelper.calculateTotalDistance(sessions), 5.0);

      // Distribution
      final distribution = StatisticsHelper.getWorkoutTypeDistribution(sessions);
      expect(distribution['Strength'], 1);
      expect(distribution['Cardio'], 1);
    });

    test('calculateAveragePace calcola correttamente il ritmo medio sulle sessioni cardio', () {
      final session1 = WorkoutSession(
        id: 's1',
        userId: 'u1',
        workoutTemplateId: '',
        workoutName: 'Corsa Mattina',
        startTime: DateTime.now(),
        workoutType: 'cardio',
        exercises: [
          WorkoutExercise(
            exerciseId: 'c1',
            exerciseName: 'Corsa',
            type: ExerciseType.cardio,
            sets: [
              WorkoutSet(distance: 5.0, durationSeconds: 1500, isCompleted: true), // 5 km in 25 min
            ],
          ),
        ],
      );

      final session2 = WorkoutSession(
        id: 's2',
        userId: 'u1',
        workoutTemplateId: '',
        workoutName: 'Corsa Sera',
        startTime: DateTime.now(),
        workoutType: 'cardio',
        exercises: [
          WorkoutExercise(
            exerciseId: 'c1',
            exerciseName: 'Corsa',
            type: ExerciseType.cardio,
            sets: [
              WorkoutSet(distance: 5.0, durationSeconds: 1200, isCompleted: true), // 5 km in 20 min
            ],
          ),
        ],
      );

      // Totale 10 km in 45 minuti -> 4.5 min/km
      expect(StatisticsHelper.calculateAveragePace([session1, session2]), closeTo(4.5, 0.001));
    });
  });
}
