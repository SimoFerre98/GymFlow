import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/services/health_service.dart';
import 'package:gymflow/src/ui/screens/statistics_screen.dart';

/// I permessi di salute: quando mancano si dice, e non si mostra uno zero.
///
/// **Il test consegnato con US-100 era `expect(true, isTrue)`**, con un commento
/// che spiegava perche: `Health` parla con un method channel e non si puo
/// sostituire. Vero finche il servizio se lo costruiva da solo — ora lo accetta
/// dal costruttore, e il finto qui sotto e tutto quello che serviva.
///
/// **Limite dichiarato**: il finto risponde come risponderebbe il plugin, ma
/// **non e** Health Connect. Che il permesso venga davvero chiesto, e che
/// l'utente veda la schermata di sistema, resta da confermare sul dispositivo —
/// e cosi la causa per cui oggi manca, che il piano lascia aperta apposta.
class FakeHealth implements Health {
  FakeHealth({this.risposte = const {}, this.eccezione = false});

  /// Cosa rispondere a `hasPermissions`, per elenco di tipi richiesti.
  /// L'assenza di una chiave vale `null`, cioe «non lo so».
  final Map<HealthDataType, bool?> risposte;
  final bool eccezione;

  final richieste = <List<HealthDataType>>[];

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (eccezione) throw Exception('Health Connect non risponde');
    richieste.add(types);
    // Come il plugin vero: `null` se anche uno solo non e determinabile.
    if (types.any((t) => !risposte.containsKey(t))) return null;
    return types.every((t) => risposte[t] == true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const passi = HealthDataType.STEPS;
  const calorie = HealthDataType.ACTIVE_ENERGY_BURNED;

  group('quali permessi mancano', () {
    test('se ci sono tutti, non manca niente', () async {
      final servizio = HealthService(
        health: FakeHealth(risposte: {passi: true, calorie: true}),
      );
      expect(await servizio.getMissingSummaryPermissions(), isEmpty);
    });

    test('se manca solo quello dei passi, dice quello', () async {
      final servizio = HealthService(
        health: FakeHealth(risposte: {passi: false, calorie: true}),
      );
      expect(await servizio.getMissingSummaryPermissions(), [passi]);
    });

    test('se mancano tutti e due, li dice tutti e due', () async {
      final servizio = HealthService(
        health: FakeHealth(risposte: {passi: false, calorie: false}),
      );
      expect(await servizio.getMissingSummaryPermissions(), [passi, calorie]);
    });

    test('indeterminato non e negato', () async {
      // `hasPermissions` restituisce `null` quando non sa rispondere.
      // Trattarlo come un rifiuto farebbe comparire l'avviso a chi ha
      // concesso tutto: e il caso che il rapporto di consegna dichiarava, e
      // che qui viene fissato.
      final servizio = HealthService(health: FakeHealth());
      expect(await servizio.getMissingSummaryPermissions(), isNull);
    });

    test('se il plugin solleva, non si inventa un elenco', () async {
      final servizio = HealthService(health: FakeHealth(eccezione: true));
      expect(await servizio.getMissingSummaryPermissions(), isNull);
    });
  });

  group('la sezione delle statistiche', () {
    const loc = Localization(Locale('it'));

    /// Un futuro gia fallito, con l'errore gia «visto».
    ///
    /// Senza un ascoltatore al momento della creazione, `Future.error` viene
    /// segnalato dal framework di test come errore non gestito e fa fallire il
    /// test prima ancora che il widget lo legga.
    Future<Map<String, dynamic>> fallito(Object errore) {
      final f = Future<Map<String, dynamic>>.error(errore);
      f.then((_) {}, onError: (_) {});
      return f;
    }

    Widget sezione(
      Future<Map<String, dynamic>>? future, {
      VoidCallback? onConsenti,
    }) => MaterialApp(
      theme: AppTheme.darkTheme(Colors.blue),
      home: Scaffold(
        body: HealthSummarySection(
          future: future,
          loc: loc,
          onConsenti: onConsenti ?? () {},
        ),
      ),
    );

    testWidgets('col permesso mancante lo dice, e non mostra uno zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        sezione(fallito(const PermessiSaluteMancanti([passi, calorie]))),
      );
      await tester.pumpAndSettle();

      expect(find.text(loc.t('health_permission_needed')), findsOneWidget);

      // È la meta che conta: prima di US-100 l'errore finiva in
      // `snapshot.data ?? {}` e la schermata mostrava «0 passi, 0 calorie».
      expect(find.text('0'), findsNothing);
      expect(find.textContaining('0 kcal'), findsNothing);
    });

    testWidgets('dice quali dati non sono leggibili', (tester) async {
      await tester.pumpWidget(
        sezione(fallito(const PermessiSaluteMancanti([passi]))),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(loc.t('steps_label')),
        findsWidgets,
        reason: 'l elenco di cosa manca e la differenza fra «qualcosa non va» '
            'e un avviso su cui si puo agire',
      );
      expect(
        find.textContaining(loc.t('active_cal_label')),
        findsNothing,
        reason: 'le calorie erano leggibili: dirle mancanti sarebbe falso',
      );
    });

    testWidgets('quando non si sa cosa manca, non si inventa un elenco', (
      tester,
    ) async {
      await tester.pumpWidget(sezione(fallito(Exception('rete assente'))));
      await tester.pumpAndSettle();

      expect(find.text(loc.t('health_permission_needed')), findsOneWidget);
      expect(
        find.textContaining(loc.t('health_permission_missing_prefix')),
        findsNothing,
      );
    });

    testWidgets('il pulsante chiede davvero i permessi', (tester) async {
      var chiesto = 0;
      await tester.pumpWidget(
        sezione(
          fallito(const PermessiSaluteMancanti([passi])),
          onConsenti: () => chiesto++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(loc.t('health_permission_grant')));
      await tester.pump();

      expect(chiesto, 1);
    });

    testWidgets('coi dati leggibili mostra i numeri veri', (tester) async {
      await tester.pumpWidget(
        sezione(Future.value({'steps': 8421, 'calories': 512.0})),
      );
      await tester.pumpAndSettle();

      expect(find.text('8421'), findsOneWidget);
      expect(find.text(loc.t('health_permission_needed')), findsNothing);
    });
  });
}
