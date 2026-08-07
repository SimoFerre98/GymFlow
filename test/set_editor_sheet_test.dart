import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/ui/widgets/set_editor_sheet.dart';
import 'package:gymflow/src/ui/widgets/set_value_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Widget host({
    required WorkoutSet set,
    WorkoutSet? previous,
    bool showWeight = true,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SetEditorSheet(
            set: set,
            setNumber: 3,
            exerciseName: 'Panca piana',
            previous: previous,
            showWeight: showWeight,
          ),
        ),
      ),
    );
  }

  List<SetValueSlider> slidersOf(WidgetTester tester) =>
      tester.widgetList<SetValueSlider>(find.byType(SetValueSlider)).toList();

  group('i passi che chiede il criterio', () {
    testWidgets('2,5 kg per il carico, 1 per ripetizioni e sforzo', (
      tester,
    ) async {
      await tester.pumpWidget(host(set: WorkoutSet(weight: 60, reps: 8)));

      final sliders = slidersOf(tester);
      expect(sliders, hasLength(3));
      expect(sliders[0].step, 2.5, reason: 'carico');
      expect(sliders[1].step, 1, reason: 'ripetizioni');
      expect(sliders[2].step, 1, reason: 'sforzo percepito');
    });

    testWidgets('senza carico restano due cursori', (tester) async {
      // Corpo libero: il carico non ha senso, e un cursore fermo a zero
      // sarebbe un invito a impostare un valore che non esiste.
      await tester.pumpWidget(
        host(set: WorkoutSet(reps: 12), showWeight: false),
      );

      expect(slidersOf(tester), hasLength(2));
    });
  });

  group('valori iniziali', () {
    testWidgets('vengono dalla serie precedente', (tester) async {
      await tester.pumpWidget(
        host(
          set: WorkoutSet(weight: 0, reps: 0),
          previous: WorkoutSet(weight: 60, reps: 8, rpe: 7),
        ),
      );

      final sliders = slidersOf(tester);
      expect(sliders[0].value, 60);
      expect(sliders[1].value, 8);
      expect(sliders[2].value, 7);
    });

    testWidgets('senza serie precedente valgono quelli della serie', (
      tester,
    ) async {
      await tester.pumpWidget(host(set: WorkoutSet(weight: 45, reps: 12)));

      final sliders = slidersOf(tester);
      expect(sliders[0].value, 45);
      expect(sliders[1].value, 12);
    });

    testWidgets('con tutto a zero si parte da valori sensati, non da zero', (
      tester,
    ) async {
      // Un cursore a zero ripetizioni non e un punto di partenza: e un valore
      // che nessuno vuole registrare.
      await tester.pumpWidget(host(set: WorkoutSet(weight: 0, reps: 0)));

      final sliders = slidersOf(tester);
      expect(sliders[0].value, greaterThan(0));
      expect(sliders[1].value, greaterThan(0));
    });
  });

  group('la serie precedente come riferimento', () {
    testWidgets('e visibile mentre si imposta la nuova', (tester) async {
      await tester.pumpWidget(
        host(
          set: WorkoutSet(weight: 0, reps: 0),
          previous: WorkoutSet(weight: 60, reps: 8),
        ),
      );

      expect(find.text('60 kg × 8'), findsOneWidget);
    });

    testWidgets('un carico con decimali si scrive con la virgola', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          set: WorkoutSet(weight: 0, reps: 0),
          previous: WorkoutSet(weight: 62.5, reps: 8),
        ),
      );

      expect(find.text('62,5 kg × 8'), findsOneWidget);
    });

    testWidgets('alla prima serie non compare', (tester) async {
      await tester.pumpWidget(host(set: WorkoutSet(weight: 60, reps: 8)));

      expect(find.textContaining('×'), findsNothing);
    });
  });

  group('la via d uscita da tastiera', () {
    testWidgets('carico e ripetizioni si possono digitare', (tester) async {
      // Il criterio la chiede "per i casi fuori scala": il bilanciere da
      // 137,5 kg quando il cursore arriva a 300 a passi di 2,5.
      await tester.pumpWidget(host(set: WorkoutSet(weight: 60, reps: 8)));

      final sliders = slidersOf(tester);
      expect(sliders[0].onTapValue, isNotNull, reason: 'carico');
      expect(sliders[1].onTapValue, isNotNull, reason: 'ripetizioni');
    });

    testWidgets('toccando il carico si apre un campo numerico', (tester) async {
      await tester.pumpWidget(host(set: WorkoutSet(weight: 60, reps: 8)));

      await tester.tap(find.text('60 kg'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('lo sforzo percepito non ha bisogno della tastiera', (
      tester,
    ) async {
      // Va da 1 a 10: non esistono casi fuori scala.
      await tester.pumpWidget(host(set: WorkoutSet(weight: 60, reps: 8)));

      expect(slidersOf(tester)[2].onTapValue, isNull);
    });
  });

  group('cosa restituisce', () {
    testWidgets('i tre valori impostati', (tester) async {
      SetValues? result;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await SetEditorSheet.show(
                      context,
                      set: WorkoutSet(weight: 60, reps: 8),
                      setNumber: 1,
                      exerciseName: 'Panca piana',
                    );
                  },
                  child: const Text('apri'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chiudi la serie'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.weight, 60);
      expect(result!.reps, 8);
      expect(result!.rpe, isNotNull);
    });

    testWidgets('senza carico restituisce zero, non un valore inventato', (
      tester,
    ) async {
      SetValues? result;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await SetEditorSheet.show(
                      context,
                      set: WorkoutSet(reps: 12),
                      setNumber: 1,
                      exerciseName: 'Trazioni',
                      showWeight: false,
                    );
                  },
                  child: const Text('apri'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chiudi la serie'));
      await tester.pumpAndSettle();

      expect(result!.weight, 0);
      expect(result!.reps, 12);
    });
  });

  group('lo sforzo percepito e un dato vitale', () {
    testWidgets('usa il colore riservato ai dati vitali, non quello azioni', (
      tester,
    ) async {
      // La palette riserva il salmone ai dati vitali e l'ambra alle azioni.
      // Carico e ripetizioni si impostano, lo sforzo si dichiara.
      await tester.pumpWidget(host(set: WorkoutSet(weight: 60, reps: 8)));

      final scheme = Theme.of(
        tester.element(find.byType(SetEditorSheet)),
      ).colorScheme;
      final sliders = slidersOf(tester);

      expect(sliders[2].color, scheme.tertiary);
      expect(sliders[0].color, isNull, reason: 'carico usa il primario');
    });
  });
}
