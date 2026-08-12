import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'expressive_tokens.dart';

/// Costruisce i temi di GymFlow sulla palette Indigo.
///
/// Il `ColorScheme` e assemblato a mano invece che generato da
/// `ColorScheme.fromSeed`. La ragione: i colori sono cinque, scelti dal
/// prodotto, con i contrasti di ogni coppia gia verificati. Derivarli da un
/// seme unico significherebbe perderli e riottenere altri valori.
///
/// `fromSeed` con `DynamicSchemeVariant.expressive` resta invece la strada per
/// il colore personalizzato dell'utente: la, dove si ha un solo colore di
/// partenza, la derivazione algoritmica e la risposta giusta.
class AppTheme {
  /// Tema scuro, quello predefinito dell'applicazione.
  ///
  /// [accent] e il colore delle azioni: ambra per impostazione predefinita,
  /// modificabile fra i preset di [AppPalette.accentPresets]. [hapticFeedback]
  /// accende la vibrazione al tocco, impostabile da Impostazioni.
  static ThemeData darkTheme(Color accent, {bool hapticFeedback = true}) {
    final scheme = ColorScheme.dark(
      // Azioni. Un solo colore, un solo significato.
      primary: accent,
      onPrimary: AppPalette.indigo900,
      primaryContainer: AppPalette.amberMuted,
      onPrimaryContainer: AppPalette.paper,

      // Supporto: elementi che accompagnano, non chiedono di essere premuti.
      secondary: AppPalette.indigo400,
      onSecondary: AppPalette.indigo900,
      secondaryContainer: AppPalette.indigo700,
      onSecondaryContainer: AppPalette.paper,

      // Dati vitali. Distinto dalle azioni di proposito: una metrica non e un
      // pulsante, e confonderli svuota di significato entrambi.
      tertiary: AppPalette.salmon,
      onTertiary: AppPalette.indigo900,
      tertiaryContainer: AppPalette.salmonMuted,
      onTertiaryContainer: AppPalette.paper,

      // Superfici, dal fondo verso l'alto.
      surface: AppPalette.indigo800,
      onSurface: AppPalette.paper,
      onSurfaceVariant: AppPalette.paperDim,
      surfaceContainerLowest: AppPalette.indigo900,
      surfaceContainerLow: AppPalette.indigo900,
      surfaceContainer: AppPalette.indigo800,
      surfaceContainerHigh: AppPalette.indigo700,
      surfaceContainerHighest: AppPalette.indigo700,
      inverseSurface: AppPalette.paper,
      onInverseSurface: AppPalette.indigo900,

      outline: AppPalette.indigo600,
      outlineVariant: AppPalette.indigo700,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),

      error: AppPalette.danger,
      onError: AppPalette.indigo900,
      errorContainer: const Color(0xFF6E322C),
      onErrorContainer: AppPalette.paper,
    );

    return _build(scheme, AppPalette.indigo900, Brightness.dark, hapticFeedback);
  }

  /// Tema chiaro, per chi lo preferisce.
  ///
  /// Non e un'inversione meccanica: ambra e salmone non hanno contrasto
  /// sufficiente per il testo su fondo chiaro, quindi i ruoli testuali usano le
  /// loro varianti scurite e gli originali finiscono sui contenitori.
  static ThemeData lightTheme(Color accent, {bool hapticFeedback = true}) {
    final scheme = ColorScheme.light(
      primary: AppPalette.amberOnLight,
      onPrimary: AppPalette.paper,
      primaryContainer: accent,
      onPrimaryContainer: AppPalette.indigo900,

      secondary: AppPalette.indigo700,
      onSecondary: AppPalette.paper,
      secondaryContainer: AppPalette.lightSurfaceAlt,
      onSecondaryContainer: AppPalette.indigo900,

      tertiary: AppPalette.salmonOnLight,
      onTertiary: AppPalette.paper,
      tertiaryContainer: AppPalette.salmon,
      onTertiaryContainer: AppPalette.indigo900,

      surface: AppPalette.lightSurface,
      onSurface: AppPalette.lightOnSurface,
      onSurfaceVariant: AppPalette.lightOnSurfaceDim,
      surfaceContainerLowest: AppPalette.lightBackground,
      surfaceContainerLow: AppPalette.lightBackground,
      surfaceContainer: AppPalette.lightSurface,
      surfaceContainerHigh: AppPalette.lightSurfaceAlt,
      surfaceContainerHighest: AppPalette.lightSurfaceAlt,
      inverseSurface: AppPalette.indigo900,
      onInverseSurface: AppPalette.paper,

      outline: const Color(0xFFB6AFCC),
      outlineVariant: const Color(0xFFDEDAEA),
      shadow: AppPalette.indigo900,
      scrim: AppPalette.indigo900,

      error: const Color(0xFFB3261E),
      onError: AppPalette.paper,
      errorContainer: const Color(0xFFF9DEDC),
      onErrorContainer: const Color(0xFF410E0B),
    );

    return _build(scheme, AppPalette.lightBackground, Brightness.light, hapticFeedback);
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
    final textTheme = GoogleFonts.outfitTextTheme(base).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    const shape = ExpressiveShape();

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

      // Token del design system, con la tipografia derivata dalla stessa scala.
      // Vedi docs/adr/001-material-3-expressive.md
      extensions: <ThemeExtension<dynamic>>[
        ExpressiveTokens(typography: ExpressiveTypography.from(textTheme)),
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

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: shape.cornerLg),
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

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: const StadiumBorder(),
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
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: const StadiumBorder(),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        shape: const StadiumBorder(),
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
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: shape.cornerLg),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHigh,
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
      borderRadius: const ExpressiveShape().cornerLg,
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
