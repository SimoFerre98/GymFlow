import 'package:flutter/material.dart';

/// Regioni del corpo usate dal segnaposto dell'esercizio.
///
/// La regione definisce la sagoma a tratto che distingue un esercizio di petto
/// da uno di gambe quando manca l'immagine.
enum BodyRegion {
  chest(Icons.fitness_center_outlined),
  back(Icons.rowing),
  shoulders(Icons.sports_handball),
  arms(Icons.sports_martial_arts),
  legs(Icons.directions_run),
  core(Icons.self_improvement),
  cardio(Icons.monitor_heart_outlined);

  const BodyRegion(this.glyph);

  /// Sagoma disegnata sopra il fondo.
  final IconData glyph;
}

/// Dal gruppo muscolare alla regione del corpo.
///
/// Esiste perche il campo `musclesTargeted` contiene **due vocabolari diversi**
/// e continuera a contenerli: gli esercizi gia presenti in Firestore portano
/// nomi inglesi capitalizzati (`Chest`, `Quads`, `Hamstrings`), mentre la
/// libreria curata che importera US-045 porta nomi italiani minuscoli (`petto`,
/// `quadricipiti`, `femorali`). Riconoscerne uno solo vorrebbe dire mandare
/// meta della libreria sul ripiego generico.
///
/// Un esercizio personalizzato puo scrivere qualunque cosa, quindi il caso
/// "gruppo sconosciuto" non e un errore da segnalare: e un caso normale, e ha
/// un comportamento definito.
abstract final class MuscleGroupVisuals {
  /// Regione di un esercizio, dedotta dai suoi gruppi muscolari.
  ///
  /// Vince il **primo gruppo riconosciuto**, non il primo della lista: in
  /// `['Chest', 'Triceps']` il petto e il movimento, il tricipite lo
  /// accompagna, e chi scrive la lista mette per primo cio che conta. Se pero
  /// il primo nome e ignoto e il secondo no, il secondo e comunque
  /// un'informazione migliore di un ripiego.
  ///
  /// Quando nessun gruppo e riconoscibile si ricade su [_hashedRegion], che
  /// sceglie in modo stabile a partire dal testo: [fallbackSeed] serve a
  /// distinguere fra loro gli esercizi che non dichiarano alcun gruppo — di
  /// solito e il nome dell'esercizio.
  static BodyRegion resolve({
    required Iterable<String> muscleGroups,
    String fallbackSeed = '',
  }) {
    String? firstNonEmpty;

    for (final group in muscleGroups) {
      final key = normalize(group);
      if (key.isEmpty) continue;
      firstNonEmpty ??= key;
      final known = _regionsByGroup[key];
      if (known != null) return known;
    }

    return _hashedRegion(firstNonEmpty ?? normalize(fallbackSeed));
  }

  /// Regione di un singolo gruppo, oppure `null` se il nome non e riconosciuto.
  ///
  /// Separata da [resolve] perche distinguere "non riconosciuto" da "ripiegato"
  /// e cio che permette a un test di misurare quanto vocabolario copriamo
  /// davvero, invece di vedere sempre una regione e crederla giusta.
  static BodyRegion? regionOfGroup(String group) =>
      _regionsByGroup[normalize(group)];

  /// Forma di confronto di un nome di gruppo: minuscolo, senza accenti, senza
  /// spazi ripetuti. `'Spalle Posteriori '` e `'spalle posteriori'` sono lo
  /// stesso gruppo, e il segnaposto non deve dipendere da come e stato scritto.
  static String normalize(String raw) {
    final lower = raw.toLowerCase().trim();
    final buffer = StringBuffer();
    var lastWasSpace = false;

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final plain = _accents[char] ?? char;
      if (plain == ' ' || plain == '_' || plain == '-') {
        // Uno spazio solo, e nessuno ai bordi: 'lower  back' e 'lower-back'
        // sono lo stesso gruppo scritto da due persone diverse.
        if (buffer.isNotEmpty) lastWasSpace = true;
        continue;
      }
      if (lastWasSpace) {
        buffer.write(' ');
        lastWasSpace = false;
      }
      buffer.write(plain);
    }

