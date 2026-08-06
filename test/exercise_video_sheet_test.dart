import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/services/video_availability.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Exercise exercise({String? videoUrl, String? videoSearchQuery}) {
  return Exercise(
    id: 'e1',
    name: 'Panca piana',
    description: '',
    type: ExerciseType.strength,
    videoUrl: videoUrl,
    videoSearchQuery: videoSearchQuery,
    musclesTargeted: const ['petto'],
  );
}

const _video = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Widget host(Exercise e, {VideoProbe? probe}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ExerciseVideoSheet(exercise: e, probe: probe),
        ),
      ),
    );
  }

  group('esercizio senza un video scelto', () {
    testWidgets('offre la ricerca invece di fingere un video', (tester) async {
      // Il caso di 28 esercizi su 43.
      await tester.pumpWidget(
        host(exercise(videoSearchQuery: 'panca piana bilanciere')),
      );

      expect(find.text('Cerca su YouTube'), findsOneWidget);
      expect(
        find.textContaining('non e ancora stato scelto un video'),
        findsOneWidget,
      );
    });

    testWidgets('senza nemmeno una ricerca lo dice, e non offre nulla', (
      tester,
    ) async {
      await tester.pumpWidget(host(exercise()));

      expect(find.text('Cerca su YouTube'), findsNothing);
      expect(find.textContaining("non c'e ancora un video"), findsOneWidget);
    });

    testWidgets('non interroga la rete: non c e niente da chiedere', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        host(
          exercise(videoSearchQuery: 'panca piana'),
          probe: (_) async {
            called = true;
            return 200;
          },
        ),
      );
      await tester.pump();

      expect(called, isFalse);
    });
  });

  group('esercizio con un video', () {
    testWidgets('mentre chiede a YouTube mostra un attesa, non il vuoto', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          exercise(videoUrl: _video),
          // La risposta arriva tardi, e non e 200: il riproduttore ha bisogno
          // di una WebView, che in un test non esiste. Qui interessa cosa si
          // vede **prima** della risposta.
          probe: (_) async {
            await Future<void>.delayed(const Duration(seconds: 1));
            return 404;
          },
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Si lascia scadere l'attesa, altrimenti il test finisce con un timer
      // ancora vivo.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('un video rimosso mostra un messaggio, non una schermata bianca', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(exercise(videoUrl: _video), probe: (_) async => 404),
      );
      await tester.pump();

      expect(find.textContaining('non e piu disponibile'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('senza rete si spiega che serve la connessione', (tester) async {
      await tester.pumpWidget(
        host(
          exercise(videoUrl: _video),
          probe: (_) async => throw const SocketException('niente rete'),
        ),
      );
      await tester.pump();

      expect(find.textContaining('serve una connessione'), findsOneWidget);
      // Il messaggio e diverso da quello del video rimosso: sono due
      // situazioni diverse e chi legge deve poterle distinguere.
      expect(find.textContaining('non e piu disponibile'), findsNothing);
    });
  });

  group('cosa si vede sempre', () {
    testWidgets('il nome dell esercizio, in ogni stato', (tester) async {
      for (final e in [
        exercise(),
        exercise(videoSearchQuery: 'panca piana'),
        exercise(videoUrl: _video),
      ]) {
        await tester.pumpWidget(host(e, probe: (_) async => 404));
        await tester.pump();
        expect(find.text('Panca piana'), findsOneWidget);
      }
    });
  });
}
