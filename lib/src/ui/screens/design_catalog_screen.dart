import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/expressive_tokens.dart';
import '../../core/theme/muscle_group_visuals.dart';
import '../../models/exercise.dart';
import '../widgets/exercise_image.dart';
import '../widgets/exercise_thumbnail.dart';
import '../widgets/expressive_card.dart';

/// Catalogo dei token del design system, visibile solo nelle build di debug.
///
/// Serve a due cose: vedere i token invece di immaginarli quando si sceglie
/// quale usare, e accorgersi subito se una modifica al design system rompe
/// qualcosa. Man mano che EP-005 aggiunge forme, componenti e movimento,
/// questa schermata cresce con loro.
///
/// L'accesso e protetto da [isAvailable]: nelle build di release la voce non
/// compare nel menu e la schermata non e raggiungibile.
class DesignCatalogScreen extends StatelessWidget {
  const DesignCatalogScreen({super.key});

  /// Vero in debug **e in profile**, falso in release.
  ///
  /// Era `kDebugMode` fino a US-043. Il criterio sulle prestazioni delle liste
  /// chiede una misura in profile mode su cento esercizi, e in Firestore ce ne
  /// sono otto: la lista di prova sta qui, e in profile mode questa schermata
  /// deve esistere, altrimenti il criterio non e misurabile. Le build di
  /// release restano senza catalogo, che era il punto di US-033.
  static bool get isAvailable => !kReleaseMode;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Design system')),
      body: ListView(
        padding: EdgeInsets.all(t.spacing.xl),
        children: [
          _Section(title: 'Colore', children: [_ColorRoles(scheme: scheme)]),
          _Section(title: 'Spaziature', children: [_SpacingScale(tokens: t)]),
          _Section(title: 'Forme', children: [_ShapeScale(tokens: t)]),
          _Section(
            title: 'Elevazioni',
            children: [_ElevationScale(tokens: t, scheme: scheme)],
          ),
          _Section(title: 'Movimento', children: [_MotionScale(tokens: t)]),
          _Section(title: 'Card', children: const [_Cards()]),
          _Section(
            title: 'Immagini degli esercizi',
            children: const [
              _ExerciseImageChain(),
              _RegionPlaceholders(),
              _StressListLink(),
            ],
          ),
          SizedBox(height: t.spacing.bottomInset),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: t.spacing.xl, bottom: t.spacing.md),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ColorRoles extends StatelessWidget {
  const _ColorRoles({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final roles = <String, Color>{
      'primary': scheme.primary,
      'onPrimary': scheme.onPrimary,
      'secondary': scheme.secondary,
      'surface': scheme.surface,
      'onSurface': scheme.onSurface,
      'error': scheme.error,
    };

    return Wrap(
      spacing: t.spacing.sm,
      runSpacing: t.spacing.sm,
      children: roles.entries.map((e) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 48,
              decoration: BoxDecoration(
                color: e.value,
                borderRadius: t.shape.cornerSm,
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.15),
                ),
              ),
            ),
            SizedBox(height: t.spacing.xs),
            SizedBox(
              width: 72,
              child: Text(
                e.key,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _SpacingScale extends StatelessWidget {
  const _SpacingScale({required this.tokens});

  final ExpressiveTokens tokens;

  @override
  Widget build(BuildContext context) {
    final s = tokens.spacing;
    final steps = <String, double>{
      'xs': s.xs,
      'sm': s.sm,
      'md': s.md,
      'lg': s.lg,
      'xl': s.xl,
      'xxl': s.xxl,
    };

    return Column(
      children: steps.entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: s.sm),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(e.key, style: Theme.of(context).textTheme.bodySmall),
              ),
              Container(
                width: e.value,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: tokens.shape.cornerXs,
                ),
              ),
              SizedBox(width: s.sm),
              Text(
                '${e.value.toStringAsFixed(0)} dp',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ShapeScale extends StatelessWidget {
  const _ShapeScale({required this.tokens});

  final ExpressiveTokens tokens;

  @override
  Widget build(BuildContext context) {
    final sh = tokens.shape;
    final shapes = <String, BorderRadius>{
      'xs': sh.cornerXs,
      'sm': sh.cornerSm,
      'md': sh.cornerMd,
      'lg': sh.cornerLg,
      'xl': sh.cornerXl,
      'full': sh.cornerFull,
    };

    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.sm,
      children: shapes.entries.map((e) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: e.value,
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(e.key, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}

class _ElevationScale extends StatelessWidget {
  const _ElevationScale({required this.tokens, required this.scheme});

  final ExpressiveTokens tokens;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final el = tokens.elevation;
    final levels = <String, List<BoxShadow>>{
      'level1': el.level1(scheme.shadow),
      'level2': el.level2(scheme.shadow),
      'level3': el.level3(scheme.shadow),
    };

    return Wrap(
      spacing: tokens.spacing.xl,
      runSpacing: tokens.spacing.xl,
      children: levels.entries.map((e) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: tokens.shape.cornerLg,
                boxShadow: e.value,
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
            Text(e.key, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}

/// Mostra le durate facendole vedere: ogni barra percorre la propria
/// larghezza nel tempo del token, cosi la differenza si osserva invece di
/// doverla immaginare leggendo un numero.
class _MotionScale extends StatefulWidget {
  const _MotionScale({required this.tokens});

  final ExpressiveTokens tokens;

  @override
  State<_MotionScale> createState() => _MotionScaleState();
}

class _MotionScaleState extends State<_MotionScale> {
  bool _moved = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final m = t.motion;
    final durations = <String, Duration>{
      'instant': m.instant,
      'quick': m.quick,
      'standard': m.standard,
      'emphasized': m.emphasized,
      'expressive': m.expressive,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...durations.entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(bottom: t.spacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    e.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: _moved
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: e.value,
                      curve: m.standardCurve,
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: t.shape.cornerFull,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${e.value.inMilliseconds} ms',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: t.spacing.sm),
        FilledButton.tonal(
          onPressed: () => setState(() => _moved = !_moved),
          child: const Text('Anima'),
        ),
      ],
    );
  }
}

/// I quattro anelli della catena di ripiego, uno accanto all'altro.
///
/// Serve a vedere cosa fa `ExerciseImage` **prima** che finisca nelle liste
/// vere: quale anello vince quando ce ne sono due, e cosa si vede quando quello
/// che dovrebbe vincere non si carica. Gli indirizzi dei video sono
/// identificativi reali della libreria curata, quindi i primi quattro casi si
/// riempiono davvero se il telefono ha rete.
class _ExerciseImageChain extends StatelessWidget {
  const _ExerciseImageChain();

  static Exercise _exercise({
    String? userImageUrl,
    String? imageUrl,
    String? videoUrl,
  }) {
    return Exercise(
      id: 'catalogo',
      name: 'Panca piana',
      description: '',
      type: ExerciseType.strength,
      userImageUrl: userImageUrl,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      musclesTargeted: const ['petto'],
    );
  }

  // Miniature di tre video diversi: si distinguono a occhio, ed e questo che
  // rende visibile quale anello ha vinto.
  static const _videoA = 'https://www.youtube.com/watch?v=0VUnN89pUyw';
  static const _thumbB = 'https://img.youtube.com/vi/nclAIgM4NJE/hqdefault.jpg';
  static const _thumbC = 'https://img.youtube.com/vi/9MY4ZJNXHYM/hqdefault.jpg';

  /// Un dominio che non esiste: fallisce sempre, anche con rete.
  static const _broken = 'https://gymflow.invalid/manca.jpg';

  @override
  Widget build(BuildContext context) {
    final cases = <String, Exercise>{
      'video': _exercise(videoUrl: _videoA),
      'curata\nsopra il video': _exercise(imageUrl: _thumbB, videoUrl: _videoA),
      'utente\nsopra tutto': _exercise(
        userImageUrl: _thumbC,
        imageUrl: _thumbB,
        videoUrl: _videoA,
      ),
      'curata rotta:\nripiega sul video': _exercise(
        imageUrl: _broken,
        videoUrl: _videoA,
      ),
      'niente:\nsegnaposto': _exercise(),
    };

    return _CatalogTiles(
      tiles: cases.entries
          .map(
            (e) => (
              label: e.key,
              child: ExerciseImage(exercise: e.value, decodeWidth: 88),
            ),
          )
          .toList(),
    );
  }
}

/// Il segnaposto nelle sette regioni del corpo.
class _RegionPlaceholders extends StatelessWidget {
  const _RegionPlaceholders();

  @override
  Widget build(BuildContext context) {
    return _CatalogTiles(
      tiles: BodyRegion.values
          .map(
            (region) => (
              label: region.name,
              child: ExercisePlaceholder(region: region),
            ),
          )
          .toList(),
    );
  }
}

/// La card del design system, nelle sue tre forme.
///
/// Sta qui perche e il posto dove si guarda un componente senza dover navigare
/// fino alla schermata che lo usa — e perche una card senza titolo e una con
/// titolo sono due cose che si giudicano una accanto all'altra.
class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExpressiveCard(child: Text('Solo contenuto, nessun titolo')),
        SizedBox(height: t.spacing.md),
        const ExpressiveCard(
          title: 'Con titolo',
          child: Text('Il titolo prende uno stile del tema, non una misura'),
        ),
        SizedBox(height: t.spacing.md),
        ExpressiveCard(
          title: 'Toccabile',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tocco ricevuto')),
          ),
          child: const Text("L'onda del tocco segue gli angoli della card"),
        ),
      ],
    );
  }
}

/// Porta alla lista di prova da cento esercizi.
class _StressListLink extends StatelessWidget {
  const _StressListLink();

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExerciseListStressScreen()),
      ),
      icon: const Icon(Icons.list),
      label: const Text('100 esercizi (prova di scorrimento)'),
    );
  }
}

/// Cento esercizi finti, per misurare lo scorrimento di una lista lunga.
///
/// Serve perche il criterio di US-043 parla di cento esercizi e in Firestore ce
/// ne sono otto: senza questa lista la misura non esiste, e un criterio non
/// misurabile va dichiarato invece che spuntato.
///
/// Il materiale e **misto di proposito**: una lista di soli segnaposti non
/// misurerebbe nulla, perche il costo sta nel decodificare le immagini remote.
/// Qui una parte ha un video vero (miniatura remota e indicatore), una parte ha
/// un indirizzo rotto (quindi percorre la catena di ripiego), la maggioranza non
/// ha nulla — che e la proporzione reale della libreria curata, 15 su 43.
class ExerciseListStressScreen extends StatelessWidget {
  const ExerciseListStressScreen({super.key});

  /// Identificativi verificati, dalla libreria curata.
  static const _videoIds = [
    '0VUnN89pUyw',
    'nclAIgM4NJE',
    '9MY4ZJNXHYM',
    'd7B7bXZr26c',
  ];

  static const _groups = [
    'petto',
    'dorso',
    'spalle',
    'bicipiti',
    'tricipiti',
    'quadricipiti',
    'femorali',
    'glutei',
    'addome',
    'polpacci',
    'trapezio',
    'cardio',
  ];

  static List<Exercise> _build() {
    return List.generate(100, (i) {
      final hasVideo = i % 7 == 0;
      final hasBrokenImage = !hasVideo && i % 5 == 0;

      return Exercise(
        id: 'stress_$i',
        name: 'Esercizio di prova numero ${i + 1}',
        description: '',
        type: ExerciseType.strength,
        videoUrl: hasVideo
            ? 'https://www.youtube.com/watch?v=${_videoIds[i % _videoIds.length]}'
            : null,
        imageUrl: hasBrokenImage ? 'https://gymflow.invalid/$i.jpg' : null,
        musclesTargeted: [_groups[i % _groups.length]],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final exercises = _build();
    // Celle di altezza dichiarata: con l'estensione nota, ListView non deve
    // misurarle per sapere dove sono.
    final extent = t.sizing.thumbnailMd + t.spacing.md;

    return Scaffold(
      appBar: AppBar(title: const Text('100 esercizi')),
      body: ListView.builder(
        itemCount: exercises.length,
        itemExtent: extent,
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return Row(
            children: [
              ExerciseThumbnail(exercise: exercise),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Riquadri quadrati con etichetta, la forma in cui il catalogo mostra le
/// immagini.
class _CatalogTiles extends StatelessWidget {
  const _CatalogTiles({required this.tiles});

  final List<({String label, Widget child})> tiles;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;

    return Padding(
      padding: EdgeInsets.only(bottom: t.spacing.md),
      child: Wrap(
        spacing: t.spacing.sm,
        runSpacing: t.spacing.sm,
        children: tiles.map((tile) {
          return SizedBox(
            width: 88,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: t.shape.cornerMd,
                  child: SizedBox.square(dimension: 88, child: tile.child),
                ),
                SizedBox(height: t.spacing.xs),
                Text(
                  tile.label,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
