import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/timer_settings_provider.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAvvisiTempo implements AvvisiTempo {
  int chiamateSecondoFinale = 0;
  int chiamateScaduto = 0;
  bool? ultimaVibra;
  bool? ultimaSuona;

  int? ultimoSecondo;
  bool? ultimaVibraSecondo;
  bool? ultimaParla;

  @override
  void secondoFinale(int secondiRestanti, {required bool vibra, required bool parla}) {
    chiamateSecondoFinale++;
    ultimoSecondo = secondiRestanti;
    ultimaVibraSecondo = vibra;
    ultimaParla = parla;
  }

  @override
  void scaduto({required bool vibra, required bool suona}) {
    chiamateScaduto++;
    ultimaVibra = vibra;
    ultimaSuona = suona;
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

    test(
      'con la sola vibrazione disabilitata, scaduto() e chiamato ma senza vibrare',
      () {
        // Vibrazione e suono sono due preferenze indipendenti: disattivare
        // una non deve azzerare l'altra, ne evitare del tutto la chiamata a
        // scaduto() se il suono resta attivo.
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final settingsNotifier = container.read(timerSettingsNotifierProvider.notifier);
        settingsNotifier.setVibrateOnTimerEnd(false);

        final notifier = container.read(timerNotifierProvider.notifier);
        final mock = MockAvvisiTempo();
        notifier.avvisi = mock;

        notifier.segnalaScadenza();
        expect(mock.chiamateScaduto, 1, reason: 'il suono e ancora attivo per default');
        expect(mock.ultimaVibra, isFalse);
        expect(mock.ultimaSuona, isTrue);
      },
    );

    test('con vibrazione e suono entrambi disabilitati, scaduto() non e chiamato', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settingsNotifier = container.read(timerSettingsNotifierProvider.notifier);
      settingsNotifier.setVibrateOnTimerEnd(false);
      settingsNotifier.setSoundOnTimerEnd(false);

      final notifier = container.read(timerNotifierProvider.notifier);
      final mock = MockAvvisiTempo();
      notifier.avvisi = mock;

      notifier.segnalaScadenza();
      expect(mock.chiamateScaduto, 0, reason: 'senza vibrazione ne suono non deve accadere nulla');
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

    test(
      'con la sola voce abilitata, secondoFinale e chiamato senza vibrare',
      () {
        // Vibrazione e conto vocale sono due preferenze indipendenti, stesso
        // principio gia' verificato per scaduto()/vibra+suona.
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final settingsNotifier = container.read(timerSettingsNotifierProvider.notifier);
        settingsNotifier.setVibrateOnTimerEnd(false);
        settingsNotifier.setVoiceCountdownEnabled(true);

        final notifier = container.read(timerNotifierProvider.notifier);
        final mock = MockAvvisiTempo();
        notifier.avvisi = mock;

        notifier.avvisaSeUltimiSecondi(const Duration(seconds: 2));
        expect(mock.chiamateSecondoFinale, 1);
        expect(mock.ultimoSecondo, 2);
        expect(mock.ultimaVibraSecondo, isFalse);
        expect(mock.ultimaParla, isTrue);
      },
    );

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

    test(
      'addTimerSeconds che porta il tempo a zero conclude come uno scadere naturale, non come resetTimer',
      () {
        // Segnalato rivedendo il codice: "-15s" su un recupero quasi finito
        // chiamava resetTimer(), che riporta timerRemaining alla durata
        // piena invece di concludere il conto alla rovescia — il quadrante
        // "risorgeva" da 0:10 a 0:30 invece di segnare 0:00, e senza vibrare
        // ne suonare.
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(timerNotifierProvider.notifier);
        final mock = MockAvvisiTempo();
        notifier.avvisi = mock;

        notifier.setTimerDuration(const Duration(seconds: 30));
        notifier.toggleTimer();
        notifier.addTimerSeconds(-40); // ben oltre lo zero

        final state = container.read(timerNotifierProvider);
        expect(state.timerRemaining, Duration.zero);
        expect(state.isTimerRunning, isFalse);
        expect(
          state.timerDuration,
          const Duration(seconds: 30),
          reason: 'la durata originale non deve tornare come "nuovo" tempo restante',
        );
        expect(mock.chiamateScaduto, 1, reason: 'concluso come uno scadere naturale, deve avvisare');
      },
    );

    test('addTimerSeconds che porta a zero un timer già in pausa non avvisa', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerNotifierProvider.notifier);
      final mock = MockAvvisiTempo();
      notifier.avvisi = mock;

      notifier.setTimerDuration(const Duration(seconds: 30));
      notifier.addTimerSeconds(-40);

      expect(mock.chiamateScaduto, 0, reason: 'non stava scorrendo nulla da concludere');
    });

    test('addTimerSeconds oltre la durata originale allunga anche timerDuration', () {
      // Senza questo, l'anello di progresso (restante/durata) superava 1 e
      // restava visivamente pieno finche il tempo restante non ridiscendeva
      // sotto la durata di partenza, anche se le cifre contavano bene.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerNotifierProvider.notifier);
      notifier.setTimerDuration(const Duration(seconds: 30));
      notifier.toggleTimer();
      notifier.addTimerSeconds(60);

      final state = container.read(timerNotifierProvider);
      expect(state.timerRemaining, const Duration(seconds: 90));
      expect(state.timerDuration, const Duration(seconds: 90));
    });
  });
}
