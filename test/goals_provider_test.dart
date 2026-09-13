import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymflow/src/core/providers/goals_provider.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/user_goal.dart';
import 'package:gymflow/src/models/workout.dart';

/// Un obiettivo `targetLoad` senza `exerciseId` non deve muoversi.
///
/// `goals_screen.dart` («Nuovo obiettivo») crea sempre `GoalType.targetLoad`,
/// qualunque sia il titolo o l'unità scelti dall'utente, e non lascia mai
/// scegliere un esercizio — quindi ogni obiettivo creato da lì ha
/// `exerciseId == null`. Prima di questo fix, `updateProgressFromSessions`
/// interpretava un `exerciseId` nullo come "qualunque esercizio va bene": un
/// obiettivo "Corri 10 km" risultava "raggiunto al 100%" sollevando 60 kg in
/// uno squat, perché quel numero diventava comunque il nuovo massimo.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  WorkoutSession sessioneConSerie(String exerciseId, double peso) => WorkoutSession(
        id: 's1',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Gambe',
        startTime: DateTime.now(),
        exercises: [
          WorkoutExercise(
            exerciseId: exerciseId,
            exerciseName: 'Squat',
            sets: [WorkoutSet(weight: peso, reps: 5, isCompleted: true)],
          ),
        ],
      );

  test('obiettivo targetLoad senza exerciseId: il progresso non si muove', () {
    final container = ProviderContainer(
      overrides: [
        userGoalsNotifierProvider.overrideWith(
          () => _GoalsConSemeUnico(
            UserGoal(
              id: 'g1',
              userId: 'local',
              title: 'Corri 10 km',
              type: GoalType.targetLoad,
              targetValue: 10.0,
              currentValue: 0.0,
              unit: 'km',
              createdAt: DateTime.now(),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(userGoalsNotifierProvider.notifier)
        .updateProgressFromSessions([sessioneConSerie('squat', 60.0)]);

    final goal = container.read(userGoalsNotifierProvider).first;
    expect(goal.currentValue, 0.0, reason: '60 kg di squat non e una corsa');
    expect(goal.isAchieved, isFalse);
  });

  test('obiettivo targetLoad con exerciseId: il progresso segue solo quell esercizio', () {
    final container = ProviderContainer(
      overrides: [
        userGoalsNotifierProvider.overrideWith(
          () => _GoalsConSemeUnico(
            UserGoal(
              id: 'g2',
              userId: 'local',
              title: 'Squat 100 kg',
              type: GoalType.targetLoad,
              targetValue: 100.0,
              currentValue: 60.0,
              unit: 'kg',
              exerciseId: 'squat',
              createdAt: DateTime.now(),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(userGoalsNotifierProvider.notifier).updateProgressFromSessions([
      sessioneConSerie('panca', 120.0), // altro esercizio: non deve contare
      sessioneConSerie('squat', 105.0),
    ]);

    final goal = container.read(userGoalsNotifierProvider).first;
    expect(goal.currentValue, 105.0);
    expect(goal.isAchieved, isTrue);
  });
}

class _GoalsConSemeUnico extends UserGoalsNotifier {
  _GoalsConSemeUnico(this._seme);
  final UserGoal _seme;

  @override
  List<UserGoal> build() => [_seme];
}
