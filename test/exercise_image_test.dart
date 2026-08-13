import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/muscle_group_visuals.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/ui/widgets/exercise_image.dart';

/// Un anello che non si carica: la rete assente, il 404, il file corrotto.
///
/// Fallisce subito e sempre. L'uguaglianza e sull'indirizzo perche altrimenti
/// ogni ricostruzione produrrebbe una chiave diversa e la cache di Flutter
/// rifarebbe la richiesta, falsando il conteggio.
class _FailingImage extends ImageProvider<_FailingImage> {
  const _FailingImage(this.url);

  final String url;

  @override
  Future<_FailingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FailingImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingImage key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(Exception('rete assente: $url'), StackTrace.empty),
    );
  }

  @override
  bool operator ==(Object other) => other is _FailingImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// Un anello che sta ancora caricando: non fallisce e non arriva mai.
///
/// Serve a due cose: dimostrare che senza un errore la catena **non** avanza, e
/// guardare cosa vede l'utente mentre la rete e lenta.
class _PendingImage extends ImageProvider<_PendingImage> {
  const _PendingImage(this.url);

  final String url;

  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_PendingImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
  }

  @override
  bool operator ==(Object other) => other is _PendingImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

Exercise exercise({
  String? userImageUrl,
  String? imageUrl,
  String? videoUrl,
  List<String> muscles = const ['petto'],
  String name = 'Panca piana',
}) {
  return Exercise(
    id: 'e1',
    name: name,
    description: '',
    type: ExerciseType.strength,
    userImageUrl: userImageUrl,
    imageUrl: imageUrl,
    videoUrl: videoUrl,
    musclesTargeted: muscles,
  );
}

