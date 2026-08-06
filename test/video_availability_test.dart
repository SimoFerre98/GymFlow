import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/services/video_availability.dart';

const _video = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

void main() {
  group('cosa risponde YouTube', () {
    test('200 significa che il video si puo guardare', () async {
      final result = await VideoAvailabilityCheck.of(
        _video,
        probe: (_) async => 200,
      );
      expect(result, VideoAvailability.available);
    });

    test('404 significa rimosso', () async {
      final result = await VideoAvailabilityCheck.of(
        _video,
        probe: (_) async => 404,
      );
      expect(result, VideoAvailability.unavailable);
    });

    test('401 significa privato o incorporamento vietato', () async {
      // Per chi guarda e la stessa cosa di un video rimosso: qui non lo vedra.
      final result = await VideoAvailabilityCheck.of(
        _video,
        probe: (_) async => 401,
      );
      expect(result, VideoAvailability.unavailable);
    });
  });

  group('quando la rete non c e', () {
    test('un errore di socket diventa "senza rete", non "non disponibile"', () async {
      // E la distinzione che giustifica l'esistenza di questo servizio: i due
      // criteri di US-044 chiedono due messaggi diversi.
      final result = await VideoAvailabilityCheck.of(
        _video,
        probe: (_) async => throw const SocketException('nessuna rotta'),
      );
      expect(result, VideoAvailability.offline);
    });

    test('un timeout diventa "senza rete"', () async {
      final result = await VideoAvailabilityCheck.of(
        _video,
        probe: (_) async => throw TimeoutException('troppo lento'),
      );
      expect(result, VideoAvailability.offline);
    });

    test('un errore HTTP diventa "senza rete"', () async {
      final result = await VideoAvailabilityCheck.of(
        _video,
        probe: (_) async => throw const HttpException('connessione chiusa'),
      );
      expect(result, VideoAvailability.offline);
    });
  });

  group('quando non c e niente da controllare', () {
    test('un URL che non e un video non fa partire nessuna richiesta', () async {
      var called = false;
      final result = await VideoAvailabilityCheck.of(
        'https://www.youtube.com/results?search_query=panca+piana',
        probe: (_) async {
          called = true;
          return 200;
        },
      );

      expect(result, VideoAvailability.unavailable);
      expect(called, isFalse, reason: 'niente rete per una ricerca');
    });

    test('nullo e stringa vuota non fanno cadere nulla', () async {
      expect(
        await VideoAvailabilityCheck.of(null, probe: (_) async => 200),
        VideoAvailability.unavailable,
      );
      expect(
        await VideoAvailabilityCheck.of('', probe: (_) async => 200),
        VideoAvailability.unavailable,
      );
    });
  });

  group('indirizzo interrogato', () {
    test('e l API oEmbed di YouTube, con l identificativo del video', () async {
      late Uri asked;
      await VideoAvailabilityCheck.of(
        'https://youtu.be/dQw4w9WgXcQ',
        probe: (uri) async {
          asked = uri;
          return 200;
        },
      );

      expect(asked.host, 'www.youtube.com');
      expect(asked.path, '/oembed');
      expect(asked.queryParameters['format'], 'json');
      // L'identificativo viene ricostruito in forma canonica: la forma breve
      // youtu.be non e accettata da oEmbed.
      expect(
        asked.queryParameters['url'],
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
    });
  });
}
