import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/ui/widgets/exercise_image.dart';
import 'package:gymflow/src/ui/widgets/exercise_thumbnail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un indice fisso, al posto di quello che passa da Firestore.
///
/// Serve perche l'indice vero risale a `currentUserIdProvider` e da li a
/// Firebase, che in un test non e inizializzato. Con lo stub il test misura la
/// risoluzione dell'identificativo, che e cio che abbiamo scritto.
class _StubIndex extends ExerciseIndex {
  _StubIndex(this.entries);

  final Map<String, Exercise> entries;

  @override
  Map<String, Exercise> build() => entries;
}

Exercise exercise({
  String id = 'e1',
  String name = 'Panca piana',
  String? videoUrl,
  String? videoSearchQuery,
  String? imageUrl,
  List<String> muscles = const ['petto'],
}) {
  return Exercise(
    id: id,
    name: name,
    description: '',
    type: ExerciseType.strength,
    videoUrl: videoUrl,
    videoSearchQuery: videoSearchQuery,
    imageUrl: imageUrl,
    musclesTargeted: muscles,
  );
}

const _videoUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

/// Il badge del video e l'unica icona di riproduzione della miniatura.
Finder get videoBadge => find.byIcon(Icons.play_arrow_rounded);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // La localizzazione, da cui viene l'etichetta del badge, rilegge la lingua
    // salvata all'avvio. Senza valori finti la lettura fallirebbe per un motivo
    // che non ha nulla a che vedere con la miniatura.
    SharedPreferences.setMockInitialValues({});
  });

  Widget host(Widget child, {Map<String, Exercise>? index, ThemeData? theme}) {
    return ProviderScope(
      overrides: [
        if (index != null)
          exerciseIndexProvider.overrideWith(() => _StubIndex(index)),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.darkTheme(AppPalette.amber),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('indicatore del video', () {
    testWidgets('un video vero porta l indicatore', (tester) async {
      await tester.pumpWidget(
        host(ExerciseThumbnail(exercise: exercise(videoUrl: _videoUrl))),
      );

      expect(videoBadge, findsOneWidget);
    });

    testWidgets('il badge e salmone (tertiary) e misura 18x18', (tester) async {
      final theme = AppTheme.darkTheme(AppPalette.amber);
      await tester.pumpWidget(
        host(
          ExerciseThumbnail(exercise: exercise(videoUrl: _videoUrl)),
          theme: theme,
        ),
      );

      final badgeContainer = tester.widget<Container>(
        find
            .ancestor(
              of: videoBadge,
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = badgeContainer.decoration as BoxDecoration?;
      expect(decoration?.color, theme.colorScheme.tertiary);
      const tokens = ExpressiveTokens();
      expect(badgeContainer.constraints?.minWidth, tokens.sizing.badge);
      expect(badgeContainer.constraints?.minHeight, tokens.sizing.badge);

      final icon = tester.widget<Icon>(videoBadge);
      expect(icon.color, theme.colorScheme.onTertiary);
      // Derivata dal token, non un numero a parte: se la misura del badge
      // cambia, il simbolo dentro la segue.
      expect(icon.size, tokens.sizing.badge * 0.72);
    });

    testWidgets('una sola ricerca NON porta l indicatore', (tester) async {
      // E il caso di 28 esercizi su 43. Un indicatore qui promette
      // l'esecuzione e consegna una lista di risultati: e la ragione per cui
      // US-041 ha tenuto separati videoUrl e videoSearchQuery.
      await tester.pumpWidget(
        host(
          ExerciseThumbnail(
            exercise: exercise(videoSearchQuery: 'panca piana bilanciere'),
          ),
        ),
      );

      expect(videoBadge, findsNothing);
    });

    testWidgets('senza nulla non c e indicatore', (tester) async {
      await tester.pumpWidget(host(ExerciseThumbnail(exercise: exercise())));

      expect(videoBadge, findsNothing);
    });

    testWidgets('un URL che non e un video non porta l indicatore', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          ExerciseThumbnail(
            exercise: exercise(videoUrl: 'https://vimeo.com/123456'),
          ),
        ),
      );

      expect(videoBadge, findsNothing);
    });

    testWidgets('l indicatore ha un etichetta per chi non vede la miniatura', (
      tester,
    ) async {
      // Qui l'immagine NON e decorativa: il badge e l'unico posto in cui
      // l'informazione "c'e un video" esiste.
      await tester.pumpWidget(
        host(ExerciseThumbnail(exercise: exercise(videoUrl: _videoUrl))),
      );

      expect(
        find.bySemanticsLabel("Video dell'esecuzione disponibile"),
        findsOneWidget,
      );
    });
  });

  group('misura e forma dai token', () {
    testWidgets('la miniatura misura thumbnailMd', (tester) async {
      await tester.pumpWidget(host(ExerciseThumbnail(exercise: exercise())));

      const tokens = ExpressiveTokens();
      expect(
        tester.getSize(find.byType(ExerciseThumbnail)),
        Size.square(tokens.sizing.thumbnailMd),
      );
    });

    testWidgets('un lato dichiarato vince sul token', (tester) async {
      await tester.pumpWidget(
        host(ExerciseThumbnail(exercise: exercise(), side: 72)),
      );

      expect(
        tester.getSize(find.byType(ExerciseThumbnail)),
        const Size.square(72),
      );
    });

    testWidgets('gli angoli sono quelli dei token, non un valore scritto', (
      tester,
    ) async {
      await tester.pumpWidget(host(ExerciseThumbnail(exercise: exercise())));

      const tokens = ExpressiveTokens();
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, tokens.shape.cornerMd);
    });

    testWidgets('la miniatura chiede la decodifica alla sua misura', (
      tester,
    ) async {
      // Una miniatura YouTube e larga 480 px: senza questo, cento celle
      // tengono in memoria trenta volte i pixel che servono.
      await tester.pumpWidget(host(ExerciseThumbnail(exercise: exercise())));

      const tokens = ExpressiveTokens();
      final image = tester.widget<ExerciseImage>(find.byType(ExerciseImage));
      expect(image.decodeWidth, tokens.sizing.thumbnailMd);
    });
  });

  group('stabilita del layout', () {
    testWidgets('la misura non cambia quando l immagine arriva', (tester) async {
      // Il criterio dice "senza far saltare il layout": la proprieta si misura,
      // invece di guardarla.
      await tester.pumpWidget(
        host(
          ExerciseThumbnail(
            exercise: exercise(imageUrl: 'https://storage/curata.jpg'),
          ),
        ),
      );

      final beforeFrame = tester.getSize(find.byType(ExerciseThumbnail));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final afterFrame = tester.getSize(find.byType(ExerciseThumbnail));

      const tokens = ExpressiveTokens();
      expect(beforeFrame, Size.square(tokens.sizing.thumbnailMd));
      expect(afterFrame, beforeFrame);
    });

    testWidgets('anche il segnaposto occupa esattamente lo stesso spazio', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              ExerciseThumbnail(exercise: exercise(id: 'a')),
              ExerciseThumbnail(
                exercise: exercise(id: 'b', videoUrl: _videoUrl),
              ),
            ],
          ),
        ),
      );

      final sizes = tester
          .widgetList<ExerciseThumbnail>(find.byType(ExerciseThumbnail))
          .map((w) => tester.getSize(find.byWidget(w)))
          .toSet();
      // Un esercizio con immagine e uno senza non devono allineare i nomi in
      // due colonne diverse.
      expect(sizes.length, 1);
    });
  });

  group('dentro un ListTile, come nelle tre schermate', () {
    testWidgets('non sfora il riquadro di una cella a due righe', (
      tester,
    ) async {
      // La miniatura misura 56 e una cella a due righe e alta 72: sette pixel
      // per parte. E il posto dove un `RenderFlex overflowed` comparirebbe, e
      // nessuno dei test finora guarda una cella vera.
      await tester.pumpWidget(
        host(
          ListTile(
            leading: ExerciseThumbnail(exercise: exercise(videoUrl: _videoUrl)),
            title: const Text('Panca piana'),
            subtitle: const Text('4 x 10 @ 60kg'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('non sfora nemmeno con tre righe di sottotitolo', (
      tester,
    ) async {
      // La forma della scheda: serie, recupero e nota.
      await tester.pumpWidget(
        host(
          ListTile(
            leading: ExerciseThumbnail(exercise: exercise()),
            title: const Text('Panca piana'),
            subtitle: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('4 x 10 @ 60kg'),
                Text('Rest: 90s'),
                Text('Note: prima serie di riscaldamento'),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('risoluzione per identificativo', () {
    testWidgets('un esercizio nell indice porta il suo materiale', (
      tester,
    ) async {
      // La scheda conosce solo l'identificativo: se la risoluzione non
      // funzionasse, un esercizio con video non mostrerebbe l'indicatore.
      await tester.pumpWidget(
        host(
          const ExerciseThumbnailById(
            exerciseId: 'e1',
            exerciseName: 'Panca piana',
          ),
          index: {'e1': exercise(videoUrl: _videoUrl)},
        ),
      );

      expect(videoBadge, findsOneWidget);
    });

    testWidgets('un identificativo che l indice non conosce da il segnaposto', (
      tester,
    ) async {
      // Il caso di una scheda aperta prima che Firestore risponda, e quello di
      // un esercizio cancellato.
      await tester.pumpWidget(
        host(
          const ExerciseThumbnailById(
            exerciseId: 'sconosciuto',
            exerciseName: 'Trazioni alla sbarra',
          ),
          index: const {},
        ),
      );

      expect(find.byType(ExercisePlaceholder), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      // Nessun indicatore: di quell'esercizio non sappiamo se ha un video.
      expect(videoBadge, findsNothing);
    });

    testWidgets('il segnaposto del nome e stabile fra due costruzioni', (
      tester,
    ) async {
      Future<String> regionName() async {
        await tester.pumpWidget(
          host(
            const ExerciseThumbnailById(
              exerciseId: 'x',
              exerciseName: 'Hip thrust',
            ),
            index: const {},
          ),
        );
        return tester
            .widget<ExercisePlaceholder>(find.byType(ExercisePlaceholder))
            .region
            .name;
      }

      final first = await regionName();
      await tester.pumpWidget(host(const SizedBox(), index: const {}));
      final second = await regionName();

      // Se cambiasse, la stessa scheda mostrerebbe due colori diversi a due
      // aperture: il segnaposto smetterebbe di essere un riconoscimento.
      expect(second, first);
    });

    testWidgets('la misura non dipende dalla risoluzione', (tester) async {
      await tester.pumpWidget(
        host(
          const ExerciseThumbnailById(
            exerciseId: 'sconosciuto',
            exerciseName: 'Rematore',
          ),
          index: const {},
        ),
      );

      const tokens = ExpressiveTokens();
      expect(
        tester.getSize(find.byType(ExerciseThumbnailById)),
        Size.square(tokens.sizing.thumbnailMd),
      );
    });
  });
}
