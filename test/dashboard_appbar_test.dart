import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:gymflow/src/ui/screens/dashboard_screen.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/services/firestore_service.dart' as svc;
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/session.dart';

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
/// ---
///
/// **Cio che segue non descrive piu la Home.** Il redesign Immersivo l'ha
/// riscritta da capo (vedi la nota in cima a `dashboard_screen.dart`): non
/// c'e piu una `SliverAppBar`, non c'e piu un cassetto ad amburger — le sue 5
/// destinazioni sono riquadri sulla Home — e non c'e piu un saluto personale:
/// il mockup non ne ha uno, ha il logo GYMFLOW. L'intestazione oggi e statica
/// (un'immagine con overlay dentro un `Column` a `Expanded`), non uno spazio
/// flessibile che si comprime scorrendo: l'intera classe di difetto che
/// questo file sorvegliava — un testo che risale sotto le icone mentre la
/// barra si comprime — non puo piu accadere, perche il meccanismo che la
/// causava e stato tolto, non solo corretto.
///
/// I quattro test sotto sono stati riscritti per verificarlo esplicitamente
/// invece di misurare una struttura che non esiste piu: provano che i widget
/// del vecchio meccanismo (`SliverAppBar`, `NestedScrollView`) sono assenti, e
/// che nessun nome utente arbitrario compare piu in Home — nemmeno quello
/// lungo che il vecchio test troncava, perche oggi il nome utente non ci si
/// mostra affatto. Vedi il report della storia di manutenzione test/ per
/// l'elenco di cosa e stato adattato e perche.
///
/// **Limite dichiarato**: questi test provano l'assenza del meccanismo
/// difettoso, non l'aspetto della nuova intestazione — quello resta da
/// confermare sull'APK, come per il file originale.
class FakeFirestoreService implements svc.FirestoreService {
  @override
  Stream<List<WorkoutProgram>> getUserPrograms(String userId) =>
      Stream.value([]);
  @override
  Stream<List<WorkoutTemplate>> getUserWorkouts(String userId) =>
      Stream.value([]);
  @override
  Stream<List<WorkoutSession>> getUserSessions(String userId) =>
      Stream.value([]);
  @override
  Stream<List<ScheduledWorkout>> getUserScheduledWorkouts(String userId) =>
      Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCurrentUser extends CurrentUser {
  @override
  User? build() => null;
}

class FakeCurrentUserId extends CurrentUserId {
  @override
  String? build() => '123';
}

class FakeFirestoreNotifier extends FirestoreService {
  @override
  svc.FirestoreService build() => FakeFirestoreService();
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
      currentUserProvider.overrideWith(FakeCurrentUser.new),
      currentUserIdProvider.overrideWith(FakeCurrentUserId.new),
      firestoreServiceProvider.overrideWith(FakeFirestoreNotifier.new),
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

  testWidgets(
    'la Home non ha piu una barra che si comprime: niente da ritagliare',
    (tester) async {
      await tester.pumpWidget(dashboard('Mario'));
      await tester.pumpAndSettle();

      // Il meccanismo che il vecchio test proteggeva (uno spazio flessibile
      // ritagliato sotto le icone) esiste solo se esiste una `SliverAppBar`
      // con `FlexibleSpaceBar`. Qui non c'e: lo `Scaffold` della Home non ha
      // nemmeno un `appBar`.
      expect(find.byType(SliverAppBar), findsNothing);
      expect(find.byType(FlexibleSpaceBar), findsNothing);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).appBar, isNull);
    },
  );

  testWidgets(
    'a riposo non c e piu un saluto personale: al suo posto il logo GYMFLOW',
    (tester) async {
      await tester.pumpWidget(dashboard('Mario'));
      await tester.pumpAndSettle();

      // Il mockup Immersivo non ha un saluto (vedi la nota in cima al file):
      // la scritta fissa 'Bentornato,' e il nome dell'atleta non compaiono
      // piu da nessuna parte, sostituiti dal logo dell'app.
      expect(find.text('Bentornato,'), findsNothing);
      expect(find.text('Mario'), findsNothing);
      expect(find.text('GYMFLOW'), findsOneWidget);
    },
  );

  testWidgets(
    'il nome utente, anche lungo, non compare piu: niente da troncare',
    (tester) async {
      // Stesso input del vecchio test («nome lungo»), ma la domanda e
      // cambiata: prima si verificava che il nome venisse troncato invece di
      // sbordare, oggi che la Home non lo mostri affatto — quindi non c'e
      // piu un bordo da sbordare.
      const nomeLungo =
          'Bartolomeo Massimiliano della Valle di Sotto e di Sopra';
      await tester.pumpWidget(dashboard(nomeLungo));
      await tester.pumpAndSettle();

      expect(find.text(nomeLungo), findsNothing);
      expect(find.textContaining('Bartolomeo'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'niente NestedScrollView da comprimere: l intestazione e statica',
    (tester) async {
      await tester.pumpWidget(dashboard('Mario'));
      await tester.pumpAndSettle();

      // Il vecchio test scorreva una `NestedScrollView` per far comprimere la
      // barra e vedere il nome ricomparire nella toolbar. Qui non c'e una
      // `NestedScrollView`: l'intestazione (l'immagine con overlay, o il
      // logo di `_EmptyHome`) non si comprime scorrendo.
      expect(find.byType(NestedScrollView), findsNothing);
      expect(find.byType(NavigationToolbar), findsNothing);
    },
  );
}
