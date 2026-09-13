import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/local/local_workout_program.dart';
import 'package:gymflow/src/models/mappers/program_mapper.dart';

void main() {
  WorkoutProgram makeFullProgram() {
    return WorkoutProgram(
      id: 'prog-abc-123',
      userId: 'user-42',
      name: 'Push Pull Legs',
      description: 'Ciclo di dodici settimane',
      workoutIds: const ['w-1', 'w-2', 'w-3'],
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 1, 8, 0),
      startDate: DateTime.utc(2026, 1, 5),
      endDate: DateTime.utc(2026, 3, 30),
      color: 0xFFAA1122,
    );
  }

  group('Domain → Local → Domain round-trip', () {
    test('programma completo: tutti i campi sopravvivono', () {
      final original = makeFullProgram();
      final restored = original.toLocal().toDomain();

      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.name, equals(original.name));
      expect(restored.description, equals(original.description));
      expect(restored.workoutIds, equals(original.workoutIds));
      expect(restored.isActive, equals(original.isActive));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.startDate, equals(original.startDate));
      expect(restored.endDate, equals(original.endDate));
      expect(restored.color, equals(original.color));
    });

    test('programma minimo: campi opzionali nulli, lista vuota', () {
      final original = WorkoutProgram(
        id: 'prog-min',
        userId: 'user-1',
        name: 'Quick',
        workoutIds: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final restored = original.toLocal().toDomain();

      expect(restored.id, equals(original.id));
      expect(restored.description, isNull);
      expect(restored.workoutIds, isEmpty);
      expect(restored.isActive, isFalse);
      expect(restored.startDate, isNull);
      expect(restored.endDate, isNull);
    });
  });

  group('Simmetria Local → Domain → Local', () {
    test('un LocalWorkoutProgram popolato sopravvive al doppio salto', () {
      final local = LocalWorkoutProgram()
        ..firestoreId = 'fs-prog-1'
        ..userId = 'uid-1'
        ..name = 'Upper Lower'
        ..description = 'Quattro giorni'
        ..workoutIds = ['w-9']
        ..isActive = true
        ..createdAt = DateTime.utc(2026, 2, 1)
        ..startDate = DateTime.utc(2026, 2, 3)
        ..endDate = null
        ..color = 0xFF00FF00;

      final backToLocal = local.toDomain().toLocal();

      expect(backToLocal.firestoreId, equals(local.firestoreId));
      expect(backToLocal.userId, equals(local.userId));
      expect(backToLocal.name, equals(local.name));
      expect(backToLocal.workoutIds, equals(local.workoutIds));
      expect(backToLocal.isActive, equals(local.isActive));
      expect(backToLocal.createdAt, equals(local.createdAt));
      expect(backToLocal.startDate, equals(local.startDate));
      expect(backToLocal.endDate, isNull);
      expect(backToLocal.color, equals(local.color));
    });
  });
}
