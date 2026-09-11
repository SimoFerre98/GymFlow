import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/ui/screens/calendar_screen.dart';

WorkoutTemplate _template(String id, {String? parentProgramId}) {
  return WorkoutTemplate(
    id: id,
    userId: 'u1',
    name: 'Scheda $id',
    parentProgramId: parentProgramId,
    exercises: const [],
    category: ExerciseType.strength,
  );
}

WorkoutProgram _program(String id, {required int color}) {
  return WorkoutProgram(
    id: id,
    userId: 'u1',
    name: 'Programma $id',
    workoutIds: const [],
    createdAt: DateTime(2026, 1, 1),
    color: color,
  );
}

void main() {
  group('resolveColorByTemplateId', () {
    test('una scheda dentro un programma prende il colore del programma', () {
      final colors = resolveColorByTemplateId(
        [_template('t1', parentProgramId: 'p1')],
        [_program('p1', color: 0xFFAA0000)],
      );

      expect(colors['t1'], 0xFFAA0000);
    });

    test('una scheda senza programma ricade sul colore di default', () {
      final colors = resolveColorByTemplateId([_template('t1')], []);

      expect(colors['t1'], AppPalette.defaultProgramColor);
    });

    test('una scheda il cui programma non esiste piu ricade sul colore di default', () {
      final colors = resolveColorByTemplateId(
        [_template('t1', parentProgramId: 'programma-cancellato')],
        [_program('p1', color: 0xFFAA0000)],
      );

      expect(colors['t1'], AppPalette.defaultProgramColor);
    });

    test('due schede dello stesso programma condividono lo stesso colore', () {
      final colors = resolveColorByTemplateId(
        [
          _template('t1', parentProgramId: 'p1'),
          _template('t2', parentProgramId: 'p1'),
        ],
        [_program('p1', color: 0xFF00AA00)],
      );

      expect(colors['t1'], 0xFF00AA00);
      expect(colors['t2'], 0xFF00AA00);
    });
  });
}
