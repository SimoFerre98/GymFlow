import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/live_metrics_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/services/health_service.dart';
import 'package:gymflow/src/ui/widgets/live_metrics_panel.dart';
import 'package:gymflow/src/ui/widgets/sparkline.dart';

class _FakeHealthService extends HealthService {
  _FakeHealthService({
    this.permissions = true,
    this.canReadHr = true,
    this.sampleCalories,
    this.sampleHeartRate,
  });

  bool permissions;
  final bool canReadHr;
  double? sampleCalories;
  int? sampleHeartRate;

  @override
  Future<bool> hasLiveMetricsPermissions() async => permissions;

  @override
  Future<bool> hasHeartRateAccess() async => canReadHr;

  @override
  Future<bool> requestPermissions() async {
    permissions = true;
    return true;
  }

  @override
  Future<Map<String, dynamic>> fetchLiveMetrics({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return {
      'calories': sampleCalories,
      'heartRate': sampleHeartRate,
    };
  }
}

class _FakeHealthServiceProvider extends HealthServiceProvider {
  _FakeHealthServiceProvider(this.service);
  final HealthService service;

  @override
  HealthService build() => service;
}

Widget _wrapWithApp({
  required HealthService service,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      healthServiceProvider.overrideWith(
        () => _FakeHealthServiceProvider(service),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(
        extensions: const [
          ExpressiveTokens(),
        ],
      ),
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

/// La lingua predefinita del progetto e l'italiano: le etichette si leggono
/// dalle chiavi invece di essere ricopiate, cosi il test non si rompe se
/// cambia la traduzione e non passa se cambia la chiave.
const _loc = Localization(Locale('it'));

void main() {
  group('LiveMetricsPanel', () {
    testWidgets('senza permesso mostra come concederlo, non un errore',
        (tester) async {
      final fakeService = _FakeHealthService(permissions: false);

      await tester.pumpWidget(
        _wrapWithApp(
          service: fakeService,
          child: const LiveMetricsPanel(
            formattedTime: '00:15:30',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('00:15:30'), findsOneWidget);

      // L'invito c'e, e c'e il pulsante che apre la richiesta.
      expect(
        find.text(_loc.t('live_metrics_permission_prompt')),
        findsOneWidget,
      );
      expect(
        find.text(_loc.t('live_metrics_grant_permission')),
        findsOneWidget,
      );

      // E non e un errore: nessuna tessera e nessun valore a zero.
      expect(find.byType(Sparkline), findsNothing);
      expect(find.text(_loc.t('live_metrics_calories')), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('battito non leggibile: la tessera manca, non vale zero',
        (tester) async {
      final fakeService = _FakeHealthService(
        permissions: true,
        canReadHr: false,
        sampleCalories: 180.0,
      );

      await tester.pumpWidget(
        _wrapWithApp(
          service: fakeService,
          child: const LiveMetricsPanel(
            formattedTime: '00:20:00',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('00:20:00'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
      expect(find.text(_loc.t('live_metrics_calories')), findsOneWidget);

      // Il punto del criterio: la tessera del battito non c'e affatto, e da
      // nessuna parte compare uno zero al posto del dato che non abbiamo.
      expect(find.text(_loc.t('live_metrics_heart_rate')), findsNothing);
      expect(find.text('0'), findsNothing);
      expect(find.byType(Sparkline), findsOneWidget);
    });

    testWidgets('battito leggibile: la tessera compare col valore letto',
        (tester) async {
      final fakeService = _FakeHealthService(
        permissions: true,
        canReadHr: true,
        sampleCalories: 250.0,
        sampleHeartRate: 142,
      );

      await tester.pumpWidget(
        _wrapWithApp(
          service: fakeService,
          child: const LiveMetricsPanel(
            formattedTime: '00:35:00',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('250'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(find.byType(Sparkline), findsNWidgets(2));
    });
  });
}
