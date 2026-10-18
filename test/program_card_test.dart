import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/ui/widgets/program_card.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La scheda nella lista: il colore scelto si vede, l'attiva si distingue, i
/// numeri vengono dalle date e non si inventano quando mancano.
///
/// **Limite dichiarato**: provano struttura e valori, non che «sia bella».
/// Il giudizio sul disegno e sull'APK.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // L'app lo fa all'avvio: senza, `DateFormat` in italiano lancia e la card
    // con le date non si disegna.
    await initializeDateFormatting('it');
  });

  WorkoutProgram scheda({
    String name = 'Forza 5x5',
    bool attiva = false,
    int colore = 0xFFE91E63,
    int giorni = 4,
    DateTime? inizio,
    DateTime? fine,
    String? descrizione,
  }) => WorkoutProgram(
    id: 'p1',
    userId: 'u1',
    name: name,
    description: descrizione,
    workoutIds: [for (var i = 0; i < giorni; i++) 'w$i'],
    isActive: attiva,
    createdAt: DateTime(2026, 1, 1),
    startDate: inizio,
    endDate: fine,
    color: colore,
  );

  // 8 settimane esatte: lunedi 5 ottobre -> domenica 29 novembre 2026.
  final inizio = DateTime(2026, 10, 5);
  final fine = DateTime(2026, 11, 29);

  Widget host(WorkoutProgram p, {DateTime? oggi, VoidCallback? onTap, VoidCallback? onDelete}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme(AppPalette.accent),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProgramCard(
              program: p,
              now: oggi ?? DateTime(2026, 10, 20),
              onTap: onTap ?? () {},
              onDelete: onDelete ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  Finder striscia(int colore) => find.byWidgetPredicate(
    (w) => w is Container && w.color == Color(colore) && w.constraints?.maxWidth == 6,
  );

  /// La decorazione esterna: l'unica `DecoratedBox` con un bordo pieno.
  BoxDecoration decorazioneEsterna(WidgetTester tester) {
    final scatole = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).toList();
    return scatole
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.border != null && d.color != null);
  }

  group('il colore scelto dall utente', () {
    testWidgets('si vede come striscia a sinistra', (tester) async {
      await tester.pumpWidget(host(scheda(colore: 0xFFE91E63)));
      expect(striscia(0xFFE91E63), findsOneWidget);
    });

    testWidgets('segue il colore della scheda, non uno fisso', (tester) async {
      await tester.pumpWidget(host(scheda(colore: 0xFF4CAF50)));
      expect(striscia(0xFF4CAF50), findsOneWidget);
      expect(striscia(0xFFE91E63), findsNothing);
    });
  });

  group('la scheda attiva', () {
    testWidgets('ha il bagliore e il bordo d azione, l inattiva no', (tester) async {
      await tester.pumpWidget(host(scheda(attiva: true)));
      final scheme = Theme.of(tester.element(find.byType(ProgramCard))).colorScheme;
      final attiva = decorazioneEsterna(tester);
      expect(attiva.boxShadow, isNotEmpty, reason: 'bagliore');
      expect((attiva.border! as Border).top.color, scheme.primary);

      await tester.pumpWidget(host(scheda(attiva: false)));
      final inattiva = decorazioneEsterna(tester);
      expect(inattiva.boxShadow, anyOf(isNull, isEmpty), reason: 'nessun bagliore');
      expect((inattiva.border! as Border).top.color, scheme.outline);
    });

    testWidgets('porta la pillola ATTIVA, l inattiva no', (tester) async {
      await tester.pumpWidget(host(scheda(attiva: true)));
      expect(find.text('ATTIVA'), findsOneWidget);
      await tester.pumpWidget(host(scheda(attiva: false)));
      expect(find.text('ATTIVA'), findsNothing);
    });
  });

  group('i numeri', () {
    testWidgets('i giorni della scheda sono sempre in evidenza', (tester) async {
      await tester.pumpWidget(host(scheda(giorni: 5)));
      expect(find.text('5'), findsOneWidget);
      expect(find.text('GIORNI'), findsOneWidget);
    });

    testWidgets('con un solo giorno l etichetta e al singolare', (tester) async {
      await tester.pumpWidget(host(scheda(giorni: 1)));
      expect(find.text('GIORNO'), findsOneWidget);
      expect(find.text('GIORNI'), findsNothing);
    });

    testWidgets('con piu giorni, o nessuno, resta al plurale', (tester) async {
      await tester.pumpWidget(host(scheda(giorni: 0)));
      expect(find.text('GIORNI'), findsOneWidget);
      await tester.pumpWidget(host(scheda(giorni: 2)));
      expect(find.text('GIORNI'), findsOneWidget);
    });

    testWidgets('con le date mostra la settimana su quelle totali e la barra', (tester) async {
      await tester.pumpWidget(host(scheda(inizio: inizio, fine: fine), oggi: DateTime(2026, 10, 20)));
      expect(find.text('3/8'), findsOneWidget);
      expect(find.text('SETTIMANA'), findsOneWidget);
      final barra = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(barra.value, closeTo(3 / 8, 1e-9));
    });

    testWidgets('senza data di fine mostra la settimana ma nessuna barra', (tester) async {
      await tester.pumpWidget(host(scheda(inizio: inizio), oggi: DateTime(2026, 10, 20)));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('SETTIMANA'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('senza date non inventa nessuna settimana', (tester) async {
      await tester.pumpWidget(host(scheda()));
      expect(find.text('SETTIMANA'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Nessuna data'), findsOneWidget);
    });

    testWidgets('prima dell inizio conta i giorni che mancano', (tester) async {
      await tester.pumpWidget(host(scheda(inizio: inizio, fine: fine), oggi: DateTime(2026, 9, 28)));
      expect(find.text('7'), findsOneWidget);
      expect(find.text("GIORNI ALL'INIZIO"), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('a scheda conclusa lo dice', (tester) async {
      await tester.pumpWidget(host(scheda(inizio: inizio, fine: fine), oggi: DateTime(2026, 12, 3)));
      expect(find.text('SETTIMANE · CONCLUSA'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('l intervallo delle date resta scritto per esteso', (tester) async {
      await tester.pumpWidget(host(scheda(inizio: inizio, fine: fine)));
      expect(find.textContaining('2026'), findsWidgets);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });
  });

  group('interazione', () {
    testWidgets('il tocco sulla card chiama onTap', (tester) async {
      var toccata = 0;
      await tester.pumpWidget(host(scheda(), onTap: () => toccata++));
      await tester.tap(find.text('Forza 5x5'));
      expect(toccata, 1);
    });

    testWidgets('il menu elimina chiama onDelete e non apre la scheda', (tester) async {
      var eliminata = 0;
      var aperta = 0;
      await tester.pumpWidget(host(scheda(), onTap: () => aperta++, onDelete: () => eliminata++));
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      expect(eliminata, 1);
      expect(aperta, 0);
    });
  });

  group('robustezza', () {
    testWidgets('un nome lunghissimo e una descrizione lunga non vanno in overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          scheda(
            name: 'Programma di forza e ipertrofia per la preparazione estiva senza fine',
            descrizione: List.filled(30, 'descrizione molto lunga').join(' '),
            attiva: true,
            inizio: inizio,
            fine: fine,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('con zero giorni mostra 0, non crasha', (tester) async {
      await tester.pumpWidget(host(scheda(giorni: 0)));
      expect(find.text('0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
