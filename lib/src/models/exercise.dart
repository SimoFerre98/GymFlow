import 'exercise_media.dart';

enum ExerciseType {
  strength, // Weight X Reps
  cardio, // Distance X Time
  timed, // Time (Duration) only
  bodyweight, // Reps only
  isometric, // Time (Static hold)
}

class Exercise {
  final String id;
  final String? userId; // Null for default exercises
  final String name;
  final String description;
  final ExerciseType type;

  /// Video dell'esecuzione, quando ne e stato scelto uno preciso.
  ///
  /// Da questo si ricava la miniatura: e la ragione per cui un video specifico
  /// vale piu di una ricerca.
  final String? videoUrl;

  /// Ricerca su YouTube, per gli esercizi che non hanno ancora un video scelto.
  ///
  /// Esiste perche la libreria curata di partenza contiene ricerche e non
  /// video: aprire una lista di risultati e meno buono che aprire l'esecuzione,
  /// ma molto meglio che non offrire nulla. Va sostituita da [videoUrl] man
  /// mano che i video vengono scelti.
  final String? videoSearchQuery;

  /// Immagine della libreria curata.
  final String? imageUrl;

  /// Immagine caricata dall'utente. Ha la precedenza su [imageUrl]: e la piu
  /// pertinente al suo modo di allenarsi.
  final String? userImageUrl;

  final List<String> musclesTargeted;
  final bool isCustom;

  /// Vero per gli esercizi della libreria fornita col prodotto.
  final bool isCurated;

  Exercise({
    required this.id,
    this.userId,
    required this.name,
    required this.description,
    required this.type,
    this.videoUrl,
    this.videoSearchQuery,
    this.imageUrl,
    this.userImageUrl,
    required this.musclesTargeted,
    this.isCustom = false,
    this.isCurated = false,
  });

  /// Indirizzi della miniatura, dal piu desiderabile all'ultimo ripiego.
  ///
  /// E una **lista** e non un solo indirizzo perche un URL puo esistere e non
  /// caricarsi: se l'immagine curata risponde 404, da un singolo valore non si
  /// torna indietro. Chi disegna cammina la lista e si ferma al primo che
  /// funziona; quando la lista finisce, tocca al segnaposto.
  ///
  /// Ordine: foto dell'utente, immagine curata, miniatura del video.
  List<String> get thumbnailCandidates =>
      _candidates(const [YouTubeThumbQuality.high]);

  /// Indirizzi dell'immagine grande, che chiede piu risoluzione della lista.
  ///
  /// Contiene **due** qualita YouTube di proposito: `maxresdefault` esiste solo
  /// per i video caricati in alta risoluzione e per gli altri risponde 404,
  /// quindi dietro sta la qualita che esiste sempre.
  List<String> get heroCandidates => _candidates(const [
    YouTubeThumbQuality.maxRes,
    YouTubeThumbQuality.high,
  ]);

  /// Miniatura da mostrare, primo anello della catena.
  ///
  /// `null` quando non c'e alcun indirizzo utilizzabile: sta al widget
  /// chiamante disegnare il segnaposto, che e l'ultimo anello.
  String? get thumbnailUrl => _firstOrNull(thumbnailCandidates);

  /// Immagine grande per la sessione, primo anello della sua catena.
  String? get heroImageUrl => _firstOrNull(heroCandidates);

  /// Costruisce la catena scartando cio che non si puo chiedere alla rete.
  ///
  /// Un candidato che non e un URL `http`/`https` assoluto viene **saltato**,
  /// non disegnato: un percorso locale richiederebbe un secondo percorso di
  /// codice e un secondo insieme di errori, per un caso che oggi non esiste
  /// (nessuno scrive ancora [userImageUrl]).
  List<String> _candidates(List<YouTubeThumbQuality> qualities) {
    final out = <String>[];

    void add(String? url) {
      if (url == null) return;
      final trimmed = url.trim();
      if (trimmed.isEmpty || !_isRemote(trimmed)) return;
      // Se la foto dell'utente e la stessa immagine curata, chiederla due
      // volte significherebbe due errori identici prima del segnaposto.
      if (out.contains(trimmed)) return;
      out.add(trimmed);
    }

    add(userImageUrl);
    add(imageUrl);
    for (final quality in qualities) {
      add(YouTubeVideo.thumbnailUrl(videoUrl, quality: quality));
    }
    return out;
  }

  static bool _isRemote(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty;
  }

  static String? _firstOrNull(List<String> values) =>
      values.isEmpty ? null : values.first;

  /// Indirizzo da aprire per vedere l'esecuzione: il video se c'e, altrimenti
  /// la ricerca. `null` se non c'e nemmeno quella.
  String? get executionUrl {
    final watch = YouTubeVideo.watchUrl(videoUrl);
    if (watch != null) return watch;
    final q = videoSearchQuery;
    if (q != null && q.trim().isNotEmpty) return YouTubeVideo.searchUrl(q);
    return null;
  }

  /// Vero se l'esecuzione porta a un video preciso invece che a una ricerca:
  /// la UI lo usa per distinguere le due promesse all'utente.
  bool get hasSpecificVideo => YouTubeVideo.isVideoUrl(videoUrl);

  Exercise copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    ExerciseType? type,
    String? videoUrl,
    String? videoSearchQuery,
    String? imageUrl,
    String? userImageUrl,
    List<String>? musclesTargeted,
    bool? isCustom,
    bool? isCurated,
  }) {
    return Exercise(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      videoUrl: videoUrl ?? this.videoUrl,
      videoSearchQuery: videoSearchQuery ?? this.videoSearchQuery,
      imageUrl: imageUrl ?? this.imageUrl,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      musclesTargeted: musclesTargeted ?? this.musclesTargeted,
      isCustom: isCustom ?? this.isCustom,
      isCurated: isCurated ?? this.isCurated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'type': type.name,
      'videoUrl': videoUrl,
      'videoSearchQuery': videoSearchQuery,
      'imageUrl': imageUrl,
      'userImageUrl': userImageUrl,
      'musclesTargeted': musclesTargeted,
      'isCustom': isCustom,
      'isCurated': isCurated,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map, String id) {
    // Se il campo videoUrl di un documento vecchio contiene una ricerca invece
    // di un video, viene riconosciuto come tale e spostato nel campo giusto:
    // nessuna migrazione dei dati, e l'esercizio resta comunque apribile.
    final rawVideo = map['videoUrl'] as String?;
    final isSearch = !YouTubeVideo.isVideoUrl(rawVideo) &&
        YouTubeVideo.searchQueryOf(rawVideo) != null;

    return Exercise(
      id: id,
      userId: map['userId'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: _parseType(map['type']),
      videoUrl: isSearch ? null : rawVideo,
      videoSearchQuery: map['videoSearchQuery'] as String? ??
          (isSearch ? YouTubeVideo.searchQueryOf(rawVideo) : null),
      imageUrl: map['imageUrl'],
      userImageUrl: map['userImageUrl'],
      musclesTargeted: List<String>.from(map['musclesTargeted'] ?? []),
      isCustom: map['isCustom'] ?? false,
      isCurated: map['isCurated'] ?? false,
    );
  }

  static ExerciseType _parseType(String? type) {
    return ExerciseType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ExerciseType.strength,
    );
  }
}
