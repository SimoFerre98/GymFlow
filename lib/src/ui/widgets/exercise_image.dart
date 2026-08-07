import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../core/theme/expressive_tokens.dart';
import '../../core/theme/muscle_group_visuals.dart';
import '../../models/exercise.dart';

/// Costruisce il provider di un indirizzo. Iniettabile per i test.
typedef ExerciseImageProviderFactory = ImageProvider Function(String url);

/// Quale catena seguire: la miniatura delle liste o l'immagine grande.
enum ExerciseImageSize {
  /// Miniature: una sola qualita YouTube, la piu leggera fra quelle nitide.
  thumbnail,

  /// Immagine piena: prova la risoluzione massima e ripiega su quella che
  /// esiste sempre.
  hero,
}

/// L'immagine di un esercizio, qualunque materiale ci sia.
///
/// Cammina la catena di ripiego — foto dell'utente, immagine curata, miniatura
/// del video, segnaposto — e **mostra sempre qualcosa**. Un anello che non si
/// carica non lascia uno spazio vuoto: si passa al successivo, e quando gli
/// anelli finiscono resta il segnaposto, che non e mai un rettangolo vuoto.
///
/// Riempie il riquadro che gli viene dato: la misura e la forma le decide chi
/// lo usa, perche una miniatura in lista e un'immagine di testata hanno la
/// stessa logica e due dimensioni diverse.
///
/// ```dart
/// SizedBox.square(dimension: 56, child: ExerciseImage(exercise: e))
/// ```
class ExerciseImage extends StatefulWidget {
  const ExerciseImage({
    super.key,
    required this.exercise,
    this.size = ExerciseImageSize.thumbnail,
    this.decodeWidth,
    this.fit = BoxFit.cover,
    this.imageProviderFactory,
  });

  final Exercise exercise;

  /// Quale delle due catene seguire.
  final ExerciseImageSize size;

  /// Larghezza logica a cui decodificare l'immagine.
  ///
  /// Una miniatura di YouTube e larga 480 pixel; decodificarla intera per
  /// disegnarla a 56 significa tenere in memoria trenta volte i pixel che
  /// servono. Passare la larghezza reale e cio che rende scorrevole una lista
  /// lunga.
  final double? decodeWidth;

  final BoxFit fit;

  /// Come si ottiene un `ImageProvider` da un indirizzo.
  ///
  /// Di norma resta nullo e vale [defaultProviderFactory], che usa la cache su
  /// disco. Esiste per i test: senza questo innesto, verificare la catena
  /// richiederebbe rete e canali di piattaforma, e finirebbe per misurare la
  /// libreria di cache invece del nostro ripiego.
  final ExerciseImageProviderFactory? imageProviderFactory;

  /// Provider predefinito: cache su disco, condivisa da tutta l'app.
  static ImageProvider defaultProviderFactory(String url) =>
      CachedNetworkImageProvider(url);

  @override
  State<ExerciseImage> createState() => _ExerciseImageState();
}

class _ExerciseImageState extends State<ExerciseImage> {
  late List<String> _candidates = _candidatesOf(widget);

  /// Anello corrente. Cresce e non torna indietro: quando supera la lista, il
  /// segnaposto e definitivo e non si riprova all'infinito.
  int _attempt = 0;

  /// Vero fra la scoperta di un errore e il ricostruire che ne consegue, per
  /// non contare due volte lo stesso fallimento.
  bool _advancing = false;

  static List<String> _candidatesOf(ExerciseImage widget) {
    return switch (widget.size) {
      ExerciseImageSize.thumbnail => widget.exercise.thumbnailCandidates,
      ExerciseImageSize.hero => widget.exercise.heroCandidates,
    };
  }

  @override
  void didUpdateWidget(covariant ExerciseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _candidatesOf(widget);
    // Nelle liste una cella viene riciclata per un altro esercizio: senza
    // azzerare l'anello, il secondo esercizio erediterebbe i fallimenti del
    // primo e partirebbe dal segnaposto.
    if (!listEquals(next, _candidates)) {
      _candidates = next;
      _attempt = 0;
      _advancing = false;
    }
  }

