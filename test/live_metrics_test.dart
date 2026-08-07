import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/live_metrics_provider.dart';
import 'package:gymflow/src/services/health_service.dart';

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
  int fetchCallCount = 0;

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
    fetchCallCount++;
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

void main() {
  group('LiveMetricsNotifier', () {
    test('il periodo di aggiornamento e dichiarato a 30 secondi', () {
      expect(kLiveMetricsInterval, const Duration(seconds: 30));
    });

    test('stato iniziale senza permessi: segnala permesso assente', () async {
      final fakeService = _FakeHealthService(permissions: false);
      final container = ProviderContainer(
        overrides: [
          healthServiceProvider.overrideWith(
            () => _FakeHealthServiceProvider(fakeService),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(liveMetricsNotifierProvider, (previous, next) {});
      addTearDown(sub.close);

      // Lascia completare la lettura asincrona di _init()
      await Future<void>.delayed(Duration.zero);

      final state = container.read(liveMetricsNotifierProvider);
      expect(state.hasPermission, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('richiesta permessi: passa a permesso concesso e avvia la lettura',
        () async {
      final fakeService = _FakeHealthService(
        permissions: false,
        sampleCalories: 150.0,
        sampleHeartRate: 130,
      );
      final container = ProviderContainer(
        overrides: [
          healthServiceProvider.overrideWith(
            () => _FakeHealthServiceProvider(fakeService),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(liveMetricsNotifierProvider, (previous, next) {});
      addTearDown(sub.close);

      final notifier = container.read(liveMetricsNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(liveMetricsNotifierProvider).hasPermission, isFalse);

      await notifier.requestPermissions();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(liveMetricsNotifierProvider);
      expect(state.hasPermission, isTrue);
      expect(state.calories, 150.0);
      expect(state.heartRate, 130);
    });

    test('battito non leggibile: canReadHeartRate e false, non un valore a zero',
        () async {
      final fakeService = _FakeHealthService(
        permissions: true,
        canReadHr: false,
        sampleCalories: 210.0,
        sampleHeartRate: null,
      );
      final container = ProviderContainer(
        overrides: [
          healthServiceProvider.overrideWith(
            () => _FakeHealthServiceProvider(fakeService),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(liveMetricsNotifierProvider, (previous, next) {});
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(liveMetricsNotifierProvider);
      expect(state.hasPermission, isTrue);
      expect(state.canReadHeartRate, isFalse);
      expect(state.calories, 210.0);
      expect(state.heartRate, isNull);
    });

    test('sensore presente ma dato non ancora pervenuto: battito e nullo',
        () async {
      final fakeService = _FakeHealthService(
        permissions: true,
        canReadHr: true,
        sampleCalories: null,
        sampleHeartRate: null,
      );
      final container = ProviderContainer(
        overrides: [
          healthServiceProvider.overrideWith(
            () => _FakeHealthServiceProvider(fakeService),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(liveMetricsNotifierProvider, (previous, next) {});
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(liveMetricsNotifierProvider);
      expect(state.hasPermission, isTrue);
      expect(state.canReadHeartRate, isTrue);
      expect(state.calories, isNull);
      expect(state.heartRate, isNull);
    });

    test('accumula la finestra recente per la sparkline senza superare il limite',
        () async {
      final fakeService = _FakeHealthService(
        permissions: true,
        canReadHr: true,
        sampleCalories: 50.0,
        sampleHeartRate: 120,
      );
      final container = ProviderContainer(
        overrides: [
          healthServiceProvider.overrideWith(
            () => _FakeHealthServiceProvider(fakeService),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(liveMetricsNotifierProvider, (previous, next) {});
      addTearDown(sub.close);

      final notifier = container.read(liveMetricsNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      // Simula 25 aggiornamenti
      for (int i = 1; i <= 25; i++) {
        fakeService.sampleCalories = 50.0 + i;
        fakeService.sampleHeartRate = 120 + i;
        await notifier.refresh();
      }

      final state = container.read(liveMetricsNotifierProvider);
      expect(state.calorieHistory.length, kMaxRecentSamples);
      expect(state.heartRateHistory.length, kMaxRecentSamples);
      expect(state.calorieHistory.last, 75.0);
      expect(state.heartRateHistory.last, 145.0);
    });

    // In `testWidgets` l'orologio e finto, quindi il periodo si puo far
    // scorrere davvero invece di dedurlo dalla costante. Serve per due criteri
    // distinti: che la lettura si ripeta, e che smetta alla chiusura.
    testWidgets('la lettura si ripete a ogni periodo e si ferma col dispose',
        (tester) async {
      final fakeService = _FakeHealthService(
        sampleCalories: 40.0,
        sampleHeartRate: 110,
      );
      final container = ProviderContainer(
        overrides: [
          healthServiceProvider.overrideWith(
            () => _FakeHealthServiceProvider(fakeService),
          ),
        ],
      );

      final sub =
          container.listen(liveMetricsNotifierProvider, (previous, next) {});
      await tester.pump();
      final dopoAvvio = fakeService.fetchCallCount;
      expect(dopoAvvio, greaterThan(0), reason: 'la prima lettura e immediata');

      await tester.pump(kLiveMetricsInterval);
      expect(fakeService.fetchCallCount, dopoAvvio + 1);

      await tester.pump(kLiveMetricsInterval);
      expect(fakeService.fetchCallCount, dopoAvvio + 2);

      // Chiuso l'ultimo ascoltatore, l'autoDispose smonta il notifier: da qui
      // in avanti il tempo passa e nessuno legge piu niente.
      sub.close();
      container.dispose();
      final dopoChiusura = fakeService.fetchCallCount;

      await tester.pump(kLiveMetricsInterval * 3);
      expect(fakeService.fetchCallCount, dopoChiusura);
      // Se un timer fosse sopravvissuto, `testWidgets` fallirebbe qui da solo
      // con «A Timer is still pending».
    });
  });
}
