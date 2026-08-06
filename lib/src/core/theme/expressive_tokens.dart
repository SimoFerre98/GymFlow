import 'package:flutter/material.dart';

/// Token del design system Material 3 Expressive.
///
/// Punto unico da cui i widget leggono spaziature, raggi, elevazioni e
/// movimento. I widget non sanno da dove arriva un token: che sia nativo di
/// Flutter, definito qui o fornito da un package, la lettura e sempre
///
/// ```dart
/// final t = context.expressive;
/// Padding(padding: EdgeInsets.all(t.spacing.md), ...)
/// ```
///
/// Perche esiste: Flutter non supporta Material 3 Expressive e non lo sta
/// sviluppando. Le decisioni su cosa prendere da dove sono in
/// `docs/adr/001-material-3-expressive.md`. Quando arrivera il supporto
/// ufficiale, la migrazione sara la riscrittura di questo file: i widget che
/// leggono i token non vanno toccati.
///
/// Cosa NON va qui: costanti che servono a una sola schermata. Questo e il
/// vocabolario condiviso del design system, non un contenitore di valori.
@immutable
class ExpressiveTokens extends ThemeExtension<ExpressiveTokens> {
  const ExpressiveTokens({
    this.spacing = const ExpressiveSpacing(),
    this.shape = const ExpressiveShape(),
    this.elevation = const ExpressiveElevation(),
    this.motion = const ExpressiveMotion(),
  });

  final ExpressiveSpacing spacing;
  final ExpressiveShape shape;
  final ExpressiveElevation elevation;
  final ExpressiveMotion motion;

  @override
  ExpressiveTokens copyWith({
    ExpressiveSpacing? spacing,
    ExpressiveShape? shape,
    ExpressiveElevation? elevation,
    ExpressiveMotion? motion,
  }) {
    return ExpressiveTokens(
      spacing: spacing ?? this.spacing,
      shape: shape ?? this.shape,
      elevation: elevation ?? this.elevation,
      motion: motion ?? this.motion,
    );
  }

  /// I token sono costanti e non dipendono dal tema, quindi non c'e nulla da
  /// interpolare durante un cambio di tema.
  @override
  ExpressiveTokens lerp(ThemeExtension<ExpressiveTokens>? other, double t) {
    if (other is! ExpressiveTokens) return this;
    return t < 0.5 ? this : other;
  }
}

/// Scala delle spaziature, in multipli di 4.
///
/// Usare la scala invece di valori liberi e cio che rende coerente la
/// spaziatura fra schermate scritte in momenti diversi.
@immutable
class ExpressiveSpacing {
  const ExpressiveSpacing();

  /// 4 — distanza fra un'icona e la sua etichetta.
  double get xs => 4;

  /// 8 — separazione fra elementi affini.
  double get sm => 8;

  /// 16 — padding interno standard, distanza fra card adiacenti.
  double get md => 16;

  /// 20 — padding interno delle card grandi.
  double get lg => 20;

  /// 24 — margine di schermata.
  double get xl => 24;

  /// 32 — separazione fra sezioni.
  double get xxl => 32;

  /// 100 — spazio in coda alle liste, per non finire sotto la barra flottante.
  double get bottomInset => 100;
}

/// Raggi di curvatura e forme.
///
/// Material 3 Expressive privilegia forme marcate: i raggi sono piu generosi
/// di quelli di Material 3 standard. La libreria completa delle 35 forme e
/// il morphing arriveranno con US-035; qui ci sono i raggi che servono
/// oggi ai contenitori.
@immutable
class ExpressiveShape {
  const ExpressiveShape();

  double get radiusXs => 8;
  double get radiusSm => 12;
  double get radiusMd => 16;
  double get radiusLg => 24;
  double get radiusXl => 32;

  /// Pillola: raggio abbastanza grande da rendere semicircolari i lati corti.
  double get radiusFull => 999;

  BorderRadius get cornerXs => BorderRadius.circular(radiusXs);
  BorderRadius get cornerSm => BorderRadius.circular(radiusSm);
  BorderRadius get cornerMd => BorderRadius.circular(radiusMd);
  BorderRadius get cornerLg => BorderRadius.circular(radiusLg);
  BorderRadius get cornerXl => BorderRadius.circular(radiusXl);
  BorderRadius get cornerFull => BorderRadius.circular(radiusFull);

  /// Forma delle card del design system.
  RoundedRectangleBorder get card =>
      RoundedRectangleBorder(borderRadius: cornerLg);

  /// Forma dei contenitori a pillola: chip, pulsanti compatti, badge.
  RoundedRectangleBorder get pill =>
      RoundedRectangleBorder(borderRadius: cornerFull);
}

/// Ombre dei contenitori.
///
/// Espresse come liste di [BoxShadow] invece che come quote di elevazione
/// perche l'app costruisce le proprie superfici con [BoxDecoration] anziche
/// con [Material].
@immutable
class ExpressiveElevation {
  const ExpressiveElevation();

  /// Nessuna ombra: superfici a filo.
  List<BoxShadow> get none => const [];

  /// Distacco appena percettibile: elementi selezionabili a riposo.
  List<BoxShadow> level1(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Card e contenitori: il livello piu usato.
  List<BoxShadow> level2(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  /// Elementi flottanti: barra di navigazione, overlay del timer.
  List<BoxShadow> level3(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Durate e curve del movimento.
///
/// Rimanda ai token nativi [Durations] ed [Easing], che Flutter fornisce: qui
/// c'e solo la mappatura fra intenzione ("una transizione di schermata") e
/// token ("extralong2"), cosi che scegliere una durata non sia un gesto
/// arbitrario ripetuto in ogni widget.
///
/// Il movimento fisico a molla, che Material 3 Expressive introduce e Flutter
/// non ha, arrivera con US-036 valutando il package `motor`.
@immutable
class ExpressiveMotion {
  const ExpressiveMotion();

  /// 100 ms — reazione immediata al tocco.
  Duration get instant => Durations.short2;

  /// 200 ms — cambio di stato di un controllo.
  Duration get quick => Durations.short4;

  /// 300 ms — comparsa o scomparsa di un elemento.
  Duration get standard => Durations.medium2;

  /// 500 ms — transizione fra sezioni.
  Duration get emphasized => Durations.long2;

  /// 800 ms — movimento espressivo, usato con parsimonia.
  Duration get expressive => Durations.extralong2;

  /// Curva predefinita: parte decisa e si posa dolcemente.
  Curve get standardCurve => Easing.standard;

  /// Ingresso di un elemento.
  Curve get enter => Easing.standardDecelerate;

  /// Uscita di un elemento.
  Curve get exit => Easing.standardAccelerate;

  /// Movimento marcato, per le transizioni che devono farsi notare.
  Curve get emphasizedCurve => Easing.emphasizedDecelerate;
}

/// Accesso ai token dal contesto.
///
/// Se l'estensione non e registrata nel tema si ottengono i valori di
/// default invece di un errore: un widget non deve rompersi perche e stato
/// inserito in un albero senza tema completo, per esempio in un test.
extension ExpressiveTokensContext on BuildContext {
  ExpressiveTokens get expressive =>
      Theme.of(this).extension<ExpressiveTokens>() ?? const ExpressiveTokens();
}
