import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/widgets/set_value_slider.dart';

/// Il nodo semantico dello `Slider`, cercato per il suo flag invece che per
/// `find.byType(Slider)`.
///
/// Su questa versione di Flutter, `tester.getSemantics(find.byType(Slider))`
/// risale all'elemento sbagliato — quello dell'`OverlayPortal` che lo
/// `Slider` usa internamente per l'indicatore, non il nodo che porta
/// `value`/`increasedValue`/`decreasedValue` — e torna sempre vuoto. Il nodo
/// giusto esiste ed e popolato correttamente (verificato leggendo l'intero
/// albero semantico): va solo cercato per flag.
SemanticsNode _sliderSemantics(WidgetTester tester) {
  SemanticsNode? found;
  void visit(SemanticsNode node) {
    if (found != null) return;
    if (node.getSemanticsData().flagsCollection.isSlider) {
      found = node;
      return;
    }
    node.visitChildren((child) {
      visit(child);
      return found == null;
    });
  }

  // `rootPipelineOwner`, il rimpiazzo non deprecato, non possiede
  // direttamente un `semanticsOwner` su questa versione di Flutter (lo
  // possiedono i suoi figli, non esposti pubblicamente): resta questa la
  // sola via per arrivare alla radice dell'albero semantico nei test.
  // ignore: deprecated_member_use
  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return found!;
}

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  group('il passo', () {
    testWidgets('i valori emessi sono multipli del passo', (tester) async {
      final emitted = <double>[];
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Carico',
            value: 60,
            min: 0,
            max: 300,
            step: 2.5,
            onChanged: emitted.add,
          ),
        ),
      );

      // Una serie di trascinamenti corti, per raccogliere valori intermedi.
      final slider = find.byType(Slider);
      for (var dx = 10.0; dx <= 60; dx += 10) {
        await tester.drag(slider, Offset(dx, 0));
        await tester.pump();
      }

      expect(emitted, isNotEmpty);
      for (final value in emitted) {
        final steps = value / 2.5;
        expect(
          steps,
          closeTo(steps.roundToDouble(), 0.0001),
          reason: '$value non e un multiplo di 2,5',
        );
      }
    });

    testWidgets('con passo 1 i valori sono interi', (tester) async {
      final emitted = <double>[];
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Ripetizioni',
            value: 8,
            min: 1,
            max: 50,
            step: 1,
            onChanged: emitted.add,
          ),
        ),
      );

      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pump();

      expect(emitted, isNotEmpty);
      for (final value in emitted) {
        expect(value, value.roundToDouble());
      }
    });

    testWidgets('il valore non arrotonda quello di partenza', (tester) async {
      // Una serie salvata a 61,3 kg resta 61,3 finche non la si tocca:
      // inventare 62,5 significherebbe cambiare un dato che l'utente ha scelto.
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Carico',
            value: 61.3,
            min: 0,
            max: 300,
            step: 2.5,
            formatValue: (v) => v.toStringAsFixed(1),
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('61.3'), findsOneWidget);
    });
  });

  group('area di tocco', () {
    testWidgets('e alta almeno 48 dp, come chiede il criterio', (tester) async {
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Carico',
            value: 60,
            min: 0,
            max: 300,
            step: 2.5,
            onChanged: (_) {},
          ),
        ),
      );

      const tokens = ExpressiveTokens();
      final size = tester.getSize(find.byType(Slider));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.height, tokens.sizing.minTouchTarget);
    });
  });

  group('annuncio allo screen reader', () {
    testWidgets('porta valore e unita, non il solo numero', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Carico',
            value: 62.5,
            min: 0,
            max: 300,
            step: 2.5,
            semanticUnit: 'kg',
            formatValue: (v) => '${v.toStringAsFixed(1)} kg',
            onChanged: (_) {},
          ),
        ),
      );

      // "62,5" da solo non dice niente a chi non vede l'etichetta sopra.
      final node = _sliderSemantics(tester);
      expect(node.value, contains('kg'));
      expect(node.increasedValue, contains('kg'));
      expect(node.decreasedValue, contains('kg'));

      handle.dispose();
    });

    testWidgets('senza unita dichiarata annuncia il solo valore', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Ripetizioni',
            value: 8,
            min: 1,
            max: 50,
            step: 1,
            onChanged: (_) {},
          ),
        ),
      );

      final node = _sliderSemantics(tester);
      expect(node.value, '8');

      handle.dispose();
    });
  });

  group('riscontro visivo', () {
    testWidgets('il valore mostrato segue quello passato', (tester) async {
      Widget build(double value) => host(
        SetValueSlider(
          label: 'Carico',
          value: value,
          min: 0,
          max: 300,
          step: 2.5,
          formatValue: (v) => '${v.toStringAsFixed(1)} kg',
          onChanged: (_) {},
        ),
      );

      await tester.pumpWidget(build(60));
      expect(find.text('60.0 kg'), findsOneWidget);

      await tester.pumpWidget(build(62.5));
      await tester.pump();
      expect(find.text('62.5 kg'), findsOneWidget);
      expect(find.text('60.0 kg'), findsNothing);
    });
  });

  group('la via d uscita da tastiera', () {
    testWidgets('toccando il valore si chiama chi apre il campo', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Carico',
            value: 60,
            min: 0,
            max: 300,
            step: 2.5,
            formatValue: (v) => v.toStringAsFixed(0),
            onTapValue: () => tapped++,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('60'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('senza azione il valore non e toccabile', (tester) async {
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Sforzo',
            value: 8,
            min: 1,
            max: 10,
            step: 1,
            onChanged: (_) {},
          ),
        ),
      );

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });
  });

  group('estremi', () {
    testWidgets('un valore oltre il massimo non fa cadere il cursore', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Carico',
            value: 500,
            min: 0,
            max: 300,
            step: 2.5,
            onChanged: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 300);
    });

    testWidgets('un valore sotto il minimo viene riportato dentro', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SetValueSlider(
            label: 'Ripetizioni',
            value: 0,
            min: 1,
            max: 50,
            step: 1,
            onChanged: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 1);
    });
  });
}
