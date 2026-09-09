import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motor/motor.dart';
/// Token del design system "Immersivo / Toxic Forest".
///
/// Punto unico da cui i widget leggono spaziature, raggi, bagliori e
/// movimento. I widget non sanno da dove arriva un token: che sia nativo di
/// Flutter, definito qui o fornito da un package, la lettura e sempre
///
/// ```dart
/// final t = context.immersivo;
/// Padding(padding: EdgeInsets.all(t.spacing.md), ...)
/// ```
///
/// Sostituisce `ExpressiveTokens`/Material 3 Expressive (`docs/adr/001`,
/// superseduto da `docs/adr/002-immersivo-toxic-forest.md`): la direzione
/// visiva ora e quella dei mockup in `docs/design/05-immersivo-toxic-forest.html`,
/// non piu quella di Material 3.
///
/// Cosa NON va qui: costanti che servono a una sola schermata. Questo e il
/// vocabolario condiviso del design system, non un contenitore di valori.
@immutable
class ImmersivoTokens extends ThemeExtension<ImmersivoTokens> {
  const ImmersivoTokens({
    this.spacing = const ImmersivoSpacing(),
    this.shape = const ImmersivoShape(),
    this.sizing = const ImmersivoSizing(),
    this.elevation = const ImmersivoElevation(),
    this.motion = const ImmersivoMotion(),
    this.typography = const ImmersivoTypography(),
  });
  final ImmersivoSpacing spacing;
  final ImmersivoShape shape;
  final ImmersivoSizing sizing;
  final ImmersivoElevation elevation;
  final ImmersivoMotion motion;
  final ImmersivoTypography typography;
  @override
  ImmersivoTokens copyWith({
    ImmersivoSpacing? spacing,
    ImmersivoShape? shape,
    ImmersivoSizing? sizing,
    ImmersivoElevation? elevation,
    ImmersivoMotion? motion,
    ImmersivoTypography? typography,
  }) {
    return ImmersivoTokens(
      spacing: spacing ?? this.spacing,
      shape: shape ?? this.shape,
      sizing: sizing ?? this.sizing,
      elevation: elevation ?? this.elevation,
      motion: motion ?? this.motion,
      typography: typography ?? this.typography,
    );
  }
  /// I token sono costanti e non dipendono dal tema, quindi non c'e nulla da
  /// interpolare durante un cambio di tema.
  @override
  ImmersivoTokens lerp(ThemeExtension<ImmersivoTokens>? other, double t) {
    if (other is! ImmersivoTokens) return this;
    return t < 0.5 ? this : other;
  }
}
/// Scala delle spaziature, in multipli di 4.
///
/// Usare la scala invece di valori liberi e cio che rende coerente la
/// spaziatura fra schermate scritte in momenti diversi.
@immutable
class ImmersivoSpacing {
  const ImmersivoSpacing();
  /// 4 — distanza fra un'icona e la sua etichetta.
  double get xs => 4;
  /// 8 — separazione fra elementi affini.
  double get sm => 8;
  /// 16 — padding interno standard, distanza fra riquadri adiacenti.
  double get md => 16;
  /// 20 — padding interno dei riquadri grandi.
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
/// "Immersivo" e un linguaggio ad **angoli vivi**: il mockup non arrotonda
/// quasi nulla — non i pulsanti, non i riquadri, non gli interruttori. I
/// confini si disegnano con un filetto (bordo sottile), non con l'elevazione
/// o lo smusso. [radiusFull] resta per i rari casi circolari genuinamente
/// tondi che restano fuori dal mockup (una foto profilo ritagliata a cerchio,
/// per esempio) — non per pillole o badge, che nel mockup sono rettangoli.
@immutable
class ImmersivoShape {
  const ImmersivoShape();
  double get radiusXs => 0;
  double get radiusSm => 0;
  double get radiusMd => 0;
  double get radiusLg => 0;
  double get radiusXl => 0;
  /// Cerchio pieno: solo per elementi genuinamente circolari (avatar), mai
  /// per badge o pulsanti — quelli restano ad angoli vivi.
  double get radiusFull => 999;
  BorderRadius get cornerXs => BorderRadius.circular(radiusXs);
  BorderRadius get cornerSm => BorderRadius.circular(radiusSm);
  BorderRadius get cornerMd => BorderRadius.circular(radiusMd);
  BorderRadius get cornerLg => BorderRadius.circular(radiusLg);
  BorderRadius get cornerXl => BorderRadius.circular(radiusXl);
  BorderRadius get cornerFull => BorderRadius.circular(radiusFull);
  /// Forma dei riquadri del design system: angoli vivi, il bordo li chiude.
  RoundedRectangleBorder get card =>
      RoundedRectangleBorder(borderRadius: cornerXs);
  /// Forma di badge/etichette compatte: rettangolo ad angoli vivi, non una
  /// pillola — nel mockup (`.badge-solid`, `.badge-outline`) non lo e mai.
  RoundedRectangleBorder get tag =>
      RoundedRectangleBorder(borderRadius: cornerXs);
}
/// Misure dei componenti che compaiono in piu schermate.
///
/// Distinta da [ImmersivoSpacing] di proposito: una spaziatura e lo spazio
/// **fra** le cose, una misura e quanto e grande **una** cosa.
@immutable
class ImmersivoSizing {
  const ImmersivoSizing();
  /// 40 — miniatura nelle liste dense, dove il nome conta piu dell'immagine.
  double get thumbnailSm => 40;
  /// 56 — miniatura predefinita delle liste di esercizi.
  double get thumbnailMd => 56;
  /// 72 — miniatura di rilievo: la testata di una card, l'esercizio in corso.
  double get thumbnailLg => 72;
  /// 18 — lato dell'indicatore sovrapposto a una miniatura.
  double get badge => 18;
  /// 48 — lato minimo di una zona che si tocca (linee guida di accessibilita).
  double get minTouchTarget => 48;
  /// 16 — icona dentro una riga di testo, alta come una lettera maiuscola.
  double get iconSm => 16;
  /// 20 — icona predefinita accanto a un'etichetta.
  double get iconMd => 20;
  /// 24 — icona di un pulsante, o di una voce di elenco.
  double get iconLg => 24;
}
/// Bagliori: la sostituzione dell'ombra in un linguaggio a superfici piatte.
///
/// Il mockup non solleva le superfici con l'ombra — le separa con un filetto
/// e, dove serve enfasi (uno stato selezionato, un elemento fluttuante),
/// aggiunge un alone colorato invece di un'ombra direzionale. Espressi come
/// liste di [BoxShadow] per restare compatibili con [BoxDecoration].
@immutable
class ImmersivoElevation {
  const ImmersivoElevation();
  /// Nessun bagliore: superfici a filo, separate solo dal filetto.
  List<BoxShadow> get none => const [];
  /// Bagliore appena percettibile: elementi selezionabili a riposo.
  List<BoxShadow> level1(Color glow) => [
    BoxShadow(color: glow.withValues(alpha: 0.25), blurRadius: 12),
  ];
  /// Stato selezionato o attivo: il livello piu usato.
  List<BoxShadow> level2(Color glow) => [
    BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: 20),
  ];
  /// Elementi flottanti: barra di navigazione, overlay del timer.
  List<BoxShadow> level3(Color glow) => [
    BoxShadow(color: glow.withValues(alpha: 0.45), blurRadius: 28),
  ];
}
/// Durate e curve del movimento.
///
/// Rimanda ai token nativi [Durations] ed [Easing]: qui c'e solo la mappatura
/// fra intenzione ("una transizione di schermata") e token, cosi che
/// scegliere una durata non sia un gesto arbitrario ripetuto in ogni widget.
/// Non e cambiato con la direzione visiva: le curve non sono legate a
/// Material 3, restano valide.
@immutable
class ImmersivoMotion {
  const ImmersivoMotion();
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
  /// La molla dei mockup Immersivo: `cubic-bezier(.34,1.56,.64,1)`, usata
  /// nelle comparse a scatto (medaglie, badge). Supera l'unita e torna: si
  /// scrive, non si approssima con `Curves.easeOutBack`.
  Curve get spring => const Cubic(0.34, 1.56, 0.64, 1);
  /// Molla fisica veloce a rimbalzo minimo, per controlli reattivi.
  SpringMotion get springSnappy =>
      const MaterialSpringMotion.standardSpatialFast();
  /// Molla fisica media e bilanciata, per pannelli e transizioni fluide.
  SpringMotion get springSmooth =>
      const MaterialSpringMotion.standardSpatialDefault();
  /// Molla fisica marcata con rimbalzo evidente, per gesti espressivi.
  SpringMotion get springExpressive =>
      const MaterialSpringMotion.expressiveSpatialDefault();
}
/// Stili tipografici del linguaggio "Immersivo".
///
/// Quattro famiglie, ognuna con un solo compito — mescolarle e il punto del
/// mockup, non un incidente:
/// - **Anton** (condensato, un solo peso): titoli e numeri protagonisti,
///   sempre MAIUSCOLO. Flutter non ha `text-transform`: chi usa questi stili
///   deve maiuscolare la stringa (`.toUpperCase()`), non lo stile da solo.
/// - **Space Grotesk**: corpo, etichette, pulsanti — il carattere di base del
///   tema (`TextTheme`), letto anche senza passare da qui.
/// - **Sora**: paragrafi lunghi, testo descrittivo.
/// - **JetBrains Mono**: numeri tabulari, etichette "eyebrow", timer.
@immutable
class ImmersivoTypography {
  const ImmersivoTypography({
    this.display,
    this.headline,
    this.title,
    this.paragraph,
    this.metricLarge,
    this.metricMedium,
    this.metricSmall,
    this.eyebrow,
  });
  /// Costruisce gli stili derivandoli da [base], il `TextTheme` del tema
  /// (gia in Space Grotesk).
  factory ImmersivoTypography.from(TextTheme base) {
    TextStyle? anton(TextStyle? s, {double height = 0.9}) => s == null
        ? null
        : GoogleFonts.anton(textStyle: s, height: height, letterSpacing: 0.2);
    TextStyle? mono(TextStyle? s) => s == null
        ? null
        : GoogleFonts.jetBrainsMono(
            textStyle: s,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          );
    return ImmersivoTypography(
      display: anton(base.displayLarge, height: 0.85),
      headline: anton(base.headlineMedium, height: 0.9),
      title: anton(base.titleLarge, height: 0.95),
      paragraph: base.bodyMedium == null
          ? null
          : GoogleFonts.sora(textStyle: base.bodyMedium, height: 1.55),
      metricLarge: mono(base.headlineMedium),
      metricMedium: mono(base.titleLarge),
      metricSmall: mono(base.titleSmall),
      eyebrow: base.labelSmall == null
          ? null
          : GoogleFonts.jetBrainsMono(
              textStyle: base.labelSmall,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
    );
  }
  /// Titolo huge: il nome dell'allenamento del giorno, il numero di punti.
  final TextStyle? display;
  /// Titoli di schermata.
  final TextStyle? headline;
  /// Titoli di sezione e di riquadro.
  final TextStyle? title;
  /// Testo descrittivo lungo (Sora).
  final TextStyle? paragraph;
  /// Numeri protagonisti: il cronometro, il carico della serie.
  final TextStyle? metricLarge;
  /// Numeri dentro le tessere delle statistiche.
  final TextStyle? metricMedium;
  /// Numeri di supporto: valori nelle liste.
  final TextStyle? metricSmall;
  /// Etichetta piccola maiuscola-mono, tipo "SERIE 3 / 4".
  final TextStyle? eyebrow;
  ImmersivoTypography copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? paragraph,
    TextStyle? metricLarge,
    TextStyle? metricMedium,
    TextStyle? metricSmall,
    TextStyle? eyebrow,
  }) {
    return ImmersivoTypography(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      paragraph: paragraph ?? this.paragraph,
      metricLarge: metricLarge ?? this.metricLarge,
      metricMedium: metricMedium ?? this.metricMedium,
      metricSmall: metricSmall ?? this.metricSmall,
      eyebrow: eyebrow ?? this.eyebrow,
    );
  }
}
/// Accesso ai token dal contesto.
///
/// Se l'estensione non e registrata nel tema si ottengono i valori di
/// default invece di un errore: un widget non deve rompersi perche e stato
/// inserito in un albero senza tema completo, per esempio in un test.
extension ImmersivoTokensContext on BuildContext {
  ImmersivoTokens get immersivo =>
      Theme.of(this).extension<ImmersivoTokens>() ?? const ImmersivoTokens();
}
