import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymflow/src/core/providers/dashboard_provider.dart';
import 'package:gymflow/src/core/providers/goals_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/user_goal.dart';
import 'package:gymflow/src/ui/screens/workout_summary_screen.dart';

/// Riproduce il difetto: aprendo il riepilogo, l'obiettivo "N allenamenti a
/// settimana" veniva aggiornato con `[session]` — solo la sessione mostrata,
/// mai la settimana intera — quindi il conteggio non poteva superare 1, e
/// riaprire dallo storico una sessione più vecchia di 7 giorni azzerava un
/// progresso vero. `WorkoutSummaryScreen` ora passa tutte le sessioni note
/// (`allSessions`, più quella mostrata se ancora assente), non solo quella.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('it');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  WorkoutSession sessionAt(String id, DateTime startTime) => WorkoutSession(
        id: id,
        userId: 'u1',
        workoutTemplateId: 't1',
        workoutName: 'Spinte',
        startTime: startTime,
        endTime: startTime.add(const Duration(minutes: 40)),
        exercises: const [],
      );

  testWidgets(
    'il progresso settimanale conta tutte le sessioni recenti, non solo quella mostrata',
    (tester) async {
      final now = DateTime.now();
      final sessions = [
        sessionAt('s1', now.subtract(const Duration(days: 1))),
        sessionAt('s2', now.subtract(const Duration(days: 3))),
        sessionAt('s3', now.subtract(const Duration(days: 5))),
      ];

      final container = ProviderContainer(
        overrides: [
          localizationNotifierProvider.overrideWith(
            () => _FakeLocalizationNotifier(const Localization(Locale('it'))),
          ),
          dashboardSessionsProvider.overrideWith(
            () => _FakeDashboardSessions(sessions),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme(const Color(0xFFF0C38E)),
            // Si apre la prima sessione, come farebbe lo storico: e la meno
            // recente delle tre a comparire nella lista, cosi non e quella
            // che "per caso" trascinerebbe con se le altre due nel giro
            // sbagliato di prima (dove contava solo se stessa).
            home: WorkoutSummaryScreen(session: sessions.first),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final freqGoal = container
          .read(userGoalsNotifierProvider)
          .firstWhere((g) => g.type == GoalType.workoutFrequency);
      expect(freqGoal.currentValue, 3.0);
      expect(freqGoal.isAchieved, isTrue);
    },
  );

  testWidgets(
    'riaprire dallo storico una sessione vecchia non azzera il progresso',
    (tester) async {
      final now = DateTime.now();
      final recenti = [
        sessionAt('s1', now.subtract(const Duration(days: 1))),
        sessionAt('s2', now.subtract(const Duration(days: 2))),
      ];
      final vecchia = sessionAt('old', now.subtract(const Duration(days: 40)));

      final container = ProviderContainer(
        overrides: [
          localizationNotifierProvider.overrideWith(
            () => _FakeLocalizationNotifier(const Localization(Locale('it'))),
          ),
          dashboardSessionsProvider.overrideWith(
            () => _FakeDashboardSessions([...recenti, vecchia]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme(const Color(0xFFF0C38E)),
            // Si riapre proprio quella vecchia, come da storico: prima del
            // fix questo azzerava a 0 il progresso delle due recenti.
            home: WorkoutSummaryScreen(session: vecchia),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final freqGoal = container
          .read(userGoalsNotifierProvider)
          .firstWhere((g) => g.type == GoalType.workoutFrequency);
      expect(freqGoal.currentValue, 2.0);
    },
  );
}

class _FakeLocalizationNotifier extends LocalizationNotifier {
  _FakeLocalizationNotifier(this._loc);
  final Localization _loc;

  @override
  Localization build() => _loc;
}

class _FakeDashboardSessions extends DashboardSessions {
  _FakeDashboardSessions(this._sessions);
  final List<WorkoutSession> _sessions;

  @override
  Stream<List<WorkoutSession>> build() async* {
    yield _sessions;
  }
}
