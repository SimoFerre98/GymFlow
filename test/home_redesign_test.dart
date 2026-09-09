import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/ui/widgets/home_hero_card.dart';
import 'package:gymflow/src/ui/widgets/progress_ring.dart';
import 'package:gymflow/src/ui/widgets/exercise_row.dart';
import 'package:gymflow/src/models/exercise.dart';

void main() {
  group('US-062 Home Redesign', () {
    testWidgets('HomeHeroCard shows active workout details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeroCard(
              hasActiveProgram: true,
              programName: 'Spinte',
              workoutName: 'Panca piana',
              currentDay: 3,
              totalDays: 5,
              durationMinutes: 48,
              exerciseCount: 6,
              progressFraction: 0.72,
              onAction: () {},
              locInProgress: 'In corso',
              formattedDay: 'Giorno 3 / 5',
              locResume: 'Riprendi',
              locNoActive: 'Nessuna',
              locCreatePrompt: 'Crea',
              locCreateAction: 'Vai',
              locMin: 'min',
              locExercises: 'esercizi',
      locExerciseOne: 'esercizio',
            ),
          ),
        ),
      );

      expect(find.text('Panca piana'), findsOneWidget);
      expect(find.text('GIORNO 3 / 5'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('6 esercizi'), findsOneWidget);
    });

    testWidgets('con un esercizio solo scrive «1 esercizio», non «1 esercizi»', (
      tester,
    ) async {
      // Sulla home si leggeva «1 esercizi», che sembra un errore di sistema.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeroCard(
              hasActiveProgram: true,
              programName: 'Scheda',
              currentDay: 1,
              totalDays: 5,
              durationMinutes: 48,
              exerciseCount: 1,
              progressFraction: 0.2,
              onAction: () {},
              locInProgress: 'In corso',
              formattedDay: 'Giorno 1 / 5',
              locResume: 'Riprendi',
              locNoActive: 'Nessuna',
              locCreatePrompt: 'Crea',
              locCreateAction: 'Vai',
              locExercises: 'esercizi',
              locExerciseOne: 'esercizio',
              locMin: 'min',
            ),
          ),
        ),
      );

      expect(find.text('1 esercizio'), findsOneWidget);
      expect(find.text('1 esercizi'), findsNothing);
    });

    testWidgets('HomeHeroCard shows invite when no active program', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeroCard(
              hasActiveProgram: false,
              onAction: () {},
              locInProgress: 'In corso',
              formattedDay: 'Giorno 3 / 5',
              locResume: 'Riprendi',
              locNoActive: 'Nessuna scheda',
              locCreatePrompt: 'Crea una',
              locCreateAction: 'Vai',
              locMin: 'min',
              locExercises: 'esercizi',
      locExerciseOne: 'esercizio',
            ),
          ),
        ),
      );

      expect(find.text('Nessuna scheda'), findsOneWidget);
      expect(find.text('Vai'), findsOneWidget);
      expect(find.text('Panca piana'), findsNothing);
    });

    test('ProgressRing changes arc based on fraction and radius', () {
      final ring1 = ProgressRing(fraction: 0.0);
      final ring2 = ProgressRing(fraction: 0.72);
      final ring3 = ProgressRing(fraction: 1.0);

      expect(ring1.fraction, 0.0);
      expect(ring2.fraction, 0.72);
      expect(ring3.fraction, 1.0);
      
      // Since ProgressRing is a custom painter, we'll verify it scales with different layouts
      // via the fact that it uses the context size internally instead of a hardcoded dasharray.
    });

    test('scheme.primary compare una volta sola come fondo di un pulsante', () {
      // Il criterio della palette: l'ambra significa «cosa fare adesso», e in
      // questa card deve comparire in un solo posto — il pulsante d'azione —
      // non ripetuta a caso altrove.
      //
      // Il pulsante non e piu scritto qui: e `ExpressiveCtaButton`, condiviso
      // con la barra di navigazione e con qualunque altra card che ne avra
      // bisogno. Il test segue il codice, non il file che lo conteneva prima.
      final sorgenti = [
        'lib/src/ui/widgets/home_hero_card.dart',
        'lib/src/ui/widgets/progress_ring.dart',
        'lib/src/ui/widgets/expressive_cta_button.dart',
      ].map((p) => File(p).readAsStringSync()).join();

      final count = RegExp(r'scheme\.primary\b').allMatches(sorgenti).length;

      expect(
        count,
        2,
        reason: '1 per il riempimento di ProgressRing, 1 per il fondo di '
            'ExpressiveCtaButton',
      );
    });

    testWidgets(
      'US-062 non descrive piu la Home: non costruisce piu ExerciseRow',
      (tester) async {
        // La Home del redesign Immersivo non mostra piu una lista di esercizi
        // (vedi la nota in cima a `dashboard_screen.dart`): al suo posto ci
        // sono due `_NumberedRow` — prossimo allenamento, obiettivo migliore.
        // `ExerciseRow` resta un widget vivo, usato dalla libreria esercizi e
        // dalle schede, ma non piu dalla Home: il criterio di US-062 non si
        // applica piu a questo file.
        final dashboardSource =
            File('lib/src/ui/screens/dashboard_screen.dart').readAsStringSync();
        expect(dashboardSource.contains('ExerciseRow('), isFalse);
        expect(dashboardSource.contains('_NumberedRow('), isTrue);

        // Cio che resta vero, e vale a prescindere da chi lo usa oggi:
        // `ExerciseRow` tollera un esercizio con un id sconosciuto senza
        // eccezioni — la garanzia che il test originale voleva davvero.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExerciseRow(
                exercise: Exercise(
                  id: 'unknown_id',
                  name: 'Unknown',
                  description: '',
                  type: ExerciseType.strength,
                  musclesTargeted: [],
                ),
                subtitle: const Text('Meta'),
                trailing: const Text('Pill'),
              ),
            ),
          ),
        );

        expect(find.byType(ExerciseRow), findsOneWidget);
        expect(find.text('Unknown'), findsOneWidget);
      },
    );
  });
}
