import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/clients_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/utils/client_overview.dart';
import 'package:gymflow/src/models/invite.dart';
import 'package:gymflow/src/ui/screens/clients_screen.dart';
import 'package:gymflow/src/ui/widgets/expressive_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'elenco clienti del trainer (US-089), come schermata.
///
/// Il provider è sostituito con righe già pronte: la schermata non conosce
/// Firestore, ed è per questo che qui si monta, a differenza delle altre.
///
/// **Limite dichiarato**: provano cosa si legge e cosa succede al tocco, non
/// che la riga «sia bella», né il collegamento vero ai dati (quello è nei test
/// di `client_overview_loader_test.dart`, con una sorgente finta, e sull'APK).
class FintaClientOverview extends ClientOverview {
  FintaClientOverview(this.righe, {this.errore = false});

  final List<ClientRow> righe;
  final bool errore;
  int aggiornamenti = 0;

  @override
  Future<List<ClientRow>> build() async {
    if (errore) throw StateError('rete assente');
    return righe;
  }

  @override
  Future<void> refresh() async => aggiornamenti++;
}

class OsservatoreRotte extends NavigatorObserver {
  final List<Route<dynamic>> spinte = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => spinte.add(route);
}

ClientRow riga(
  String nome,
  ClientActivity attivita, {
  int? giorni,
  String? id,
}) => ClientRow(
  clientId: id ?? nome.toLowerCase(),
  name: nome,
  since: DateTime(2026, 9, 2),
  invite: Invite(
    id: 'inv-$nome',
    fromUserId: 'trainer-1',
    fromDisplayName: 'Tina',
    fromRole: 'trainer',
    toUserId: id ?? nome.toLowerCase(),
    toDisplayName: nome,
    code: 'CODE',
    relationshipType: RelationshipType.trainerClient,
    status: InviteStatus.accepted,
    createdAt: DateTime(2026, 9, 1),
    expiresAt: DateTime(2026, 9, 8),
  ),
  activity: attivita,
  daysSinceLastSession: giorni,
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  late OsservatoreRotte osservatore;

  Future<FintaClientOverview> monta(
    WidgetTester tester,
    List<ClientRow> righe, {
    bool errore = false,
  }) async {
    final finta = FintaClientOverview(righe, errore: errore);
    osservatore = OsservatoreRotte();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clientOverviewProvider.overrideWith(() => finta)],
        child: MaterialApp(
          theme: AppTheme.darkTheme(AppPalette.accent),
          navigatorObservers: [osservatore],
          home: const ClientsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return finta;
  }

  List<ExpressiveCard> carte(WidgetTester tester) =>
      tester.widgetList<ExpressiveCard>(find.byType(ExpressiveCard)).toList();

  group('cosa si legge per ogni cliente', () {
    testWidgets('il nome e una frase che dice cosa si sa dell allenamento', (tester) async {
      await monta(tester, [
        riga('Carla', ClientActivity.overdue, giorni: 12),
        riga('Dario', ClientActivity.noSessions),
        riga('Bruno', ClientActivity.recent, giorni: 3),
        riga('Anna', ClientActivity.notShared),
      ]);
      expect(find.text('Carla'), findsOneWidget);
      expect(find.text('Fermo da 12 giorni'), findsOneWidget);
      expect(find.text('Nessun allenamento ancora'), findsOneWidget);
      expect(find.text('Ultimo allenamento: 3 giorni fa'), findsOneWidget);
      expect(find.text('Allenamenti non condivisi'), findsOneWidget);
    });

    testWidgets('oggi e ieri si dicono a parole, non come 0 e 1 giorni fa', (tester) async {
      await monta(tester, [
        riga('Elena', ClientActivity.recent, giorni: 0),
        riga('Franco', ClientActivity.recent, giorni: 1),
      ]);
      expect(find.text('Ultimo allenamento: oggi'), findsOneWidget);
      expect(find.text('Ultimo allenamento: ieri'), findsOneWidget);
      expect(find.text('OGGI'), findsOneWidget);
      expect(find.text('GIORNO FA'), findsOneWidget);
    });

    testWidgets('il numero grande c e solo dove c è un numero vero', (tester) async {
      await monta(tester, [
        riga('Bruno', ClientActivity.recent, giorni: 3),
        riga('Anna', ClientActivity.notShared),
        riga('Dario', ClientActivity.noSessions),
      ]);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('GIORNI FA'), findsOneWidget, reason: 'solo per Bruno');
      // Chi non condivide, o non ha ancora un allenamento, non deve mostrare
      // un «OGGI» che nasconderebbe l'assenza del dato.
      expect(find.text('OGGI'), findsNothing);
    });
  });

  group('chi è fermo da troppo tempo si distingue', () {
    testWidgets('ha il bordo nel colore dell attenzione, gli altri no', (tester) async {
      await monta(tester, [
        riga('Carla', ClientActivity.overdue, giorni: 12),
        riga('Bruno', ClientActivity.recent, giorni: 3),
        riga('Anna', ClientActivity.notShared),
      ]);
      final scheme = Theme.of(tester.element(find.byType(ClientsScreen))).colorScheme;
      final bordi = carte(tester).map((c) => c.borderColor).toList();
      expect(bordi, [scheme.error, isNull, isNull]);
    });

    testWidgets('la frase e il numero sono nel colore dell attenzione', (tester) async {
      await monta(tester, [riga('Carla', ClientActivity.overdue, giorni: 12)]);
      final scheme = Theme.of(tester.element(find.byType(ClientsScreen))).colorScheme;
      final frase = tester.widget<Text>(find.text('Fermo da 12 giorni'));
      expect(frase.style?.color, scheme.error);
      final numero = tester.widget<Text>(find.text('12'));
      expect(numero.style?.color, scheme.error);
    });

    testWidgets('l ordine è quello del provider: chi sta in cima resta in cima', (tester) async {
      await monta(tester, [
        riga('Carla', ClientActivity.overdue, giorni: 20),
        riga('Elena', ClientActivity.overdue, giorni: 9),
        riga('Bruno', ClientActivity.recent, giorni: 1),
      ]);
      double alto(String nome) => tester.getTopLeft(find.text(nome)).dy;
      expect(alto('Carla'), lessThan(alto('Elena')));
      expect(alto('Elena'), lessThan(alto('Bruno')));
    });
  });

  group('tanti clienti', () {
    testWidgets('venticinque righe: si scorre fino all ultima, nessuna perduta', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await monta(tester, [
        for (var i = 0; i < 25; i++)
          riga('Cliente ${i.toString().padLeft(2, '0')}', ClientActivity.recent, giorni: i % 7, id: 'c$i'),
      ]);
      await tester.scrollUntilVisible(
        find.text('Cliente 24'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Cliente 24'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('senza clienti', () {
    testWidgets('spiega come invitarne uno invece di una schermata vuota', (tester) async {
      await monta(tester, const []);
      expect(find.text('Ancora nessun cliente'), findsOneWidget);
      expect(find.textContaining('Invita come cliente'), findsOneWidget);
      expect(find.text('Invita un cliente'), findsOneWidget);
    });

    testWidgets('il pulsante porta a Connetti', (tester) async {
      await monta(tester, const []);
      final prima = osservatore.spinte.length;
      // Senza `pump` dopo il tocco: la rotta e spinta, ma la schermata di
      // Connetti non viene costruita (istanzia Firebase e qui non c'è).
      await tester.tap(find.text('Invita un cliente'));
      expect(osservatore.spinte.length, prima + 1);
    });
  });

  group('al tocco, in caso di errore, e il resto', () {
    testWidgets('il tocco su un cliente apre il suo dettaglio', (tester) async {
      await monta(tester, [riga('Bruno', ClientActivity.recent, giorni: 3)]);
      final prima = osservatore.spinte.length;
      await tester.tap(find.text('Bruno'));
      expect(osservatore.spinte.length, prima + 1);
    });

    testWidgets('un errore lo dice e «Riprova» rilegge', (tester) async {
      final finta = await monta(tester, const [], errore: true);
      expect(find.text('Non sono riuscito a caricare i clienti'), findsOneWidget);
      expect(find.text('Ancora nessun cliente'), findsNothing, reason: 'un errore non è «nessun cliente»');
      await tester.tap(find.text('Riprova'));
      await tester.pump();
      expect(finta.aggiornamenti, 1);
    });

    testWidgets('«tira per aggiornare» rilegge, anche con pochi clienti', (tester) async {
      final finta = await monta(tester, [riga('Bruno', ClientActivity.recent, giorni: 3)]);
      await tester.fling(find.text('Bruno'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(finta.aggiornamenti, 1);
    });

    testWidgets('c è il tasto indietro verso la Home', (tester) async {
      await monta(tester, const []);
      expect(find.text('← Home'), findsOneWidget);
    });

    testWidgets('lo stato vuoto si aggiorna con il gesto, anche se non c è niente da scorrere', (tester) async {
      final finta = await monta(tester, const []);
      await tester.fling(find.text('Ancora nessun cliente'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(finta.aggiornamenti, 1);
    });
  });

  group('le frasi, in entrambe le lingue', () {
    // `clientSubtitle` e pura: si prova senza montare niente. `Localization`
    // restituisce la **chiave** se manca nel dizionario, quindi una frase non
    // tradotta si riconosce perche contiene un trattino basso.
    const it = Localization(Locale('it'));
    const en = Localization(Locale('en'));

    final casi = <(String, ClientRow, String, String)>[
      ('fermo da troppo tempo', riga('A', ClientActivity.overdue, giorni: 12), 'Fermo da 12 giorni', 'No workout for 12 days'),
      ('oggi', riga('A', ClientActivity.recent, giorni: 0), 'Ultimo allenamento: oggi', 'Last workout: today'),
      ('ieri', riga('A', ClientActivity.recent, giorni: 1), 'Ultimo allenamento: ieri', 'Last workout: yesterday'),
      ('tre giorni fa', riga('A', ClientActivity.recent, giorni: 3), 'Ultimo allenamento: 3 giorni fa', 'Last workout: 3 days ago'),
      ('nessun allenamento', riga('A', ClientActivity.noSessions), 'Nessun allenamento ancora', 'No workouts yet'),
      ('non condivisi', riga('A', ClientActivity.notShared), 'Allenamenti non condivisi', 'Workouts not shared'),
    ];

    for (final (nome, r, italiano, inglese) in casi) {
      test(nome, () {
        expect(clientSubtitle(it, r), italiano);
        expect(clientSubtitle(en, r), inglese);
      });
    }

    test('nessuna frase lascia un segnaposto o una chiave non tradotta', () {
      for (final (_, r, _, _) in casi) {
        for (final lingua in [it, en]) {
          final frase = clientSubtitle(lingua, r);
          expect(frase, isNot(contains('%s')), reason: frase);
          expect(frase, isNot(contains('_')), reason: 'chiave non tradotta: $frase');
        }
      }
    });

    test('le chiavi della schermata esistono in italiano e in inglese', () {
      const chiavi = [
        'clients_title', 'clients_error', 'clients_retry', 'clients_empty_title',
        'clients_empty_body', 'clients_empty_cta', 'client_stat_day_ago', 'client_stat_days_ago',
        'client_when_today', 'client_when_yesterday',
      ];
      for (final chiave in chiavi) {
        expect(it.t(chiave), isNot(chiave), reason: 'manca in italiano: $chiave');
        expect(en.t(chiave), isNot(chiave), reason: 'manca in inglese: $chiave');
      }
    });
  });
}
