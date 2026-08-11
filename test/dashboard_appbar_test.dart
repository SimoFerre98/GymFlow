import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/ui/screens/dashboard_screen.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/exercise.dart';

/// Il saluto della home non finisce sotto le icone della barra.
///
/// **Perche non basta confrontare i rettangoli.** Il primo test scritto per
/// questa storia cercava il nome dentro `NavigationToolbar` e verificava che non
/// si intersecasse con l'hamburger: ma quel titolo lo posiziona Material fra il
/// cassetto e le azioni, quindi **non puo** intersecarli, e il test restava
/// verde anche senza correzione — misurato, e restava verde pure senza scorrere
/// affatto. Il widget che si sovrappone e un altro: il titolo dello spazio
/// flessibile, che sale insieme al fondo della barra.
///
/// La correzione ritaglia lo spazio flessibile sotto la fascia occupata dalle
/// icone. Un ritaglio impedisce il **disegno**, non il layout: `getRect`
/// continua a restituire un rettangolo sovrapposto, e un test sui rettangoli
/// direbbe il falso in tutte e due le direzioni. Quello che si puo fissare, e
/// che vale, e l'invariante in due pezzi qui sotto.
///
/// **Limite dichiarato**: nessuno di questi test guarda i pixel disegnati.
/// Provano che il ritaglio c'e e che le icone stanno tutte sopra la linea di
/// taglio; che il risultato si legga bene mentre si scorre resta da confermare
/// sull'APK.
class FakeFirestoreService implements FirestoreService {
  @override
  Stream<List<WorkoutProgram>> getUserPrograms(String userId) =>
      Stream.value([]);
  @override
  Stream<List<WorkoutTemplate>> getUserWorkouts(String userId) =>
      Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalization extends Localization {
  const FakeLocalization(this.athleteName) : super(const Locale('it'));
  final String athleteName;
  @override
  String t(String key) {
    if (key == 'athlete') return athleteName;
    if (key == 'welcome_back') return 'Bentornato,';
    return key;
  }
}

class TestLocalizationNotifier extends LocalizationNotifier {
  TestLocalizationNotifier(this.athleteName);
  final String athleteName;
  @override
  Localization build() => FakeLocalization(athleteName);
}

class FakeExercises extends Exercises {
  @override
  Future<List<Exercise>> build() async => [];
}

void main() {
  Widget dashboard(String userName) => ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => null),
      currentUserIdProvider.overrideWith((ref) => '123'),
      firestoreServiceProvider.overrideWithValue(FakeFirestoreService()),
      exercisesProvider.overrideWith(() => FakeExercises()),
      localizationNotifierProvider.overrideWith(
        () => TestLocalizationNotifier(userName),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme(Colors.blue),
      home: const DashboardScreen(),
    ),
  );

  /// Il ritaglio applicato allo spazio flessibile, e la sua linea superiore.
  double lineaDiTaglio(WidgetTester tester) {
    final ritaglio = find.descendant(
      of: find.byType(SliverAppBar),
      matching: find.byWidgetPredicate(
        (w) => w is ClipRect && w.clipper != null,
      ),
    );
    expect(
      ritaglio,
      findsWidgets,
      reason: 'lo spazio flessibile non e ritagliato: senza ritaglio il saluto '
          'viene disegnato sopra le icone mentre si scorre',
    );
    final widget = tester.widgetList<ClipRect>(ritaglio).first;
    return widget.clipper!.getClip(tester.getSize(ritaglio.first)).top;
  }

  testWidgets('le icone della barra stanno tutte sopra la linea di taglio', (
    tester,
  ) async {
    await tester.pumpWidget(dashboard('Mario'));
    await tester.pumpAndSettle();

    final taglio = lineaDiTaglio(tester);
    expect(taglio, greaterThan(0));

    // Se ogni icona sta interamente sopra la linea, allora niente di cio che
    // viene disegnato sotto puo coprirla: e questo che rende la sovrapposizione
    // impossibile, non la posizione del titolo in un istante particolare.
    for (final icona in [Icons.menu, Icons.bar_chart]) {
      final trovata = find.byIcon(icona);
      expect(trovata, findsOneWidget, reason: 'icona $icona assente');
      expect(
        tester.getRect(trovata).bottom,
        lessThanOrEqualTo(taglio),
        reason: 'l icona $icona sporge sotto la linea di taglio, quindi il '
            'saluto puo finirle sopra',
      );
    }
  });

  testWidgets('a riposo il saluto resta dove la home lo ha sempre avuto', (
    tester,
  ) async {
    await tester.pumpWidget(dashboard('Mario'));
    await tester.pumpAndSettle();

    // Misurato su `main` prima di questa storia: il blocco non si sposta e non
    // rimpicciolisce. La larghezza e la prova che l'ingrandimento che
    // `FlexibleSpaceBar` applica al proprio titolo c'e ancora: senza, il saluto
    // sarebbe largo circa 157 invece di 235.
    final saluto = tester.getRect(find.text('Bentornato,'));
    expect(saluto.left, 20.0);
    expect(saluto.top, closeTo(67.5, 0.5));
    expect(saluto.width, closeTo(235.1, 1.0));
  });

  testWidgets('il nome lungo viene troncato invece di sbordare', (
    tester,
  ) async {
    const nomeLungo =
        'Bartolomeo Massimiliano della Valle di Sotto e di Sopra';
    await tester.pumpWidget(dashboard(nomeLungo));
    await tester.pumpAndSettle();

    for (final testo in tester.widgetList<Text>(find.text(nomeLungo))) {
      expect(
        testo.maxLines,
        1,
        reason: 'senza maxLines il nome va a capo e il blocco cresce',
      );
      expect(testo.overflow, TextOverflow.ellipsis);
    }

    // E non esce dallo schermo.
    final larghezza = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    for (final r in find
        .text(nomeLungo)
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget as Text)))) {
      expect(r.right, lessThanOrEqualTo(larghezza));
    }
  });

  testWidgets('a barra compressa il nome compare nella toolbar', (
    tester,
  ) async {
    await tester.pumpWidget(dashboard('Mario'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final nellaToolbar = find.descendant(
      of: find.byType(NavigationToolbar),
      matching: find.text('Mario'),
    );
    expect(nellaToolbar, findsOneWidget);
    expect(
      tester.getRect(nellaToolbar).overlaps(tester.getRect(find.byIcon(Icons.menu))),
      isFalse,
    );
  });
}
