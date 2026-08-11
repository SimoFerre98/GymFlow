import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/dashboard_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/contrast.dart';
import 'package:gymflow/src/core/utils/personal_record.dart';
import 'package:gymflow/src/core/utils/workout_summary.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/ui/screens/workout_summary_screen.dart';
import 'package:gymflow/src/ui/widgets/workout_receipt.dart';

void main() {
  Widget createReceiptWidget({
    required WorkoutSummary summary,
    Locale locale = const Locale('it'),
  }) {
    return ProviderScope(
      overrides: [
        localizationNotifierProvider.overrideWith(
          () => _FakeLocalizationNotifier(Localization(locale)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme(const Color(0xFFF0C38E)),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: WorkoutReceipt(summary: summary),
            ),
          ),
        ),
      ),
    );
  }

  group('WorkoutReceipt Widget', () {
    testWidgets('mostra tutti i dati quando presenti', (tester) async {
      final summary = WorkoutSummary(
        workoutName: 'Spinte',
        startTime: DateTime(2026, 8, 6, 10, 0),
        endTime: DateTime(2026, 8, 6, 10, 48),
        totalVolume: 4240,
        completedSets: 18,
        totalSets: 18,
        averageRpe: 7.6,
        calories: 412,
        avgHeartRate: 131,
      );

      await tester.pumpWidget(createReceiptWidget(summary: summary));
      await tester.pumpAndSettle();

      expect(find.text('Spinte'), findsOneWidget);
      expect(find.text('48 min'), findsOneWidget);
      expect(find.text('4 240 kg'), findsOneWidget);
      expect(find.text('18 / 18'), findsOneWidget);
      expect(find.text('RPE 7,6'), findsOneWidget);
      expect(find.text('412 kcal'), findsOneWidget);
      expect(find.text('131 bpm'), findsOneWidget);
    });

    testWidgets('non mostra le righe di calorie, battito e rpe se sono null', (tester) async {
      final summary = WorkoutSummary(
        workoutName: 'Trazioni',
        startTime: DateTime(2026, 8, 6, 10, 0),
        endTime: DateTime(2026, 8, 6, 10, 30),
        totalVolume: 1200,
        completedSets: 10,
        totalSets: 12,
        averageRpe: null,
        calories: null,
        avgHeartRate: null,
      );

      await tester.pumpWidget(createReceiptWidget(summary: summary));
      await tester.pumpAndSettle();

      expect(find.text('Trazioni'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('1 200 kg'), findsOneWidget);
      expect(find.text('10 / 12'), findsOneWidget);

      // Nessuna riga a zero per calorie, battito o rpe
      expect(find.textContaining('kcal'), findsNothing);
      expect(find.textContaining('bpm'), findsNothing);
      expect(find.textContaining('RPE'), findsNothing);
      expect(find.textContaining('0 kcal'), findsNothing);
      expect(find.textContaining('0 bpm'), findsNothing);
    });

    testWidgets('le serie non completate sono visibili nel denominatore', (tester) async {
      final summary = WorkoutSummary(
        workoutName: 'Gambe Interrotte',
        startTime: DateTime(2026, 8, 6, 10, 0),
        endTime: DateTime(2026, 8, 6, 10, 25),
        totalVolume: 2500,
        completedSets: 12,
        totalSets: 18,
      );

      await tester.pumpWidget(createReceiptWidget(summary: summary));
      await tester.pumpAndSettle();

      expect(find.text('12 / 18'), findsOneWidget);
    });
  });

  group('ReceiptClipper', () {
    test('genera un Path non vuoto con le dimensioni specificate', () {
      const clipper = ReceiptClipper(topRadius: 22, scallopRadius: 7);
      final path = clipper.getClip(const Size(300, 200));

      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.width, 300);
      expect(bounds.height, 200);
    });
  });
  group('WorkoutSummaryScreen Widget', () {
    testWidgets('mostra pillola di stato, data, scontrino e pulsante chiudi', (tester) async {
      final session = WorkoutSession(
        id: 's1',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Spinte & Petto',
        startTime: DateTime(2026, 8, 6, 10, 0),
        endTime: DateTime(2026, 8, 6, 10, 48),
        exercises: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationNotifierProvider.overrideWith(
              () => _FakeLocalizationNotifier(
                const Localization(Locale('it')),
              ),
            ),
            dashboardSessionsProvider.overrideWith(
              () => _FakeDashboardSessions(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(const Color(0xFFF0C38E)),
            home: WorkoutSummaryScreen(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Allenamento chiuso'), findsOneWidget);
      expect(find.text('6 ago'), findsOneWidget);
      expect(find.text('Spinte & Petto'), findsOneWidget);
      // "Salva e chiudi" mentiva: il salvataggio avviene prima, e dallo
      // storico non c'e niente da salvare.
      expect(find.text('Chiudi'), findsOneWidget);
      expect(find.byType(WorkoutReceipt), findsOneWidget);

      // L'etichetta si legge sul fondo del pulsante.
      //
      // Non e un dettaglio: il tema dipinge tutti i testi di `onSurface`, e uno
      // `style` che porta il colore dentro vince sul `foregroundColor` del
      // pulsante. Cosi l'etichetta era carta chiara su ambra chiara, circa
      // 1,3:1, e sul telefono non si leggeva. I test dei contrasti non potevano
      // vederlo: misurano le coppie dei ruoli del tema, non quelle che una
      // schermata si costruisce sovrascrivendo un colore.
      final etichetta = tester.widget<Text>(find.text('Chiudi'));
      final fondo = AppTheme.darkTheme(const Color(0xFFF0C38E)).colorScheme;
      expect(
        etichetta.style?.color,
        isNotNull,
        reason: 'senza colore esplicito vince quello del tema, non del pulsante',
      );
      expect(
        Contrast.ratio(etichetta.style!.color!, fondo.primary),
        greaterThanOrEqualTo(Contrast.aa),
        reason: 'l etichetta del pulsante non si legge sul suo fondo',
      );

      // Toccare Chiudi
      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();
    });

    testWidgets('mostra la card del record personale quando presente', (tester) async {
      final session = WorkoutSession(
        id: 's1',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Spinte & Petto',
        startTime: DateTime(2026, 8, 6, 10, 0),
        endTime: DateTime(2026, 8, 6, 10, 48),
        exercises: [],
      );

      final record = PersonalRecord(
        exerciseId: 'bench',
        exerciseName: 'Panca piana',
        newWeight: 62.5,
        newReps: 8,
        previousWeight: 60.0,
        previousDate: DateTime(2026, 7, 21),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationNotifierProvider.overrideWith(
              () => _FakeLocalizationNotifier(
                const Localization(Locale('it')),
              ),
            ),
            dashboardSessionsProvider.overrideWith(
              () => _FakeDashboardSessions(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(const Color(0xFFF0C38E)),
            home: WorkoutSummaryScreen(session: session, records: [record]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECORD'), findsOneWidget);
      expect(find.text('+2,5 kg'), findsOneWidget);
      expect(find.text('Panca piana · 62,5 kg × 8'), findsOneWidget);
      expect(
        find.textContaining('Il massimo precedente era 60 kg, il 21 lug'),
        findsOneWidget,
      );
    });

    testWidgets('non mostra card dei record se la lista dei record e vuota', (tester) async {
      final session = WorkoutSession(
        id: 's1',
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Spinte & Petto',
        startTime: DateTime(2026, 8, 6, 10, 0),
        endTime: DateTime(2026, 8, 6, 10, 48),
        exercises: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationNotifierProvider.overrideWith(
              () => _FakeLocalizationNotifier(
                const Localization(Locale('it')),
              ),
            ),
            dashboardSessionsProvider.overrideWith(
              () => _FakeDashboardSessions(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(const Color(0xFFF0C38E)),
            home: WorkoutSummaryScreen(session: session, records: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECORD'), findsNothing);
    });
  });
}

class _FakeLocalizationNotifier extends LocalizationNotifier {
  _FakeLocalizationNotifier(this._loc);
  final Localization _loc;

  @override
  Localization build() => _loc;
}

class _FakeDashboardSessions extends DashboardSessions {
  @override
  Stream<List<WorkoutSession>> build() async* {
    yield [];
  }
}