  /// Passa all'anello successivo, dopo il frame in corso.
  ///
  /// L'errore arriva durante la costruzione dell'albero, quando `setState` non
  /// e ammesso: il cambio di stato va rimandato al frame successivo.
  void _advanceFrom(String failed) {
    if (_advancing) return;
    _advancing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _advancing = false;
        return;
      }
      _advancing = false;
      // Se nel frattempo la catena e cambiata, questo fallimento non riguarda
      // piu l'anello corrente e non deve farlo avanzare.
      if (_attempt < _candidates.length && _candidates[_attempt] == failed) {
        setState(() => _attempt++);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = ExercisePlaceholder.of(widget.exercise);

    if (_attempt >= _candidates.length) return placeholder;

    final url = _candidates[_attempt];
    final factory =
        widget.imageProviderFactory ?? ExerciseImage.defaultProviderFactory;
    final decodeWidth = widget.decodeWidth;
    // Una larghezza nulla o negativa non e una richiesta di decodifica: passarla
    // a ResizeImage farebbe scattare un assert in debug. Vale come "intera".
    final pixels = decodeWidth == null || decodeWidth <= 0
        ? null
        : (decodeWidth * MediaQuery.devicePixelRatioOf(context)).round();
    final provider = ResizeImage.resizeIfNeeded(pixels, null, factory(url));

    return Image(
      // Un elemento nuovo per ogni anello. Senza la chiave, `Image` riusa lo
      // stesso stato e con esso l'eccezione dell'anello precedente: il suo
      // `errorBuilder` scatta di nuovo appena l'anello cambia, e un solo
      // fallimento ne consumerebbe due.
      key: ValueKey(url),
      image: provider,
      fit: widget.fit,
      // L'immagine sta sempre accanto al nome dell'esercizio: annunciarla
      // farebbe leggere due volte la stessa informazione.
      excludeFromSemantics: true,
      // Alla ricostruzione tiene i pixel precedenti invece di lampeggiare.
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        _advanceFrom(url);
        return placeholder;
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        // Il segnaposto resta sotto: l'immagine si scopre sopra di esso, cosi
        // una rete lenta non mostra mai un buco e il riquadro non cambia
        // dimensione quando i pixel arrivano.
        return Stack(
          fit: StackFit.passthrough,
          children: [
            placeholder,
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: context.expressive.motion.quick,
              curve: context.expressive.motion.enter,
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// L'ultimo anello della catena: cosa si vede quando non c'e nessuna immagine.
///
/// Per due terzi della libreria curata questo **e** l'immagine dell'esercizio:
/// 15 esercizi su 43 hanno un video, gli altri 28 arrivano qui. Per questo non
/// e un rettangolo grigio ma porta due informazioni — il colore dice la regione
/// del corpo, la sagoma dice il gruppo muscolare.
class ExercisePlaceholder extends StatelessWidget {
  const ExercisePlaceholder({super.key, required this.region});

  /// Segnaposto di un esercizio, con la regione dedotta dai suoi gruppi.
  factory ExercisePlaceholder.of(Exercise exercise, {Key? key}) {
    return ExercisePlaceholder(
      key: key,
      region: MuscleGroupVisuals.resolve(
        muscleGroups: exercise.musclesTargeted,
        fallbackSeed: exercise.name,
      ),
    );
  }

  final BodyRegion region;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // In un riquadro senza limiti il segnaposto si dimensiona sulla sagoma
        // invece di provare a essere infinito.
        final shortestSide = math.min(
          constraints.hasBoundedWidth ? constraints.maxWidth : 48.0,
          constraints.hasBoundedHeight ? constraints.maxHeight : 48.0,
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.outline, scheme.surfaceContainer],
            ),
          ),
          child: Center(
            child: Icon(
              region.glyph,
              size: (shortestSide * 0.42).clamp(14.0, 72.0),
              color: scheme.onSurface.withValues(alpha: 0.92),
            ),
          ),
        );
      },
    );
  }
}
