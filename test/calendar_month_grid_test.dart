import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/workout_type.dart';
import 'package:gymflow/src/ui/screens/calendar_screen.dart';

/// Una sessione minima del tipo indicato, per i test della barra colorata
/// della cella del calendario. L'id non serve a essere univoco: la funzione
/// sotto test legge solo il tipo.
WorkoutSession _session(String workoutType) {
  return WorkoutSession(
    id: 's1',
    userId: 'u1',
    workoutTemplateId: 't1',
    workoutName: 'Test',
    startTime: DateTime(2026, 9, 12),
    exercises: const [],
    workoutType: workoutType,
  );
}

void main() {
  group('orderedSessionTypes', () {
    test('un giorno senza sessioni non ha tipi', () {
      expect(orderedSessionTypes(const []), isEmpty);
    });

    test('un giorno con una sessione ha un solo tipo', () {
      final types = orderedSessionTypes([_session('cardio')]);
      expect(types, [WorkoutType.cardio]);
    });

    test('due sessioni dello stesso tipo non duplicano il tipo', () {
      final types = orderedSessionTypes([
        _session('strength'),
        _session('strength'),
      ]);
      expect(types, [WorkoutType.strength]);
    });

    test('più tipi lo stesso giorno restano nell\'ordine fisso di WorkoutType',
        () {
      // Inseriti in ordine sparso apposta: l'ordine del risultato deve venire
      // da WorkoutType.values, non dall'ordine di inserimento.
      final types = orderedSessionTypes([
        _session('sport'),
        _session('strength'),
        _session('mobility'),
      ]);
      expect(types, [
        WorkoutType.strength,
        WorkoutType.mobility,
        WorkoutType.sport,
      ]);
    });

    test('un allenamento programmato (non fatto) non conta come tipo', () {
      final scheduled = ScheduledWorkout(
        id: 'sc1',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Programmato',
        scheduledDate: DateTime(2026, 9, 12),
      );
      expect(orderedSessionTypes([scheduled]), isEmpty);
    });
  });
}
