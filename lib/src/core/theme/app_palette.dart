import 'package:flutter/material.dart';

/// Colori di GymFlow.
///
/// Scelti dal prodotto con riferimenti visivi, non derivati algoritmicamente:
/// i rapporti di contrasto di ogni coppia usata dall'interfaccia sono stati
/// misurati e sono verificati da `test/contrast_test.dart`.
///
/// Qui ci sono soltanto i valori. La loro assegnazione ai ruoli Material 3
/// avviene in `app_theme.dart`: chi cerca "di che colore e un bottone" guarda
/// il tema, non questo file.
abstract final class AppPalette {
  // ── Indigo: la famiglia che porta le superfici ──────────────────────────

  /// Sfondo dell'applicazione. Il piu scuro: tutto il resto emerge da qui.
  static const Color indigo900 = Color(0xFF221E3A);

  /// Superficie delle card.
  static const Color indigo800 = Color(0xFF312C51);

  /// Superficie sollevata: card dentro card, elementi flottanti.
  static const Color indigo700 = Color(0xFF48426D);

  /// Bordi e separatori sulle superfici scure.
  static const Color indigo600 = Color(0xFF5A5384);

  /// Elementi di supporto che non sono azioni.
  static const Color indigo400 = Color(0xFF8B84B8);

  // ── Accenti: uno per le azioni, uno per i dati ─────────────────────────

  /// Ambra. **Un solo significato: cosa fare adesso.**
  ///
  /// Se compare su qualcosa che non e un'azione, l'occhio impara a ignorarlo
  /// e il colore perde la sua funzione.
  static const Color amber = Color(0xFFF0C38E);

  /// Ambra spento, per gli stati disabilitati e i contenitori.
  static const Color amberMuted = Color(0xFF8A6E4E);

  /// Salmone. Riservato ai **dati vitali**: battito, sforzo percepito.
  ///
  /// Distinto dall'ambra di proposito: una metrica non e un pulsante.
  static const Color salmon = Color(0xFFF1AA9B);

  /// Salmone spento, per i contenitori.
  static const Color salmonMuted = Color(0xFF8C5F55);

  // ── Neutri ──────────────────────────────────────────────────────────────

  /// Bianco freddo, virato verso l'indigo: un bianco puro sull'indigo
  /// sembrerebbe staccato.
  static const Color paper = Color(0xFFF7F5FB);

  /// Testo secondario sulle superfici scure.
  static const Color paperDim = Color(0xFFB8B2D0);

  // ── Tema chiaro ─────────────────────────────────────────────────────────

  /// Fondo del tema chiaro, con la stessa vira verso l'indigo.
  static const Color lightBackground = Color(0xFFF2F0F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFE9E5F3);

  /// Testo sul tema chiaro.
  static const Color lightOnSurface = Color(0xFF241F3C);
  static const Color lightOnSurfaceDim = Color(0xFF6A648A);

  /// Sul tema chiaro l'ambra non ha contrasto sufficiente per il testo:
  /// serve una variante scurita per i ruoli testuali.
  static const Color amberOnLight = Color(0xFF7A5A2E);

  /// Idem per il salmone.
  static const Color salmonOnLight = Color(0xFF8E4436);

  // ── Semantici: separati dagli accenti ──────────────────────────────────

  static const Color success = Color(0xFF7BC49A);
  static const Color warning = Color(0xFFE8B54A);
  static const Color danger = Color(0xFFE2685C);

  // ── Segnaposto degli esercizi ───────────────────────────────────────────

  /// Tinte del segnaposto, una per regione del corpo.
  ///
  /// Stanno **al posto di una fotografia**, ed e la ragione di ogni scelta che
  /// segue: sono scure e desature come lo e una foto di palestra, e sono
  /// identiche nei due temi, perche una fotografia non cambia quando l'app
  /// passa da chiaro a scuro.
  ///
  /// Perche sette e non dodici: un colore per gruppo muscolare darebbe dodici
  /// tinte, troppo vicine fra loro per restare distinguibili e nessuna
  /// memorizzabile. La regione porta il colore, la sagoma porta il gruppo.
  ///
  /// Nessuna di queste puo essere confusa con [amber] o [salmon], che in questa
  /// app significano rispettivamente "cosa fare adesso" e "dato vitale": sono
  /// tutte piu scure di [indigo400], quindi leggono come superficie e non come
  /// accento. Verificato da `test/contrast_test.dart`.
  static const Color regionChest = Color(0xFF3E4A70);
  static const Color regionBack = Color(0xFF2F5652);
  static const Color regionShoulders = Color(0xFF4A3A66);
  static const Color regionArms = Color(0xFF5B4055);
  static const Color regionLegs = Color(0xFF3B5A3C);
  static const Color regionCore = Color(0xFF35566B);
  static const Color regionCardio = Color(0xFF5C3D42);

  /// Colore della sagoma sul segnaposto.
  ///
  /// Fisso e non preso da `onSurface`: nel tema chiaro quel ruolo e quasi nero
  /// e sparirebbe sulle tinte scure qui sopra.
  static const Color regionGlyph = Color(0xFFD8D3EA);

  /// Preset che l'utente puo scegliere come colore delle azioni.
  ///
  /// Ognuno supera 4,5:1 su [indigo900] e su [indigo800]: la scelta e libera
  /// dentro un insieme che non produce testo illeggibile.
  /// Verificato da `test/contrast_test.dart`.
  static const List<Color> accentPresets = <Color>[
    amber, // ambra, predefinito
    salmon, // salmone
    Color(0xFF9FD8C0), // menta
    Color(0xFFB9AEE8), // lilla
    Color(0xFF8FC7E8), // cielo
    Color(0xFFE8C8DC), // rosa cipria
  ];
}
