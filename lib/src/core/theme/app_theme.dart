import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';
import 'immersivo_tokens.dart';
/// Costruisce i temi di GymFlow su una delle 4 [AppThemeStyle].
///
/// Il `ColorScheme` e assemblato a mano invece che generato da
/// `ColorScheme.fromSeed`. La ragione: i colori sono scelti dal prodotto, con
/// i contrasti di ogni coppia gia verificati. Derivarli da un seme unico
/// significherebbe perderli e riottenere altri valori. [accent] resta
/// l'unico grado di liberta dell'utente dentro la palette scelta (i preset di
/// `style.accentPresets`, selezionabili da Impostazioni) — superficie, fondo
/// e colore dei dati vitali seguono [style].
class AppTheme {
  /// Tema scuro, quello predefinito dell'applicazione.
  ///
  /// [accent] e il colore delle azioni, scelto dentro `style.accentPresets`.
  /// [hapticFeedback] accende la vibrazione al tocco, impostabile da
  /// Impostazioni.
  static ThemeData darkTheme(
    Color accent, {
    AppThemeStyle style = AppThemeStyle.toxicForest,
    bool hapticFeedback = true,
  }) {
    final scheme = ColorScheme.dark(
      // Azioni. Un solo colore, un solo significato.
      primary: accent,
      onPrimary: style.darkBackground,
      primaryContainer: accent.withValues(alpha: 0.3),
      onPrimaryContainer: AppPalette.paper,
      // Supporto: elementi che accompagnano, non chiedono di essere premuti.
      secondary: style.defaultTertiary.withValues(alpha: 0.8),
      onSecondary: style.darkBackground,
      secondaryContainer: style.darkSurfaceHigh,
      onSecondaryContainer: AppPalette.paper,
      // Dati vitali. Distinto dalle azioni di proposito: una metrica non e un
      // pulsante, e confonderli svuota di significato entrambi.
      tertiary: style.defaultTertiary,
      onTertiary: style.darkBackground,
      tertiaryContainer: style.defaultTertiary.withValues(alpha: 0.3),
      onTertiaryContainer: AppPalette.paper,
      // Superfici, dal fondo verso l'alto.
      surface: style.darkSurface,
      onSurface: AppPalette.paper,
      onSurfaceVariant: AppPalette.paperDim,
      surfaceContainerLowest: style.darkBackground,
      surfaceContainerLow: style.darkBackground,
      surfaceContainer: style.darkSurface,
      surfaceContainerHigh: style.darkSurfaceHigh,
      surfaceContainerHighest: style.darkSurfaceHigh,
      inverseSurface: AppPalette.paper,
      onInverseSurface: style.darkBackground,
      outline: style.darkOutline,
      outlineVariant: style.darkSurfaceHigh,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      error: AppPalette.danger,
      onError: style.darkBackground,
      errorContainer: const Color(0xFF6E322C),
      onErrorContainer: AppPalette.paper,
    );
    return _build(scheme, style.darkBackground, Brightness.dark, hapticFeedback);
  }
  /// Tema chiaro, per chi lo preferisce.
  ///
  /// Non e un'inversione meccanica: l'accento e il colore dei dati vitali non
  /// hanno contrasto sufficiente per il testo su fondo chiaro in nessuna delle
  /// 4 palette, quindi i ruoli testuali usano le loro varianti scurite
  /// ([AppThemeStyle.accentOnLight], [AppThemeStyle.tertiaryOnLight]) e gli
  /// originali finiscono sui contenitori.
  static ThemeData lightTheme(
    Color accent, {
    AppThemeStyle style = AppThemeStyle.toxicForest,
    bool hapticFeedback = true,
  }) {
    final scheme = ColorScheme.light(
      primary: style.accentOnLight,
      onPrimary: AppPalette.paper,
      primaryContainer: accent,
      onPrimaryContainer: style.darkBackground,
      secondary: style.darkSurfaceHigh,
      onSecondary: AppPalette.paper,
      secondaryContainer: style.lightSurfaceAlt,
      onSecondaryContainer: style.darkBackground,
      tertiary: style.tertiaryOnLight,
      onTertiary: AppPalette.paper,
      tertiaryContainer: style.defaultTertiary,
      onTertiaryContainer: style.darkBackground,
      surface: style.lightSurface,
      onSurface: AppPalette.lightOnSurface,
      onSurfaceVariant: AppPalette.lightOnSurfaceDim,
      surfaceContainerLowest: style.lightBackground,
      surfaceContainerLow: style.lightBackground,
      surfaceContainer: style.lightSurface,
      surfaceContainerHigh: style.lightSurfaceAlt,
      surfaceContainerHighest: style.lightSurfaceAlt,
      inverseSurface: style.darkBackground,
      onInverseSurface: AppPalette.paper,
      outline: const Color(0xFFA9BFC2),
      outlineVariant: const Color(0xFFD7E3E1),
      shadow: style.darkBackground,
      scrim: style.darkBackground,
      error: const Color(0xFFB3261E),
      onError: AppPalette.paper,
      errorContainer: const Color(0xFFF9DEDC),
      onErrorContainer: const Color(0xFF410E0B),
    );
    return _build(
      scheme,
      style.lightBackground,
      Brightness.light,
      hapticFeedback,
    );
  }
  /// Parte comune ai due temi: tutto cio che deriva dai ruoli, invece di
  /// ripetere colori.
  static ThemeData _build(
    ColorScheme scheme,
    Color scaffoldBackground,
    Brightness brightness,
    bool hapticFeedback,
  ) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.spaceGroteskTextTheme(base).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    const shape = ImmersivoShape();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      // Un solo punto da cui accendere o spegnere la vibrazione al tocco,
      // invece di una chiamata ripetuta in ogni bottone: ogni widget che
      // disegna un'onda materiale (bottoni, righe di lista, chip, switch)
      // passa da qui. `InkSparkle` e il ripiego che Material 3 sceglierebbe
      // comunque su Android, che e l'unica piattaforma di questo progetto:
      // non serve replicare qui la logica di scelta di `ThemeData`.
      splashFactory: hapticFeedback
          ? const _HapticSplashFactory(InkSparkle.splashFactory)
          : null,
      // Token del design system. Vedi docs/adr/002-immersivo-toxic-forest.md
      extensions: <ThemeExtension<dynamic>>[
        ImmersivoTokens(typography: ImmersivoTypography.from(textTheme)),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Il 5% in meno dei 56 dp standard: l'utente lo ha chiesto per
        // alleggerire l'intestazione, hamburger compreso, senza toccare
        // dimensione di icona o testo — solo lo spazio intorno.
        toolbarHeight: kToolbarHeight * 0.95,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      // Angoli vivi, bordo sottile invece di elevazione: il "filetto neon"
      // del mockup che separa i riquadri dal fondo.
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: shape.cornerXs,
          side: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: _inputBorder(scheme.outlineVariant),
        enabledBorder: _inputBorder(scheme.outlineVariant),
        focusedBorder: _inputBorder(scheme.primary, width: 2),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 2),
      ),
      // `.btn-main` del mockup: riempimento pieno, angoli vivi, nessun bordo.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: shape.cornerXs),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: shape.cornerXs),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      // `.btn-main.outline` del mockup: solo il filetto, nessun riempimento.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: shape.cornerXs),
        ),
      ),
      // `.badge-solid` del mockup: rettangolo pieno, non una pillola.
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: shape.cornerXs),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: scheme.surfaceContainerHigh,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: shape.cornerMd),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(shape.radiusXl),
          ),
          side: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: shape.cornerXs,
          side: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHigh,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        indicatorColor: scheme.primary.withValues(alpha: 0.22),
        surfaceTintColor: Colors.transparent,
        indicatorShape: RoundedRectangleBorder(borderRadius: shape.cornerXs),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
  static OutlineInputBorder _inputBorder(Color color, {double width = 1.4}) {
    return OutlineInputBorder(
      borderRadius: const ImmersivoShape().cornerXs,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
/// Fa vibrare al tocco e poi disegna l'onda materiale come farebbe [_inner]:
/// non sostituisce l'effetto visivo, gli aggiunge un effetto fisico prima.
///
/// `selectionClick()` e non `lightImpact()`: e il piu' breve e neutro dei due
/// (vedi `AvvisiTempoDiSistema` in `timer_service.dart`, che invece cerca
/// apposta il piu' forte per il countdown) — qui deve segnare "ho toccato
/// qualcosa", non farsi notare da solo, perche' suonerebbe a ogni bottone
/// della schermata.
class _HapticSplashFactory extends InteractiveInkFeatureFactory {
  const _HapticSplashFactory(this._inner);
  final InteractiveInkFeatureFactory _inner;
  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    HapticFeedback.selectionClick();
    return _inner.create(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}
