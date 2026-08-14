import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/timer_settings_provider.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAvvisiTempo implements AvvisiTempo {
  int chiamateSecondoFinale = 0;
  int chiamateScaduto = 0;

  @override
  void secondoFinale() {
    chiamateSecondoFinale++;
  }

  @override
  void scaduto() {
    chiamateScaduto++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('US-099: Avvisi tempo e vibrazione alla scadenza del timer', () {
    test('segnalaScadenza chiama avvisi.scaduto quando vibrateOnTimerEnd e true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerNotifierProvider.notifier);
      final mock = MockAvvisiTempo();
      notifier.avvisi = mock;

      // Default vibrateOnTimerEnd è true
      expect(container.read(timerSettingsNotifierProvider).vibrateOnTimerEnd, isTrue);

      notifier.segnalaScadenza();
      expect(mock.chiamateScaduto, 1);
    });

    test('segnalaScadenza non vibra quando vibrateOnTimerEnd e disabilitato', () {
      final container = ProviderContainer(
        overrides: [
          timerSettingsNotifierProvider.overrideWith(() {
            final n = TimerSettingsNotifier();
            return n;
          }),
        ],
      );
      addTearDown(container.dispose);

      final settingsNotifier = container.read(timerSettingsNotifierProvider.notifier);
      settingsNotifier.setVibrateOnTimerEnd(false);

      final notifier = container.read(timerNotifierProvider.notifier);
      final mock = MockAvvisiTempo();
      notifier.avvisi = mock;

      notifier.segnalaScadenza();
      expect(mock.chiamateScaduto, 0, reason: 'con vibrazione disabilitata non deve suonare/vibrare');
    });

    test('avvisaSeUltimiSecondi vibra solo se vibrateOnTimerEnd e abilitato', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerNotifierProvider.notifier);
      final mock = MockAvvisiTempo();
      notifier.avvisi = mock;

      // A 2 secondi dalla fine
      notifier.avvisaSeUltimiSecondi(const Duration(seconds: 2));
      expect(mock.chiamateSecondoFinale, 1);

      // Disabilitiamo
      final settingsNotifier = container.read(timerSettingsNotifierProvider.notifier);
      settingsNotifier.setVibrateOnTimerEnd(false);

      notifier.avvisaSeUltimiSecondi(const Duration(seconds: 1));
      expect(mock.chiamateSecondoFinale, 1, reason: 'non deve incrementare quando disabilitato');
    });

    test('resetTimer azzera il conto senza chiamare scaduto()', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerNotifierProvider.notifier);
      final mock = MockAvvisiTempo();
      notifier.avvisi = mock;

      notifier.setTimerDuration(const Duration(seconds: 30));
      notifier.toggleTimer();
      notifier.resetTimer();

      expect(mock.chiamateScaduto, 0, reason: 'azzerare a mano prima della scadenza non vibra');
    });
  });
}
