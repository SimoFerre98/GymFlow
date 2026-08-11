import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/app.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/screens/time_tools_screen.dart';
import 'package:gymflow/src/ui/widgets/timer_overlay.dart';

/// La pillola del tempo: sta in alto, non copre niente, e non toglie niente
/// quando non c'e.
///
/// **I test montano `GymFlowShell`, cioe il telaio vero di `app.dart`.** La
/// prima versione di questi test si costruiva una `Column` nel proprio file:
/// sarebbero rimasti verdi anche rimettendo lo `Stack` che copriva il
/// contenuto, cioe proprio il difetto che questa storia chiude. È il difetto
/// n. 3 dell'handoff — provare i pezzi e non il cablaggio fra loro.
///
/// **La superficie di prova ha un bordo di sistema di 40 dp.** Senza, il difetto
/// piu grosso trovato in review sarebbe invisibile: la `SafeArea` attorno a
/// tutto occupava quella fascia **anche a pillola nascosta**, e ogni schermata
/// scendeva di 40 dp per sempre.
///
/// **Limite dichiarato**: sono misure di geometria. Che la pillola si legga, e
/// che l'entrata e l'uscita non diano fastidio, resta da confermare sull'APK.
void main() {
  /// Il telaio vero, con un bordo di sistema come su un telefono.
  Widget app(ProviderContainer container, {PreferredSizeWidget? barra}) =>
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 40)),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            theme: ThemeData(extensions: const [ExpressiveTokens()]),
            builder: (context, child) => GymFlowShell(child: child),
            home: Scaffold(
              appBar: barra,
              body: const Center(child: Text('Contenuto', key: Key('c'))),
            ),
          ),
        ),
      );

  ProviderContainer nuovo(WidgetTester tester) {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  testWidgets('compare solo quando cronometro o recupero sono attivi', (
    tester,
  ) async {
    final c = nuovo(tester);
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsNothing);

    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsOneWidget);

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsNothing);

    c.read(timerNotifierProvider.notifier).toggleStopwatch();
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsOneWidget);

    c.read(timerNotifierProvider.notifier).resetStopwatch();
    await tester.pumpAndSettle();
  });

  testWidgets('non compare sulla schermata del tempo', (tester) async {
    final c = nuovo(tester);
    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsOneWidget);

    c.read(timerNotifierProvider.notifier).setToolsVisible(true);
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsNothing);

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('quando non c e, non occupa niente', (tester) async {
    // Il difetto trovato in review: la `SafeArea` attorno a tutto impagina un
    // figlio di dimensione zero e si prende comunque la fascia di sistema.
    // Misurato: 40 dp su ogni schermata, sempre, piu i 40 che la `AppBar`
    // aggiunge per conto suo.
    final c = nuovo(tester);
    await tester.pumpWidget(app(c, barra: AppBar(title: const Text('Titolo'))));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(TimerOverlay)).height, 0.0);
    expect(
      tester.getRect(find.byType(AppBar)).top,
      0.0,
      reason: 'a pillola nascosta la barra deve stare dove starebbe senza',
    );
  });

  testWidgets('il contenuto si sposta invece di essere coperto', (tester) async {
    final c = nuovo(tester);
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    final senza = tester.getRect(find.byKey(const Key('c')));

    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpAndSettle();
    final con = tester.getRect(find.byKey(const Key('c')));
    final pillola = tester.getRect(find.byKey(chiavePillola));

    expect(con.top, greaterThan(senza.top), reason: 'il contenuto non si e mosso');
    expect(
      pillola.overlaps(con),
      isFalse,
      reason: 'la pillola copre il contenuto invece di spostarlo',
    );

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('con la pillola la barra non ripete il bordo di sistema', (
    tester,
  ) async {
    // La pillola copre gia la fascia di sistema: se il contenuto se la prende
    // di nuovo, fra pillola e titolo restano altri 40 dp vuoti.
    final c = nuovo(tester);
    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(app(c, barra: AppBar(title: const Text('Titolo'))));
    await tester.pumpAndSettle();

    final pillola = tester.getRect(find.byKey(chiavePillola));
    final barra = tester.getRect(find.byType(AppBar));

    expect(barra.height, kToolbarHeight);
    expect(
      barra.top - pillola.bottom,
      lessThanOrEqualTo(8.0),
      reason: 'fra la pillola e la barra e rimasta una striscia vuota',
    );

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('sta in alto e non si sposta col dito', (tester) async {
    final c = nuovo(tester);
    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();

    final prima = tester.getRect(find.byKey(chiavePillola));
    expect(prima.top, lessThan(tester.getSize(find.byType(MaterialApp)).height / 2));

    // Trascinarla non deve piu spostarla: era una funzione della vecchia
    // pillola flottante, tolta di proposito con la posizione fissa.
    await tester.drag(find.byKey(chiavePillola), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(chiavePillola)), prima);

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('porta i comandi di pausa e azzeramento', (tester) async {
    final c = nuovo(tester);
    final notifier = c.read(timerNotifierProvider.notifier);
    notifier.toggleTimer();
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    expect(notifier.isTimerRunning, isTrue);

    await tester.tap(find.byIcon(Icons.pause_circle_filled));
    await tester.pumpAndSettle();
    expect(notifier.isTimerRunning, isFalse);

    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pumpAndSettle();
    expect(notifier.isTimerRunning, isTrue);

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();
    expect(notifier.isTimerRunning, isFalse);
    expect(notifier.timerRemaining, notifier.timerDuration);
  });

  testWidgets('un tocco porta alla schermata del tempo', (tester) async {
    final c = nuovo(tester);
    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();

    // Sul testo e non sulla pillola intera: al centro ci sono i comandi, e
    // toccare li vuol dire mettere in pausa, non navigare.
    await tester.tap(find.byType(Text).first);
    await tester.pumpAndSettle();

    expect(find.byType(TimeToolsScreen, skipOffstage: false), findsOneWidget);

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('col cronometro e il recupero insieme mostra il recupero', (
    tester,
  ) async {
    final c = nuovo(tester);
    final notifier = c.read(timerNotifierProvider.notifier);
    notifier.toggleStopwatch();
    notifier.setTimerDuration(const Duration(seconds: 45));
    notifier.toggleTimer();
    await tester.pumpWidget(app(c));
    // Un fotogramma solo: `pumpAndSettle` con due ticker in corsa fa scorrere
    // il tempo finto fino a far scadere il recupero, e il numero non e piu
    // quello impostato.
    await tester.pump();

    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    expect(find.byIcon(Icons.timer), findsNothing);
    // E il numero e quello del recupero, non quello del cronometro.
    expect(find.textContaining('45'), findsOneWidget);

    notifier.resetTimer();
    notifier.resetStopwatch();
    await tester.pump();
  });
}
