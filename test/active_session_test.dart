import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/active_session_provider.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testWorkout = WorkoutTemplate(
    id: 'w1',
    userId: 'u1',
    name: 'Allenamento Test',
    category: ExerciseType.strength,
    exercises: [
      WorkoutTemplateExercise(
        exerciseId: 'ex1',
        exerciseName: 'Panca Piana',
        type: ExerciseType.strength,
        targetSets: 3,
        targetReps: '10',
        targetWeight: 60,
        restSeconds: 90,
      ),
    ],
  );

  group('ActiveSessionNotifier', () {
    test('inizializza senza sessione attiva', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(activeSessionNotifierProvider);
      expect(state.isActive, isFalse);
      expect(state.workout, isNull);
      expect(state.elapsedDuration, equals(Duration.zero));
    });

    test('avvia una nuova sessione e clona gli esercizi', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeSessionNotifierProvider.notifier);
      notifier.startOrResumeSession(testWorkout);

      final state = container.read(activeSessionNotifierProvider);
      expect(state.isActive, isTrue);
      expect(state.workout?.name, equals('Allenamento Test'));
      expect(state.sessionExercises.length, equals(1));
      expect(state.sessionExercises.first.sets.length, equals(3));
    });

    test('riprende la sessione se e gia attiva per lo stesso allenamento senza resettare startedAt', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeSessionNotifierProvider.notifier);
      notifier.startOrResumeSession(testWorkout);

      final firstState = container.read(activeSessionNotifierProvider);
      final firstStart = firstState.startedAt;

      await Future.delayed(const Duration(milliseconds: 50));

      notifier.startOrResumeSession(testWorkout);
      final secondState = container.read(activeSessionNotifierProvider);

      expect(secondState.startedAt, equals(firstStart));
    });

    test('endSession azzera la sessione attiva', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeSessionNotifierProvider.notifier);
      notifier.startOrResumeSession(testWorkout);
      notifier.endSession();

      final state = container.read(activeSessionNotifierProvider);
      expect(state.isActive, isFalse);
      expect(state.workout, isNull);
    });
  });
}
