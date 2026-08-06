import 'dart:async';
import 'dart:io';

import '../models/exercise_media.dart';

/// Cosa sappiamo di un video prima di provare a mostrarlo.
enum VideoAvailability {
  /// YouTube conferma che il video esiste ed e incorporabile.
  available,

  /// Rimosso, privato, oppure con l'incorporamento vietato dall'autore.
  unavailable,

  /// YouTube non risponde: quasi sempre significa che non c'e connessione.
  offline,
}

/// Risultato grezzo di un'interrogazione: il codice di stato HTTP.
typedef VideoProbe = Future<int> Function(Uri uri);

/// Chiede a YouTube se un video esiste, **prima** di aprire il riproduttore.
///
/// Serve perche i criteri di US-044 chiedono due messaggi diversi — «il video
/// non e disponibile» e «serve una connessione» — e un riproduttore che non
/// parte non dice quale dei due sia: resta a caricare, e basta.
///
/// Si usa l'API oEmbed, la stessa con cui i 15 identificativi della libreria
/// curata sono stati verificati quando il materiale e arrivato. Risponde 200
/// per un video esistente e incorporabile, 401 o 404 per uno rimosso, privato o
/// con l'incorporamento vietato — che dal punto di vista di chi guarda sono la
/// stessa cosa: non lo puo vedere qui.
abstract final class VideoAvailabilityCheck {
  /// Oltre questo tempo si considera che la rete non ci sia.
  ///
  /// Cinque secondi perche il foglio si apre subito e mostra l'attesa: e il
  /// tempo oltre il quale un messaggio onesto vale piu di una rotellina.
  static const timeout = Duration(seconds: 5);

  static Future<VideoAvailability> of(String? videoUrl, {VideoProbe? probe}) async {
    final id = YouTubeVideo.idOf(videoUrl);
    // Nessun video da controllare: non e un problema di rete, e proprio
    // un'assenza. Chi chiama distingue gia questo caso, ma il servizio non deve
    // dipendere dal fatto che lo faccia.
    if (id == null) return VideoAvailability.unavailable;

    final uri = Uri.https('www.youtube.com', '/oembed', {
      'url': 'https://www.youtube.com/watch?v=$id',
      'format': 'json',
    });

    try {
      final status = await (probe ?? _httpProbe)(uri).timeout(timeout);
      return status == 200
          ? VideoAvailability.available
          : VideoAvailability.unavailable;
    } on TimeoutException {
      return VideoAvailability.offline;
    } on SocketException {
      return VideoAvailability.offline;
    } on HttpException {
      return VideoAvailability.offline;
    } on HandshakeException {
      return VideoAvailability.offline;
    }
  }

  /// Interrogazione vera. Sostituibile nei test: senza, verificare i tre esiti
  /// richiederebbe di staccare la rete a comando.
  static Future<int> _httpProbe(Uri uri) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      // Il corpo non serve, ma va consumato: senza, la connessione resta
      // appesa finche non scade.
      await response.drain<void>();
      return response.statusCode;
    } finally {
      client.close(force: true);
    }
  }
}
