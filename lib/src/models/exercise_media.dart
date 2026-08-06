/// Riconoscimento e normalizzazione degli URL dei video di esecuzione.
///
/// Sta in un file a se, come funzioni pure senza dipendenze da Flutter, perche
/// e la parte piu facile da sbagliare: gli URL di YouTube hanno cinque forme
/// diverse, e da uno di essi dipende la miniatura dell'esercizio. Funzioni pure
/// significano test rapidi e nessuna sorpresa.
abstract final class YouTubeVideo {
  /// Un identificativo YouTube e composto da 11 caratteri fra lettere, cifre,
  /// trattino e trattino basso.
  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Estrae l'identificativo del video da [url], oppure `null` se l'URL non
  /// contiene un video riconoscibile.
  ///
  /// Forme riconosciute:
  /// - `youtube.com/watch?v=ID`
  /// - `youtu.be/ID`
  /// - `youtube.com/shorts/ID`
  /// - `youtube.com/embed/ID`
  /// - `youtube.com/live/ID`
  ///
  /// **Non** riconosce gli URL di ricerca (`youtube.com/results?search_query=`):
  /// non contengono un video, e per quelli esiste [searchQueryOf].
  static String? idOf(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;

    final host = uri.host.toLowerCase().replaceFirst('www.', '');

    // youtu.be/ID
    if (host == 'youtu.be') {
      return _validate(uri.pathSegments.isEmpty ? null : uri.pathSegments.first);
    }

    // Confronto sul dominio esatto o su un sottodominio: `endsWith` da solo
    // accetterebbe anche `notyoutube.com`, che non e YouTube.
    if (!_isYouTubeHost(host)) return null;

    // youtube.com/watch?v=ID
    final v = uri.queryParameters['v'];
    if (v != null) return _validate(v);

    // youtube.com/shorts/ID, /embed/ID, /live/ID
    const prefixes = {'shorts', 'embed', 'live', 'v'};
    final seg = uri.pathSegments;
    if (seg.length >= 2 && prefixes.contains(seg.first)) {
      return _validate(seg[1]);
    }

    return null;
  }

  /// Estrae la query da un URL di ricerca YouTube, oppure `null`.
  ///
  /// Serve perche il materiale della libreria curata contiene ricerche invece
  /// di video specifici: aprire la ricerca e meno buono che aprire il video,
  /// ma e molto meglio che non avere nulla.
  static String? searchQueryOf(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (!_isYouTubeHost(uri.host.toLowerCase().replaceFirst('www.', ''))) {
      return null;
    }

    final q = uri.queryParameters['search_query'] ?? uri.queryParameters['q'];
    if (q == null || q.trim().isEmpty) return null;
    return q.trim();
  }

  /// Vero se [url] contiene un video riconoscibile.
  static bool isVideoUrl(String? url) => idOf(url) != null;

  /// Miniatura del video, nella qualita piu adatta alle liste.
  ///
  /// E il terzo anello della catena di ripiego dell'immagine: non la carica
  /// nessuno, esiste per il solo fatto che esiste il video.
  static String? thumbnailUrl(String? videoUrl, {YouTubeThumbQuality quality = YouTubeThumbQuality.high}) {
    final id = idOf(videoUrl);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/${quality.fileName}';
  }

  /// URL canonico di visione, ricostruito dall'identificativo.
  static String? watchUrl(String? videoUrl) {
    final id = idOf(videoUrl);
    return id == null ? null : 'https://www.youtube.com/watch?v=$id';
  }

  /// URL di ricerca costruito da [query], per gli esercizi che non hanno
  /// ancora un video scelto.
  static String searchUrl(String query) =>
      'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent(query)}';

  /// Domini validi di YouTube, confrontati per intero o come sottodominio.
  static const _hosts = {'youtube.com', 'youtube-nocookie.com', 'youtu.be'};

  static bool _isYouTubeHost(String host) {
    return _hosts.any((h) => host == h || host.endsWith('.$h'));
  }

  static String? _validate(String? candidate) {
    if (candidate == null) return null;
    // Alcuni URL portano parametri attaccati al segmento: si tiene la parte
    // prima del primo separatore.
    final cleaned = candidate.split(RegExp(r'[?&#]')).first;
    return _idPattern.hasMatch(cleaned) ? cleaned : null;
  }
}

/// Qualita della miniatura YouTube.
enum YouTubeThumbQuality {
  /// 120x90. Per le miniature piccole nelle liste dense.
  standard('default.jpg'),

  /// 320x180. Compromesso per le liste.
  medium('mqdefault.jpg'),

  /// 480x360. Quella predefinita: nitida sulle miniature e leggera.
  high('hqdefault.jpg'),

  /// 640x480, non sempre disponibile.
  standardDefinition('sddefault.jpg'),

  /// 1280x720, non sempre disponibile. Per l'immagine piena in sessione.
  maxRes('maxresdefault.jpg');

  const YouTubeThumbQuality(this.fileName);

  final String fileName;
}
