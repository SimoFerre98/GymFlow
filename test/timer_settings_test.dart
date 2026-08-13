import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/timer_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimerSettings', () {
    test('valori di default corretti', () {
      const settings = TimerSettings();
      expect(settings.autoRestEnabled, isTrue);
      expect(settings.defaultRestSeconds, equals(90));
      expect(settings.vibrateOnTimerEnd, isTrue);
    });

    test('copyWith aggiorna i campi specificati', () {
      const settings = TimerSettings();
      final updated = settings.copyWith(
        autoRestEnabled: false,
        defaultRestSeconds: 120,
        vibrateOnTimerEnd: false,
      );

      expect(updated.autoRestEnabled, isFalse);
      expect(updated.defaultRestSeconds, equals(120));
      expect(updated.vibrateOnTimerEnd, isFalse);
    });
  });

  group('TimerSettingsNotifier', () {
    test('inizializza con i valori di default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(timerSettingsNotifierProvider);
      expect(state.autoRestEnabled, isTrue);
      expect(state.defaultRestSeconds, equals(90));
      expect(state.vibrateOnTimerEnd, isTrue);
    });

    test('aggiorna autoRestEnabled e lo persiste', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerSettingsNotifierProvider.notifier);
      await notifier.setAutoRestEnabled(false);

      expect(
        container.read(timerSettingsNotifierProvider).autoRestEnabled,
        isFalse,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('timer_auto_rest_enabled'), isFalse);
    });

    test('aggiorna defaultRestSeconds e lo persiste', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerSettingsNotifierProvider.notifier);
      await notifier.setDefaultRestSeconds(60);

      expect(
        container.read(timerSettingsNotifierProvider).defaultRestSeconds,
        equals(60),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('timer_default_rest_seconds'), equals(60));
    });

    test('aggiorna vibrateOnTimerEnd e lo persiste', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerSettingsNotifierProvider.notifier);
      await notifier.setVibrateOnTimerEnd(false);

      expect(
        container.read(timerSettingsNotifierProvider).vibrateOnTimerEnd,
        isFalse,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('timer_vibrate_on_end'), isFalse);
    });
  });
}
