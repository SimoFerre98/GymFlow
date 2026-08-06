import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/exercise_media.dart';

Exercise ex({
  String? videoUrl,
  String? videoSearchQuery,
  String? imageUrl,
  String? userImageUrl,
}) {
  return Exercise(
    id: 'e1',
    name: 'Panca piana',
    description: '',
    type: ExerciseType.strength,
    videoUrl: videoUrl,
    videoSearchQuery: videoSearchQuery,
    imageUrl: imageUrl,
    userImageUrl: userImageUrl,
    musclesTargeted: const ['petto'],
  );
}

void main() {
  const id = 'dQw4w9WgXcQ'; // 11 caratteri, forma valida

  group('riconoscimento del video', () {
    test('riconosce la forma watch', () {
      expect(YouTubeVideo.idOf('https://www.youtube.com/watch?v=$id'), id);
    });

    test('riconosce la forma breve', () {
      expect(YouTubeVideo.idOf('https://youtu.be/$id'), id);
    });

    test('riconosce gli shorts', () {
      expect(YouTubeVideo.idOf('https://www.youtube.com/shorts/$id'), id);
    });

    test('riconosce la forma da incorporare', () {
      expect(YouTubeVideo.idOf('https://www.youtube.com/embed/$id'), id);
    });

    test('riconosce le dirette', () {
      expect(YouTubeVideo.idOf('https://www.youtube.com/live/$id'), id);
    });

    test('riconosce il dominio senza tracciamento', () {
      expect(YouTubeVideo.idOf('https://www.youtube-nocookie.com/embed/$id'), id);
    });

    test('funziona senza il prefisso www', () {
      expect(YouTubeVideo.idOf('https://youtube.com/watch?v=$id'), id);
    });

    test('ignora i parametri in coda', () {
      expect(YouTubeVideo.idOf('https://youtu.be/$id?t=42'), id);
      expect(
        YouTubeVideo.idOf('https://www.youtube.com/watch?v=$id&list=PL123'),
        id,
      );
    });

    test('tollera gli spazi ai lati', () {
      expect(YouTubeVideo.idOf('  https://youtu.be/$id  '), id);
    });
  });

  group('cosa NON e un video', () {
    // Il caso concreto del materiale ricevuto: 43 URL su 43 sono ricerche.
    test('un URL di ricerca non contiene un video', () {
      const url =
          'https://www.youtube.com/results?search_query=panca+piana+bilanciere';
      expect(YouTubeVideo.idOf(url), isNull);
      expect(YouTubeVideo.isVideoUrl(url), isFalse);
    });

    test('un altro dominio non e YouTube', () {
      expect(YouTubeVideo.idOf('https://vimeo.com/123456'), isNull);
      expect(YouTubeVideo.idOf('https://notyoutube.com/watch?v=$id'), isNull);
    });

    test('un identificativo di lunghezza sbagliata viene rifiutato', () {
      // 'troppocorto' sono esattamente 11 caratteri e sarebbe valido: qui
      // servono lunghezze davvero diverse da 11.
      expect(YouTubeVideo.idOf('https://youtu.be/corto'), isNull);
      expect(
        YouTubeVideo.idOf('https://youtu.be/${id}moltopiulungo'),
        isNull,
      );
    });

    test('un dominio che finisce per youtube.com non e YouTube', () {
      // endsWith da solo accetterebbe notyoutube.com: il confronto deve essere
      // sul dominio esatto o su un suo sottodominio.
      expect(YouTubeVideo.idOf('https://notyoutube.com/watch?v=$id'), isNull);
      expect(YouTubeVideo.idOf('https://myyoutube.com/watch?v=$id'), isNull);
      expect(YouTubeVideo.idOf('https://m.youtube.com/watch?v=$id'), id);
    });

    test('nullo e stringa vuota non fanno cadere nulla', () {
      expect(YouTubeVideo.idOf(null), isNull);
      expect(YouTubeVideo.idOf(''), isNull);
      expect(YouTubeVideo.idOf('   '), isNull);
    });

    test('una stringa che non e un URL non fa cadere nulla', () {
      expect(YouTubeVideo.idOf('non un url'), isNull);
      expect(YouTubeVideo.idOf('::::'), isNull);
    });
  });

  group('query di ricerca', () {
    test('estrae la query da un URL di ricerca', () {
      expect(
        YouTubeVideo.searchQueryOf(
          'https://www.youtube.com/results?search_query=panca+piana',
        ),
        'panca piana',
      );
    });

    test('un URL di video non contiene una query', () {
      expect(
        YouTubeVideo.searchQueryOf('https://www.youtube.com/watch?v=$id'),
        isNull,
      );
    });

    test('costruisce un URL di ricerca con la codifica corretta', () {
      final url = YouTubeVideo.searchUrl('croci ai cavi 30°');
      expect(url, startsWith('https://www.youtube.com/results?search_query='));
      expect(url, isNot(contains(' ')));
    });
  });

  group('miniatura', () {
    test('deriva dall identificativo del video', () {
      expect(
        YouTubeVideo.thumbnailUrl('https://youtu.be/$id'),
        'https://img.youtube.com/vi/$id/hqdefault.jpg',
      );
    });

    test('la qualita richiesta cambia il file', () {
      expect(
        YouTubeVideo.thumbnailUrl(
          'https://youtu.be/$id',
          quality: YouTubeThumbQuality.maxRes,
        ),
        endsWith('maxresdefault.jpg'),
      );
    });

    test('senza video non c e miniatura', () {
      expect(YouTubeVideo.thumbnailUrl(null), isNull);
      expect(
        YouTubeVideo.thumbnailUrl(
          'https://www.youtube.com/results?search_query=squat',
        ),
        isNull,
      );
    });
  });

  group('catena di ripiego dell immagine', () {
    test('la foto dell utente vince su tutto', () {
      final e = ex(
        userImageUrl: 'https://storage/mia.jpg',
        imageUrl: 'https://storage/curata.jpg',
        videoUrl: 'https://youtu.be/$id',
      );
      expect(e.thumbnailUrl, 'https://storage/mia.jpg');
    });

    test('senza foto dell utente vale quella curata', () {
      final e = ex(
        imageUrl: 'https://storage/curata.jpg',
        videoUrl: 'https://youtu.be/$id',
      );
      expect(e.thumbnailUrl, 'https://storage/curata.jpg');
    });

    test('senza immagini vale la miniatura del video', () {
      final e = ex(videoUrl: 'https://youtu.be/$id');
      expect(e.thumbnailUrl, contains('img.youtube.com'));
    });

    test('senza nulla restituisce nullo, e il segnaposto tocca al widget', () {
      expect(ex().thumbnailUrl, isNull);
    });

    test('una sola ricerca non produce una miniatura', () {
      // Il caso della libreria curata di partenza: senza video specifico non
      // c'e miniatura, e l'esercizio mostra il segnaposto.
      final e = ex(videoSearchQuery: 'panca piana bilanciere');
      expect(e.thumbnailUrl, isNull);
    });

    test('l immagine grande usa la risoluzione massima', () {
      final e = ex(videoUrl: 'https://youtu.be/$id');
      expect(e.heroImageUrl, endsWith('maxresdefault.jpg'));
    });
  });

  group('indirizzo dell esecuzione', () {
    test('con un video porta al video', () {
      final e = ex(videoUrl: 'https://youtu.be/$id');
      expect(e.executionUrl, 'https://www.youtube.com/watch?v=$id');
      expect(e.hasSpecificVideo, isTrue);
    });

    test('con una sola ricerca porta alla ricerca', () {
      final e = ex(videoSearchQuery: 'stacchi a gambe tese');
      expect(e.executionUrl, contains('search_query='));
      expect(e.hasSpecificVideo, isFalse);
    });

    test('il video ha la precedenza sulla ricerca', () {
      final e = ex(
        videoUrl: 'https://youtu.be/$id',
        videoSearchQuery: 'qualcosa',
      );
      expect(e.executionUrl, contains('watch?v='));
    });

    test('senza nulla non c e niente da aprire', () {
      expect(ex().executionUrl, isNull);
      expect(ex(videoSearchQuery: '   ').executionUrl, isNull);
    });
  });

  group('conversione da e verso Firestore', () {
    test('andata e ritorno conserva tutti i campi', () {
      final original = Exercise(
        id: 'ex_001',
        name: 'Spinte manubri panca piana',
        description: 'compound',
        type: ExerciseType.strength,
        videoUrl: 'https://youtu.be/$id',
        videoSearchQuery: 'spinte manubri',
        imageUrl: 'https://storage/img.jpg',
        userImageUrl: 'https://storage/mia.jpg',
        musclesTargeted: const ['petto', 'tricipiti'],
        isCustom: true,
        isCurated: true,
      );

      final back = Exercise.fromMap(original.toMap(), original.id);

      expect(back.name, original.name);
      expect(back.type, original.type);
      expect(back.videoUrl, original.videoUrl);
      expect(back.videoSearchQuery, original.videoSearchQuery);
      expect(back.imageUrl, original.imageUrl);
      expect(back.userImageUrl, original.userImageUrl);
      expect(back.musclesTargeted, original.musclesTargeted);
      expect(back.isCustom, original.isCustom);
      expect(back.isCurated, original.isCurated);
    });

    test('un documento senza i campi nuovi resta valido', () {
      // Nessuna migrazione: gli esercizi già in Firestore devono continuare a
      // funzionare senza toccarli.
      final e = Exercise.fromMap(const {
        'name': 'Squat',
        'type': 'strength',
        'musclesTargeted': ['quadricipiti'],
      }, 'vecchio');

      expect(e.name, 'Squat');
      expect(e.videoUrl, isNull);
      expect(e.videoSearchQuery, isNull);
      expect(e.imageUrl, isNull);
      expect(e.isCurated, isFalse);
      expect(e.thumbnailUrl, isNull);
    });

    test('una ricerca salvata nel vecchio campo video viene riconosciuta', () {
      // Caso reale: i documenti importati prima di questa storia potrebbero
      // avere una ricerca dentro videoUrl. Va letta come ricerca, non come
      // video, altrimenti si tenterebbe una miniatura inesistente.
      final e = Exercise.fromMap(const {
        'name': 'Hip thrust',
        'type': 'strength',
        'videoUrl':
            'https://www.youtube.com/results?search_query=hip+thrust',
        'musclesTargeted': ['glutei'],
      }, 'x');

      expect(e.videoUrl, isNull);
      expect(e.videoSearchQuery, 'hip thrust');
      expect(e.hasSpecificVideo, isFalse);
      expect(e.thumbnailUrl, isNull);
      expect(e.executionUrl, contains('search_query='));
    });

    test('un tipo sconosciuto ripiega su forza invece di far cadere tutto', () {
      final e = Exercise.fromMap(const {
        'name': 'X',
        'type': 'tipoinesistente',
        'musclesTargeted': <String>[],
      }, 'x');
      expect(e.type, ExerciseType.strength);
    });
  });

  group('copyWith', () {
    test('sostituisce solo il campo indicato', () {
      final e = ex(imageUrl: 'https://a.jpg');
      final c = e.copyWith(userImageUrl: 'https://b.jpg');
      expect(c.userImageUrl, 'https://b.jpg');
      expect(c.imageUrl, 'https://a.jpg');
      expect(c.name, e.name);
    });
  });
}
