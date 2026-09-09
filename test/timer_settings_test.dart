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

    group('restSecondsForReps', () {
      const settings = TimerSettings(
        defaultRestSeconds: 90,
        restSecondsStrength: 180,
        restSecondsHypertrophy: 90,
        restSecondsEndurance: 45,
      );

      test('1-5 ripetizioni: fascia forza', () {
        expect(settings.restSecondsForReps(1), equals(180));
        expect(settings.restSecondsForReps(5), equals(180));
      });

      test('6-12 ripetizioni: fascia ipertrofia', () {
        expect(settings.restSecondsForReps(6), equals(90));
        expect(settings.restSecondsForReps(12), equals(90));
      });

      test('13+ ripetizioni: fascia resistenza', () {
        expect(settings.restSecondsForReps(13), equals(45));
        expect(settings.restSecondsForReps(50), equals(45));
      });

      test('ripetizioni non classificabili (0 o negative): il default', () {
        expect(settings.restSecondsForReps(0), equals(90));
        expect(settings.restSecondsForReps(-1), equals(90));
      });
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

    test('aggiorna soundOnTimerEnd e lo persiste', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerSettingsNotifierProvider.notifier);
      await notifier.setSoundOnTimerEnd(false);

      expect(
        container.read(timerSettingsNotifierProvider).soundOnTimerEnd,
        isFalse,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('timer_sound_on_end'), isFalse);
    });

    test('aggiorna il recupero per fascia e lo persiste', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerSettingsNotifierProvider.notifier);
      await notifier.setRestSecondsStrength(200);
      await notifier.setRestSecondsHypertrophy(75);
      await notifier.setRestSecondsEndurance(30);

      final state = container.read(timerSettingsNotifierProvider);
      expect(state.restSecondsStrength, equals(200));
      expect(state.restSecondsHypertrophy, equals(75));
      expect(state.restSecondsEndurance, equals(30));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('timer_rest_strength_seconds'), equals(200));
      expect(prefs.getInt('timer_rest_hypertrophy_seconds'), equals(75));
      expect(prefs.getInt('timer_rest_endurance_seconds'), equals(30));
    });
  });
}
