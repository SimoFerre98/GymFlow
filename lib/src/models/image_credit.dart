import 'dart:convert';

/// Attribuzione di una foto della libreria curata degli esercizi.
///
/// Le foto vengono da wger.de sotto Creative Commons Attribution-ShareWithAlike:
/// la licenza impone di nominare autore e licenza, e una miniatura da 56 dp non
/// ha spazio per farlo. Questo modello e cio che la schermata dei crediti mostra
/// al loro posto.
class ImageCredit {
  const ImageCredit({
    required this.exerciseId,
    required this.author,
    required this.licenseShortName,
    required this.licenseUrl,
    required this.sourceUrl,
  });

  final String exerciseId;
  final String author;
  final String licenseShortName;
  final String licenseUrl;
  final String sourceUrl;
}

/// Lettura di `assets/data/exercise_image_credits.json`.
///
/// Sta in un file a se, senza dipendenze da Flutter, per la stessa ragione di
/// [ExerciseSeed]: si prova leggendo il file vero, senza montare un widget.
abstract final class ImageCreditSeed {
  static List<ImageCredit> parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return const [];
    }
    if (decoded is! Map<String, dynamic>) return const [];

    final out = <ImageCredit>[];
    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      out.add(
        ImageCredit(
          exerciseId: entry.key,
          author: (value['author'] as String?)?.trim() ?? '',
          licenseShortName: (value['licenseShortName'] as String?)?.trim() ?? '',
          licenseUrl: (value['licenseUrl'] as String?)?.trim() ?? '',
          sourceUrl: (value['sourceUrl'] as String?)?.trim() ?? '',
        ),
      );
    }
    return out;
  }
}
