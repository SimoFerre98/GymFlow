import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/body_measurement.dart';
import 'package:gymflow/src/models/local/local_body_measurement.dart';
import 'package:gymflow/src/models/mappers/body_measurement_mapper.dart';

void main() {
  group('Domain → Local → Domain round-trip', () {
    test('misura completa: tutti i campi sopravvivono', () {
      final original = BodyMeasurement(
        id: 'meas-abc-123',
        userId: 'user-42',
        date: DateTime.utc(2026, 9, 1),
        weight: 78.4,
        height: 181.0,
        chest: 102.5,
        waist: 84.0,
        hips: 98.0,
        biceps: 36.5,
        thighs: 58.0,
        calves: 39.0,
        shoulders: 118.0,
        neck: 39.5,
        bodyFatPercentage: 14.2,
      );
      final restored = original.toLocal().toDomain();

      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.date, equals(original.date));
      expect(restored.weight, equals(original.weight));
      expect(restored.height, equals(original.height));
      expect(restored.chest, equals(original.chest));
      expect(restored.waist, equals(original.waist));
      expect(restored.hips, equals(original.hips));
      expect(restored.biceps, equals(original.biceps));
      expect(restored.thighs, equals(original.thighs));
      expect(restored.calves, equals(original.calves));
      expect(restored.shoulders, equals(original.shoulders));
      expect(restored.neck, equals(original.neck));
      expect(restored.bodyFatPercentage, equals(original.bodyFatPercentage));
    });

    test('misura minima: tutti i campi opzionali nulli', () {
      final original = BodyMeasurement(
        id: 'meas-min',
        userId: 'user-1',
        date: DateTime.utc(2026, 1, 1),
      );
      final restored = original.toLocal().toDomain();

      expect(restored.id, equals(original.id));
      expect(restored.weight, isNull);
      expect(restored.height, isNull);
      expect(restored.bodyFatPercentage, isNull);
    });
  });

  group('Simmetria Local → Domain → Local', () {
    test('un LocalBodyMeasurement popolato sopravvive al doppio salto', () {
      final local = LocalBodyMeasurement()
        ..firestoreId = 'fs-meas-1'
        ..userId = 'uid-1'
        ..date = DateTime.utc(2026, 6, 15)
        ..weight = 80.1
        ..waist = 85.0;

      final backToLocal = local.toDomain().toLocal();

      expect(backToLocal.firestoreId, equals(local.firestoreId));
      expect(backToLocal.userId, equals(local.userId));
      expect(backToLocal.date, equals(local.date));
      expect(backToLocal.weight, equals(local.weight));
      expect(backToLocal.waist, equals(local.waist));
      expect(backToLocal.height, isNull);
    });
  });
}
