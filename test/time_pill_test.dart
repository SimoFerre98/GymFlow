import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/widgets/timer_overlay.dart';
import 'package:gymflow/src/app.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/screens/time_tools_screen.dart';

void main() {
  Widget buildTestApp(ProviderContainer container, {Widget? child}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData(
          extensions: const [ExpressiveTokens()],
        ),
        home: child ??
            const Scaffold(
              body: Column(
                children: [
                  TimerOverlay(),
                  Expanded(
                    child: Center(
                      child: Text('Content', key: Key('content_text')),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  testWidgets('Compare solo quando cronometro o recupero sono attivi', (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(buildTestApp(container));

    // Fermi -> niente
    expect(find.byType(TimerOverlay), findsOneWidget);
    expect(find.byType(AnimatedSize), findsOneWidget);
    expect(find.byType(Container), findsNothing);

    // Recupero attivo -> c'è
    container.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpAndSettle();
    expect(find.byType(Container), findsOneWidget);

    // Stop recupero
    container.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
    expect(find.byType(Container), findsNothing);

    // Cronometro attivo -> c'è
    container.read(timerNotifierProvider.notifier).toggleStopwatch();
    await tester.pumpAndSettle();
    expect(find.byType(Container), findsOneWidget);
    container.dispose();
  });

  testWidgets('Non compare sulla schermata del tempo', (tester) async {
    final container = ProviderContainer();
    container.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(buildTestApp(container));
    await tester.pumpAndSettle();

    expect(find.byType(Container), findsOneWidget);

    container.read(timerNotifierProvider.notifier).setToolsVisible(true);
    await tester.pumpAndSettle();

    expect(find.byType(Container), findsNothing);
    container.dispose();
  });

  testWidgets('Occupa una posizione fissa in alto', (tester) async {
    final container = ProviderContainer();
    container.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(buildTestApp(container));
    await tester.pumpAndSettle();

    final pillRect = tester.getRect(find.byType(Container).first);
    final size = tester.getSize(find.byType(MaterialApp));

    expect(pillRect.top, lessThan(size.height / 2));

    await tester.drag(find.byType(Container).first, const Offset(0, 100));
    await tester.pumpAndSettle();

    final newPillRect = tester.getRect(find.byType(Container).first);
    expect(newPillRect, equals(pillRect));
    container.dispose();
  });

  testWidgets('Il contenuto sottostante si sposta invece di essere coperto', (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(buildTestApp(container));
    await tester.pumpAndSettle();

    final contentRectWithout = tester.getRect(find.byKey(const Key('content_text')));

    container.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpAndSettle();

    final contentRectWith = tester.getRect(find.byKey(const Key('content_text')));
    final pillRect = tester.getRect(find.byType(Container).first);

    expect(contentRectWith.top, greaterThan(contentRectWithout.top));
    expect(pillRect.overlaps(contentRectWith), isFalse);
    container.dispose();
  });

  testWidgets('Porta i comandi di pausa e azzeramento', (tester) async {
    final container = ProviderContainer();
    final notifier = container.read(timerNotifierProvider.notifier);
    notifier.toggleTimer();
    await tester.pumpWidget(buildTestApp(container));
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
    expect(notifier.timerRemaining, equals(notifier.timerDuration));
    container.dispose();
  });

  testWidgets('Un tocco porta alla schermata del tempo', (tester) async {
    final container = ProviderContainer();
    container.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(buildTestApp(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Container).first);
    await tester.pumpAndSettle();

    expect(find.byType(TimeToolsScreen, skipOffstage: false), findsOneWidget);
    container.dispose();
  });

  testWidgets('Cronometro e recupero insieme (priorità al recupero)', (tester) async {
    final container = ProviderContainer();
    final notifier = container.read(timerNotifierProvider.notifier);
    notifier.toggleStopwatch();
    notifier.toggleTimer();
    await tester.pumpWidget(buildTestApp(container));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    expect(find.byIcon(Icons.timer), findsNothing);
    container.dispose();
  });
}