void main() {
  /// Registra ogni indirizzo chiesto, e decide quali falliscono.
  ///
  /// E l'innesto che rende verificabile la catena senza rete e senza plugin
  /// nativi: con il provider vero, un test misurerebbe la libreria di cache
  /// invece del nostro ripiego.
  ({List<String> requested, ExerciseImageProviderFactory factory}) recorder({
    Set<String> failing = const {},
  }) {
    final requested = <String>[];
    return (
      requested: requested,
      factory: (url) {
        requested.add(url);
        return failing.contains(url)
            ? _FailingImage(url)
            : _PendingImage(url);
      },
    );
  }

  Widget host(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox.square(dimension: 56, child: child)),
      ),
    );
  }

  group('senza materiale', () {
    testWidgets('mostra il segnaposto e non chiede nulla alla rete', (
      tester,
    ) async {
      final rec = recorder();

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(),
            imageProviderFactory: rec.factory,
          ),
        ),
      );

      expect(find.byType(ExercisePlaceholder), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(rec.requested, isEmpty);
    });

    testWidgets('il segnaposto porta la sagoma del gruppo muscolare', (
      tester,
    ) async {
      await tester.pumpWidget(host(ExerciseImage(exercise: exercise())));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, BodyRegion.chest.glyph);
    });

    testWidgets('un esercizio senza gruppi mostra comunque una sagoma', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(ExerciseImage(exercise: exercise(muscles: const []))),
      );

      // Il criterio dice che il segnaposto non e mai un rettangolo vuoto.
      expect(find.byType(Icon), findsOneWidget);
    });
  });

  group('cammino della catena', () {
    testWidgets('chiede il primo anello e si ferma la, se non fallisce', (
      tester,
    ) async {
      final rec = recorder();

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(
              userImageUrl: 'https://storage/mia.jpg',
              imageUrl: 'https://storage/curata.jpg',
            ),
            imageProviderFactory: rec.factory,
          ),
        ),
      );
      await tester.pump();

      expect(rec.requested, ['https://storage/mia.jpg']);
    });

    testWidgets('un anello che non si carica ripiega sul successivo', (
      tester,
    ) async {
      final rec = recorder(failing: {'https://storage/mia.jpg'});

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(
              userImageUrl: 'https://storage/mia.jpg',
              imageUrl: 'https://storage/curata.jpg',
            ),
            imageProviderFactory: rec.factory,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(rec.requested, [
        'https://storage/mia.jpg',
        'https://storage/curata.jpg',
      ]);
    });

    testWidgets('la catena si percorre fino in fondo, un anello per volta', (
      tester,
    ) async {
      const mia = 'https://storage/mia.jpg';
      const curata = 'https://storage/curata.jpg';
      final rec = recorder(failing: {mia, curata});

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(
              userImageUrl: mia,
              imageUrl: curata,
              videoUrl: 'https://youtu.be/dQw4w9WgXcQ',
            ),
            imageProviderFactory: rec.factory,
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(rec.requested, [
        mia,
        curata,
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      ]);
    });

    testWidgets('quando tutti gli anelli falliscono resta il segnaposto', (
      tester,
    ) async {
      const mia = 'https://storage/mia.jpg';
      const curata = 'https://storage/curata.jpg';
      final rec = recorder(failing: {mia, curata});

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(userImageUrl: mia, imageUrl: curata),
            imageProviderFactory: rec.factory,
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(find.byType(Image), findsNothing);
      expect(find.byType(ExercisePlaceholder), findsOneWidget);
      // Non riprova all'infinito: due anelli, due richieste.
      expect(rec.requested, [mia, curata]);
    });

    testWidgets('lo stesso fallimento non consuma due anelli', (tester) async {
      const mia = 'https://storage/mia.jpg';
      final rec = recorder(failing: {mia});

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(
              userImageUrl: mia,
              imageUrl: 'https://storage/curata.jpg',
              videoUrl: 'https://youtu.be/dQw4w9WgXcQ',
            ),
            imageProviderFactory: rec.factory,
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      // Il secondo anello e in caricamento: il terzo non deve essere stato
      // chiesto per colpa dell'errore del primo.
      expect(rec.requested, [mia, 'https://storage/curata.jpg']);
    });
  });

  group('mentre la rete e lenta', () {
    testWidgets('il segnaposto resta sotto, e non c e un buco', (tester) async {
      final rec = recorder();

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(imageUrl: 'https://storage/curata.jpg'),
            imageProviderFactory: rec.factory,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(ExercisePlaceholder), findsOneWidget);
    });
  });

  group('riciclo della cella in una lista', () {
    testWidgets('un esercizio nuovo riparte dal primo anello', (tester) async {
      const rotta = 'https://storage/rotta.jpg';
      final rec = recorder(failing: {rotta});

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(imageUrl: rotta),
            imageProviderFactory: rec.factory,
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
      expect(find.byType(ExercisePlaceholder), findsOneWidget);

      // Stessa posizione nell'albero, esercizio diverso: e cio che fa una
      // ListView quando ricicla una cella. Senza azzerare l'anello corrente,
      // il secondo esercizio erediterebbe il fallimento del primo.
      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(imageUrl: 'https://storage/buona.jpg'),
            imageProviderFactory: rec.factory,
          ),
        ),
      );
      await tester.pump();

      expect(rec.requested, [rotta, 'https://storage/buona.jpg']);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('lo stesso esercizio non fa ripartire la catena', (
      tester,
    ) async {
      const rotta = 'https://storage/rotta.jpg';
      final rec = recorder(failing: {rotta});

      for (var round = 0; round < 2; round++) {
        await tester.pumpWidget(
          host(
            ExerciseImage(
              exercise: exercise(imageUrl: rotta),
              imageProviderFactory: rec.factory,
            ),
          ),
        );
        for (var i = 0; i < 3; i++) {
          await tester.pump();
        }
      }

      // Un rebuild qualunque non deve rimettere in coda un anello gia fallito.
      expect(rec.requested, [rotta]);
    });
  });

  group('cache e decodifica', () {
    test('il provider predefinito e quello con la cache su disco', () {
      final provider = ExerciseImage.defaultProviderFactory(
        'https://storage/curata.jpg',
      );
      expect(provider, isA<CachedNetworkImageProvider>());
    });

    test('un percorso di asset usa AssetImage, non la rete', () {
      final provider = ExerciseImage.defaultProviderFactory(
        'assets/exercises/ex_002.jpg',
      );
      expect(provider, isA<AssetImage>());
    });

    testWidgets('senza larghezza dichiarata il provider non viene incartato', (
      tester,
    ) async {
      final rec = recorder();

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(imageUrl: 'https://storage/curata.jpg'),
            imageProviderFactory: rec.factory,
          ),
        ),
      );

      expect(tester.widget<Image>(find.byType(Image)).image, isA<_PendingImage>());
    });

    testWidgets('con la larghezza dichiarata si decodifica in scala', (
      tester,
    ) async {
      final rec = recorder();

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(imageUrl: 'https://storage/curata.jpg'),
            decodeWidth: 56,
            imageProviderFactory: rec.factory,
          ),
        ),
      );

      // Una miniatura YouTube e larga 480 px: decodificarla intera per
      // disegnarla a 56 significa tenere in memoria trenta volte i pixel utili.
      final image = tester.widget<Image>(find.byType(Image)).image;
      expect(image, isA<ResizeImage>());
      expect((image as ResizeImage).width, isNotNull);
      expect(image.imageProvider, isA<_PendingImage>());
    });
  });

  group('immagine grande', () {
    testWidgets('segue la catena della testata, non quella delle liste', (
      tester,
    ) async {
      final rec = recorder();

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(videoUrl: 'https://youtu.be/dQw4w9WgXcQ'),
            size: ExerciseImageSize.hero,
            imageProviderFactory: rec.factory,
          ),
        ),
      );

      expect(rec.requested.single, endsWith('maxresdefault.jpg'));
    });

    testWidgets('la risoluzione massima che non esiste ripiega su quella sicura', (
      tester,
    ) async {
      const maxRes = 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg';
      final rec = recorder(failing: {maxRes});

      await tester.pumpWidget(
        host(
          ExerciseImage(
            exercise: exercise(videoUrl: 'https://youtu.be/dQw4w9WgXcQ'),
            size: ExerciseImageSize.hero,
            imageProviderFactory: rec.factory,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(rec.requested, [
        maxRes,
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      ]);
    });
  });
}
