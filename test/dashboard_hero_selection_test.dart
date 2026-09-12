import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/ui/screens/dashboard_screen.dart';

WorkoutTemplate _template(String id) {
  return WorkoutTemplate(
    id: id,
    userId: 'u1',
    name: 'Giorno $id',
    exercises: const [],
    category: ExerciseType.strength,
  );
}

WorkoutProgram _program(List<String> workoutIds) {
  return WorkoutProgram(
    id: 'p1',
    userId: 'u1',
    name: 'Programma',
    workoutIds: workoutIds,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );
}

WorkoutSession _session(String workoutTemplateId, DateTime startTime) {
  return WorkoutSession(
    id: 's-$workoutTemplateId-${startTime.millisecondsSinceEpoch}',
    userId: 'u1',
    workoutTemplateId: workoutTemplateId,
    workoutName: 'Test',
    startTime: startTime,
    exercises: const [],
  );
}

ScheduledWorkout _scheduled(
  String workoutTemplateId,
  DateTime scheduledDate, {
  bool isCompleted = false,
}) {
  return ScheduledWorkout(
    id: 'sc-$workoutTemplateId',
    userId: 'u1',
    workoutTemplateId: workoutTemplateId,
    workoutName: 'Test',
    scheduledDate: scheduledDate,
    isCompleted: isCompleted,
  );
}

void main() {
  group('selectHeroWorkout', () {
    test('una sessione gia avviata vince su tutto il resto', () {
      final active = _template('active');
      final result = selectHeroWorkout(
        activeProgram: _program(['a', 'b']),
        sessions: const [],
        workouts: [_template('a'), _template('b'), active],
        scheduledWorkouts: [_scheduled('a', DateTime.now())],
        activeSessionWorkout: active,
      );

      expect(result.targetWorkout?.id, 'active');
      expect(result.scheduledWorkoutIdForAction, isNull);
    });

    test(
        'un allenamento programmato per oggi, non ancora fatto, vince sul ciclo del programma',
        () {
      final result = selectHeroWorkout(
        activeProgram: _program(['a', 'b']),
        sessions: [_session('a', DateTime.now().subtract(const Duration(days: 1)))],
        workouts: [_template('a'), _template('b')],
        scheduledWorkouts: [_scheduled('b', DateTime.now())],
        activeSessionWorkout: null,
      );

      // Il ciclo del programma da solo suggerirebbe 'b' (il passo dopo 'a'),
      // ma qui deve arrivarci per la via della programmazione, non del ciclo:
      // lo prova scheduledWorkoutIdForAction, che il ciclo non valorizza mai.
      expect(result.targetWorkout?.id, 'b');
      expect(result.scheduledWorkoutIdForAction, 'sc-b');
    });

    test('un allenamento programmato per oggi ma gia segnato come fatto viene ignorato', () {
      final result = selectHeroWorkout(
        activeProgram: _program(['a', 'b']),
        sessions: const [],
        workouts: [_template('a'), _template('b')],
        scheduledWorkouts: [
          _scheduled('b', DateTime.now(), isCompleted: true),
        ],
        activeSessionWorkout: null,
      );

      expect(result.scheduledWorkoutIdForAction, isNull);
      expect(result.targetWorkout?.id, 'a');
    });

    test('un allenamento programmato per un altro giorno viene ignorato', () {
      final result = selectHeroWorkout(
        activeProgram: _program(['a', 'b']),
        sessions: const [],
        workouts: [_template('a'), _template('b')],
        scheduledWorkouts: [
          _scheduled('b', DateTime.now().add(const Duration(days: 3))),
        ],
        activeSessionWorkout: null,
      );

      expect(result.scheduledWorkoutIdForAction, isNull);
      expect(result.targetWorkout?.id, 'a');
    });

    test('senza programmazione per oggi, propone il passo dopo l ultima sessione del programma',
        () {
      final result = selectHeroWorkout(
        activeProgram: _program(['a', 'b', 'c']),
        sessions: [_session('b', DateTime.now().subtract(const Duration(days: 1)))],
        workouts: [_template('a'), _template('b'), _template('c')],
        scheduledWorkouts: const [],
        activeSessionWorkout: null,
      );

      expect(result.targetWorkout?.id, 'c');
      expect(result.nextWorkout?.id, 'a');
    });

    test('senza programma attivo ne programmazione, ricade sul primo modello disponibile', () {
      final result = selectHeroWorkout(
        activeProgram: null,
        sessions: const [],
        workouts: [_template('a'), _template('b')],
        scheduledWorkouts: const [],
        activeSessionWorkout: null,
      );

      expect(result.targetWorkout?.id, 'a');
      expect(result.scheduledWorkoutIdForAction, isNull);
    });
  });
}
