import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/user_goal.dart';

void main() {
  group('UserGoal model & progress calculation', () {
    test('progressFraction is correctly clamped between 0.0 and 1.0', () {
      final goal = UserGoal(
        id: 'g1',
        userId: 'u1',
        title: 'Panca 100 kg',
        type: GoalType.targetLoad,
        targetValue: 100.0,
        currentValue: 50.0,
        unit: 'kg',
        createdAt: DateTime.now(),
      );

      expect(goal.progressFraction, equals(0.5));

      final overAchieved = goal.copyWith(currentValue: 120.0);
      expect(overAchieved.progressFraction, equals(1.0));

      final negative = goal.copyWith(currentValue: -10.0);
      expect(negative.progressFraction, equals(0.0));
    });

    test('toMap and fromMap preserve model properties', () {
      final now = DateTime.now();
      final goal = UserGoal(
        id: 'g2',
        userId: 'u2',
        title: '3 allenamenti',
        type: GoalType.workoutFrequency,
        targetValue: 3.0,
        currentValue: 2.0,
        unit: 'allenamenti',
        createdAt: now,
      );

      final map = goal.toMap();
      final restored = UserGoal.fromMap(map, 'g2');

      expect(restored.id, equals('g2'));
      expect(restored.title, equals('3 allenamenti'));
      expect(restored.type, equals(GoalType.workoutFrequency));
      expect(restored.targetValue, equals(3.0));
    });
  });
}
