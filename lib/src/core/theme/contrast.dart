import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rapporti di contrasto secondo WCAG 2.1.
///
/// Serve a due cose concrete: filtrare i preset di colore che l'utente puo
/// scegliere, e far fallire un test se qualcuno ritocca un colore rompendo la
/// leggibilita. Senza una verifica automatica, l'accessibilita regredisce in
/// silenzio al primo cambio di palette.
abstract final class Contrast {
  /// Soglia WCAG AA per il testo di dimensioni normali.
  static const double aa = 4.5;

  /// Soglia WCAG AA per il testo grande (18pt, o 14pt in grassetto).
  static const double aaLarge = 3.0;

  /// Soglia WCAG AAA per il testo di dimensioni normali.
  static const double aaa = 7.0;

  /// Luminanza relativa di [color], secondo la definizione WCAG.
  ///
  /// Non e la luminosita percepita: i tre canali pesano in modo diverso perche
  /// l'occhio umano e molto piu sensibile al verde che al blu.
  static double relativeLuminance(Color color) {
    double channel(double v) {
      // v e già normalizzato fra 0 e 1 dai componenti di Color.
      return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  /// Rapporto di contrasto fra [a] e [b], da 1,0 (identici) a 21,0
  /// (bianco su nero). L'ordine degli argomenti non conta.
  static double ratio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Vero se [foreground] su [background] e leggibile per il testo normale.
  static bool meetsAA(Color foreground, Color background) =>
      ratio(foreground, background) >= aa;

  /// Vero se la coppia e leggibile per il testo grande.
  static bool meetsAALarge(Color foreground, Color background) =>
      ratio(foreground, background) >= aaLarge;

  /// Etichetta del livello raggiunto, per messaggi e diagnostica.
  static String level(Color foreground, Color background) {
    final r = ratio(foreground, background);
    if (r >= aaa) return 'AAA';
    if (r >= aa) return 'AA';
    if (r >= aaLarge) return 'AA testo grande';
    return 'insufficiente';
  }
}