    return buffer.toString();
  }

  /// Scelta stabile per i gruppi che non conosciamo.
  ///
  /// Deve essere **la stessa a ogni avvio e su ogni dispositivo**, altrimenti
  /// un segnaposto cambierebbe colore fra due aperture dell'app e smetterebbe
  /// di essere un modo per riconoscere l'esercizio. Per questo l'hash e scritto
  /// qui (FNV-1a) invece di usare `String.hashCode`, che Dart non garantisce
  /// stabile fra versioni e piattaforme.
  static BodyRegion _hashedRegion(String seed) {
    var hash = 0x811c9dc5;
    for (final unit in seed.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return BodyRegion.values[hash % BodyRegion.values.length];
  }

  /// I due vocabolari, appiattiti in una tabella sola.
  ///
  /// Le chiavi sono gia normalizzate. I sinonimi non sono zelo preventivo: sono
  /// le forme che compaiono davvero fra `firestore_service.dart` e
  /// `assets/data/exercises_seed.json`, piu le varianti che un esercizio
  /// personalizzato scrive naturalmente.
  static const Map<String, BodyRegion> _regionsByGroup = {
    // Torace
    'petto': BodyRegion.chest,
    'pettorali': BodyRegion.chest,
    'chest': BodyRegion.chest,
    'pecs': BodyRegion.chest,

    // Schiena
    'dorso': BodyRegion.back,
    'dorsali': BodyRegion.back,
    'schiena': BodyRegion.back,
    'trapezio': BodyRegion.back,
    'trapezi': BodyRegion.back,
    'back': BodyRegion.back,
    'upper back': BodyRegion.back,
    'lats': BodyRegion.back,
    'traps': BodyRegion.back,

    // Spalle
    'spalle': BodyRegion.shoulders,
    'spalle posteriori': BodyRegion.shoulders,
    'deltoidi': BodyRegion.shoulders,
    'shoulders': BodyRegion.shoulders,
    'delts': BodyRegion.shoulders,
    'rear delts': BodyRegion.shoulders,

    // Braccia
    'bicipiti': BodyRegion.arms,
    'tricipiti': BodyRegion.arms,
    'avambracci': BodyRegion.arms,
    'braccia': BodyRegion.arms,
    'biceps': BodyRegion.arms,
    'triceps': BodyRegion.arms,
    'forearms': BodyRegion.arms,
    'arms': BodyRegion.arms,

    // Gambe
    'quadricipiti': BodyRegion.legs,
    'femorali': BodyRegion.legs,
    'glutei': BodyRegion.legs,
    'polpacci': BodyRegion.legs,
    'adduttori': BodyRegion.legs,
    'abduttori': BodyRegion.legs,
    'gambe': BodyRegion.legs,
    'quads': BodyRegion.legs,
    'hamstrings': BodyRegion.legs,
    'glutes': BodyRegion.legs,
    'calves': BodyRegion.legs,
    'legs': BodyRegion.legs,

    // Core
    'addome': BodyRegion.core,
    'addominali': BodyRegion.core,
    'obliqui': BodyRegion.core,
    'lombari': BodyRegion.core,
    'core': BodyRegion.core,
    'abs': BodyRegion.core,
    'obliques': BodyRegion.core,
    'lower back': BodyRegion.core,

    // Cardio
    'cardio': BodyRegion.cardio,
    'cuore': BodyRegion.cardio,
    'heart': BodyRegion.cardio,
    'cardiovascolare': BodyRegion.cardio,
  };

  /// Accenti che compaiono nell'italiano dei nomi dei gruppi.
  static const Map<String, String> _accents = {
    'à': 'a',
    'á': 'a',
    'è': 'e',
    'é': 'e',
    'ì': 'i',
    'í': 'i',
    'ò': 'o',
    'ó': 'o',
    'ù': 'u',
    'ú': 'u',
  };
}
