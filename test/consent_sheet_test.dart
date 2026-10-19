import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/models/consent.dart';
import 'package:gymflow/src/ui/widgets/consent_sheet.dart';
import 'package:gymflow/src/ui/widgets/immersivo_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Il foglio che il cliente vede prima di accettare un trainer, e il riquadro
/// per categoria che riusa anche nel dettaglio della connessione (US-092).
///
/// **Limite dichiarato**: questi test provano il foglio come widget — cosa
/// mostra, cosa restituisce. Non provano che `connect_friend_screen.dart` lo
/// apra al tocco su «Accetta», né che scriva solo dopo la conferma: quella
/// schermata istanzia Firebase e non si monta in un test (debito US-008).
/// Il cablaggio resta da confermare sull'APK.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Future<ConsentGrants?>? risultato;

  Widget host(Widget Function(BuildContext) corpo) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme(AppPalette.accent),
        home: Scaffold(body: Builder(builder: corpo)),
      ),
    );
  }

  Future<void> apriIlFoglio(WidgetTester tester) async {
    risultato = null;
    await tester.pumpWidget(
      host(
        (context) => Center(
          child: ElevatedButton(
            onPressed: () => risultato = showConsentSheet(context, 'Tina'),
            child: const Text('apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
  }

  List<bool> valoriDegliInterruttori(WidgetTester tester) => tester
      .widgetList<ImmersivoSwitch>(find.byType(ImmersivoSwitch))
      .map((s) => s.value)
      .toList();

  group('ConsentSheet', () {
    testWidgets('dice chi chiede e cosa aprirebbe ciascuna categoria, prima di confermare', (
      tester,
    ) async {
      await apriIlFoglio(tester);

      expect(find.text('COSA PUÒ VEDERE TINA'), findsOneWidget);
      // Entrambe le categorie, con titolo **e** descrizione: il titolo da solo
      // non dice che «Allenamenti» comprende anche carichi e note.
      expect(find.text('Allenamenti'), findsOneWidget);
      expect(find.textContaining('RPE'), findsOneWidget);
      expect(find.text('Peso e misure'), findsOneWidget);
      expect(find.textContaining('misure corporee'), findsOneWidget);
      // E cosa resta privato.
      expect(find.textContaining('restano privati'), findsOneWidget);
    });

    testWidgets('gli interruttori partono spenti: non si concede per inerzia', (tester) async {
      await apriIlFoglio(tester);

      expect(valoriDegliInterruttori(tester), [false, false, false]);
    });

    testWidgets('accettare senza toccare nulla restituisce un legame senza dati', (tester) async {
      await apriIlFoglio(tester);

      await tester.tap(find.text('Accetta'));
      await tester.pumpAndSettle();

      expect(await risultato, ConsentGrants.none);
    });

    testWidgets('accendere solo gli allenamenti concede solo quelli', (tester) async {
      await apriIlFoglio(tester);

      await tester.tap(find.byType(ImmersivoSwitch).first);
      await tester.pump();
      expect(valoriDegliInterruttori(tester), [true, false, false]);

      await tester.tap(find.text('Accetta'));
      await tester.pumpAndSettle();

      final grants = await risultato;
      expect(grants?.sessions, isTrue);
      expect(grants?.measurements, isFalse);
    });

    testWidgets('accendere solo peso e misure concede solo quelle', (tester) async {
      await apriIlFoglio(tester);

      await tester.tap(find.byType(ImmersivoSwitch).at(1));
      await tester.pump();
      expect(valoriDegliInterruttori(tester), [false, true, false]);

      await tester.tap(find.text('Accetta'));
      await tester.pumpAndSettle();

      final grants = await risultato;
      expect(grants?.sessions, isFalse);
      expect(grants?.measurements, isTrue);
    });

    testWidgets('il terzo permesso, Schede, dice cosa concede e cosa no', (tester) async {
      await apriIlFoglio(tester);

      expect(find.text('Schede'), findsOneWidget);
      // Dice che scrive **nuove** schede e solo le sue, che non tocca le altre, e
      // che arrivano spente: sono le tre cose che il cliente deve sapere.
      expect(find.textContaining('nuove schede'), findsOneWidget);
      expect(find.textContaining('solo quelle che ha scritto lui'), findsOneWidget);
      expect(find.textContaining('arrivano spente'), findsOneWidget);
    });

    testWidgets('accendere solo Schede concede solo la scrittura, non la lettura', (tester) async {
      await apriIlFoglio(tester);

      await tester.tap(find.byType(ImmersivoSwitch).last);
      await tester.pump();
      expect(valoriDegliInterruttori(tester), [false, false, true]);

      await tester.tap(find.text('Accetta'));
      await tester.pumpAndSettle();

      final grants = await risultato;
      expect(grants?.programs, isTrue);
      expect(grants?.sessions, isFalse);
      expect(grants?.measurements, isFalse);
    });

    testWidgets('la frase sui dati che restano privati non promette più che nessuno li modifichi', (tester) async {
      await apriIlFoglio(tester);

      // US-092 diceva «nessuno può modificare i tuoi dati»: con il permesso di
      // scrittura non è più vero, e la frase nuova non lo dice.
      expect(find.textContaining('nessuno può modificare'), findsNothing);
      expect(find.textContaining('già scritte'), findsWidgets);
    });

    testWidgets('si può ripensarci prima di confermare: acceso e spento torna a niente', (
      tester,
    ) async {
      await apriIlFoglio(tester);

      await tester.tap(find.byType(ImmersivoSwitch).first);
      await tester.pump();
      await tester.tap(find.byType(ImmersivoSwitch).first);
      await tester.pump();

      await tester.tap(find.text('Accetta'));
      await tester.pumpAndSettle();

      expect(await risultato, ConsentGrants.none);
    });

    testWidgets('annullare non restituisce niente: nessuna concessione, nessun legame', (
      tester,
    ) async {
      await apriIlFoglio(tester);

      await tester.tap(find.byType(ImmersivoSwitch).first);
      await tester.pump();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      // `null`, non `none`: chi chiama distingue «rinuncio» da «accetto senza
      // concedere», e solo il secondo accetta l'invito.
      expect(await risultato, isNull);
    });

    testWidgets('sta su uno schermo piccolo senza andare in overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await apriIlFoglio(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Accetta'), findsOneWidget);
    });
  });

  group('ConsentCategoryTile', () {
    testWidgets('ogni interruttore muove solo la propria categoria', (tester) async {
      final chiamate = <(ConsentCategory, bool)>[];
      await tester.pumpWidget(
        host(
          (context) => Column(
            children: [
              for (final category in ConsentCategory.values)
                ConsentCategoryTile(
                  category: category,
                  value: false,
                  onChanged: (value) => chiamate.add((category, value)),
                ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(ImmersivoSwitch).at(1));
      expect(chiamate, [(ConsentCategory.measurements, true)]);

      await tester.tap(find.byType(ImmersivoSwitch).first);
      expect(chiamate, [
        (ConsentCategory.measurements, true),
        (ConsentCategory.sessions, true),
      ]);

      await tester.tap(find.byType(ImmersivoSwitch).last);
      expect(chiamate.last, (ConsentCategory.programs, true));
      expect(chiamate, hasLength(3), reason: 'ogni tocco muove una sola categoria');
    });

    testWidgets('mostra lo stato che riceve, anche acceso', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => ConsentCategoryTile(
            category: ConsentCategory.sessions,
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      expect(valoriDegliInterruttori(tester), [true]);
    });

    testWidgets('senza onChanged il riquadro è disabilitato e non scrive nulla', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => const ConsentCategoryTile(
            category: ConsentCategory.measurements,
            value: false,
            onChanged: null,
          ),
        ),
      );

      final interruttore = tester.widget<ImmersivoSwitch>(find.byType(ImmersivoSwitch));
      expect(interruttore.onChanged, isNull);
      await tester.tap(find.byType(ImmersivoSwitch));
      expect(valoriDegliInterruttori(tester), [false]);
    });
  });
}
