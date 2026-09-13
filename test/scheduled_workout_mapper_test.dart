import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/local/local_scheduled_workout.dart';
import 'package:gymflow/src/models/mappers/scheduled_workout_mapper.dart';

void main() {
  group('Domain → Local → Domain round-trip', () {
    test('allenamento programmato: tutti i campi sopravvivono', () {
      final original = ScheduledWorkout(
        id: 'sched-abc-123',
        userId: 'user-42',
        workoutTemplateId: 'tpl-7',
        workoutName: 'Push Day A',
        scheduledDate: DateTime.utc(2026, 9, 15, 18, 30),
        isCompleted: true,
      );
      final restored = original.toLocal().toDomain();

      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.workoutTemplateId, equals(original.workoutTemplateId));
      expect(restored.workoutName, equals(original.workoutName));
      expect(restored.scheduledDate, equals(original.scheduledDate));
      expect(restored.isCompleted, equals(original.isCompleted));
    });

    test('isCompleted false di default sopravvive', () {
      final original = ScheduledWorkout(
        id: 'sched-min',
        userId: 'user-1',
        workoutTemplateId: 'tpl-1',
        workoutName: 'Quick',
        scheduledDate: DateTime.utc(2026, 1, 1),
      );
      final restored = original.toLocal().toDomain();
      expect(restored.isCompleted, isFalse);
    });
  });

  group('Simmetria Local → Domain → Local', () {
    test('un LocalScheduledWorkout popolato sopravvive al doppio salto', () {
      final local = LocalScheduledWorkout()
        ..firestoreId = 'fs-sched-1'
        ..userId = 'uid-1'
        ..workoutTemplateId = 'tpl-3'
        ..workoutName = 'Leg Day'
        ..scheduledDate = DateTime.utc(2026, 10, 1)
        ..isCompleted = false;

      final backToLocal = local.toDomain().toLocal();

      expect(backToLocal.firestoreId, equals(local.firestoreId));
      expect(backToLocal.userId, equals(local.userId));
      expect(backToLocal.workoutTemplateId, equals(local.workoutTemplateId));
      expect(backToLocal.workoutName, equals(local.workoutName));
      expect(backToLocal.scheduledDate, equals(local.scheduledDate));
      expect(backToLocal.isCompleted, equals(local.isCompleted));
    });
  });
}
