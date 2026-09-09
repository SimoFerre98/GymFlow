import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/immersivo_tokens.dart';
import '../widgets/back_pill.dart';
import '../widgets/immersivo_switch.dart';
/// Misure del mockup 3d Aspetto (telaio 1:1, nessuna conversione px→dp).
const double _kTitleFontSize = 28;
const double _kPreviewLoadFontSize = 34;
const double _kSwatchSide = 44;
const double _kPaletteStripHeight = 28;
/// 8px del mockup 3d per l'etichetta di un riquadro-palette: piu piccola
/// dell'eyebrow normale (11sp), che a 4 riquadri per riga andava a capo a
/// meta parola invece che sullo spazio.
const double _kPaletteLabelFontSize = 8;
/// Aspetto: tema chiaro/scuro/sistema, palette e colore delle azioni.
///
/// La sezione "PALETTE" (mockup 3d, righe 342-362) e un controllo reale:
/// cambia atmosfera dell'intera app, non solo l'accento — vedi
/// `docs/adr/003-palette-multiple.md`.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final theme = ref.watch(themeSettingsNotifierProvider);
    final themeNotifier = ref.read(themeSettingsNotifierProvider.notifier);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: _buildHeader(context, loc, t, scheme),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThemeMode(context, loc, t, scheme, theme, themeNotifier),
                    _buildPaletteSection(context, loc, t, scheme, theme, themeNotifier),
                    _buildAccentPicker(context, loc, t, scheme, theme, themeNotifier),
                    _buildPreview(context, loc, t, scheme, theme),
                    _buildHapticToggle(context, loc, t, scheme, theme, themeNotifier),
                    SizedBox(height: t.spacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Row(
      children: [
        BackPill(label: loc.t('settings_title')),
        SizedBox(width: t.spacing.md),
        Text(
          loc.t('appearance_title').toUpperCase(),
          style: t.typography.headline?.copyWith(
            fontSize: _kTitleFontSize,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(width: t.spacing.md),
        Expanded(
          child: Container(
            height: 1,
            color: scheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
  Widget _buildThemeMode(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    ThemeSettings theme,
    ThemeSettingsNotifier notifier,
  ) {
    const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: t.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.t('app_theme').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: t.spacing.sm),
              Row(
                children: [
                  for (final mode in modes)
                    Expanded(
                      child: InkWell(
                        onTap: () => notifier.setThemeMode(mode),
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                          decoration: BoxDecoration(
                            color: theme.themeMode == mode
                                ? scheme.primary
                                : Colors.transparent,
                            border: Border.all(color: scheme.outline),
                          ),
                          child: Text(
                            _modeLabel(mode, loc).toUpperCase(),
                            style: t.typography.eyebrow?.copyWith(
                              color: theme.themeMode == mode
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _modeLabel(ThemeMode mode, Localization loc) => switch (mode) {
    ThemeMode.system => loc.t('system'),
    ThemeMode.light => loc.t('light'),
    ThemeMode.dark => loc.t('dark'),
  };
  /// Il nome della palette, con l'a-capo dove lo mette il mockup 3d
  /// (`<br>` fra le due righe) invece di lasciarlo alla rottura organica del
  /// testo — a 8px non e mai a meta parola, ma il punto non e sempre dopo la
  /// prima parola (Deep Sea Neon lo vuole dopo la seconda).
  String _paletteTileLabel(AppThemeStyle style, Localization loc) {
    final nome = loc.t(style.labelKey).toUpperCase();
    final parole = nome.split(' ');
    if (parole.length < 2) return nome;
    final rottura = style == AppThemeStyle.deepSeaNeon ? 2 : 1;
    if (parole.length <= rottura) return nome;
    return '${parole.take(rottura).join(' ')}\n${parole.skip(rottura).join(' ')}';
  }
  Widget _buildPaletteSection(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    ThemeSettings theme,
    ThemeSettingsNotifier notifier,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: t.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.t('palette_label').toUpperCase(),
                    style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    loc.t(theme.themeStyle.labelKey).toUpperCase(),
                    style: t.typography.eyebrow?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
              SizedBox(height: t.spacing.sm),
              Row(
                children: [
                  for (final style in AppThemeStyle.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: style == AppThemeStyle.values.last ? 0 : t.spacing.sm,
                        ),
                        child: _PaletteTile(
                          style: style,
                          label: _paletteTileLabel(style, loc),
                          selected: theme.themeStyle == style,
                          selectedColor: scheme.primary,
                          outlineColor: scheme.outline,
                          textColor: scheme.onSurfaceVariant,
                          onTap: () => notifier.setThemeStyle(style),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAccentPicker(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    ThemeSettings theme,
    ThemeSettingsNotifier notifier,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: t.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.t('accent_color_label').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: t.spacing.sm),
              Row(
                children: [
                  for (final color in theme.themeStyle.accentPresets)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: t.spacing.sm),
                        child: _AccentSwatch(
                          color: color,
                          checkColor: theme.themeStyle.darkBackground,
                          selected: theme.primaryColor.toARGB32() == color.toARGB32(),
                          onTap: () => notifier.setPrimaryColor(color),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPreview(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    ThemeSettings theme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: t.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.t('preview_label').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: t.spacing.sm),
              Container(
                padding: EdgeInsets.all(t.spacing.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  border: Border.all(color: scheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.t('load_label').toUpperCase(),
                              style: t.typography.eyebrow?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '60',
                              style: t.typography.headline?.copyWith(
                                fontSize: _kPreviewLoadFontSize,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: t.spacing.sm,
                            vertical: t.spacing.xs,
                          ),
                          color: scheme.secondary,
                          child: Text(
                            'RPE 8',
                            style: t.typography.eyebrow?.copyWith(color: scheme.onSecondary),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: t.spacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                            color: scheme.primary,
                            child: Text(
                              loc.t('set_done_label').toUpperCase(),
                              style: t.typography.title?.copyWith(color: scheme.onPrimary),
                            ),
                          ),
                        ),
                        SizedBox(width: t.spacing.sm),
                        Container(
                          width: t.sizing.minTouchTarget - t.spacing.md,
                          height: t.sizing.minTouchTarget - t.spacing.md,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
                          child: Icon(
                            Icons.hourglass_bottom,
                            size: t.sizing.iconSm,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHapticToggle(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    ThemeSettings theme,
    ThemeSettingsNotifier notifier,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.md),
        child: Row(
          children: [
            Icon(Icons.vibration, size: t.sizing.iconMd, color: scheme.onSurfaceVariant),
            SizedBox(width: t.spacing.md),
            Expanded(
              child: Text(
                loc.t('haptic_feedback'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ImmersivoSwitch(
              value: theme.hapticFeedback,
              onChanged: notifier.setHapticFeedback,
            ),
          ],
        ),
      ),
    );
  }
}
/// Una tinta del preset degli accenti: quadrato pieno, spunta se scelta.
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.checkColor,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final Color checkColor;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          width: _kSwatchSide,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            border: selected ? Border.all(color: checkColor, width: 2) : null,
          ),
          child: selected ? Icon(Icons.check, color: checkColor) : null,
        ),
      ),
    );
  }
}
/// Un riquadro di [AppThemeStyle]: striscia di 4 colori (fondo, superficie,
/// dato vitale, accento — stesso ordine del mockup 3d) + nome, bordo pieno
/// sul selezionato.
class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.style,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.outlineColor,
    required this.textColor,
    required this.onTap,
  });
  final AppThemeStyle style;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color outlineColor;
  final Color textColor;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(t.spacing.sm, t.spacing.sm, t.spacing.sm, t.spacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? selectedColor : outlineColor, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // `ColoredBox` qui dentro non disegnava nulla (le 4 tinte
            // restavano invisibili anche isolandole con un fondo magenta di
            // debug, che si vedeva pieno mentre i figli no); `Container`
            // con lo stesso `color` invece funziona — stesso `Expanded`,
            // stessa gerarchia, unica differenza il widget della tinta.
            SizedBox(
              height: _kPaletteStripHeight,
              child: Row(
                children: [
                  Expanded(child: Container(color: style.darkBackground)),
                  Expanded(child: Container(color: style.darkSurface)),
                  Expanded(child: Container(color: style.defaultTertiary)),
                  Expanded(child: Container(color: style.defaultAccent)),
                ],
              ),
            ),
            SizedBox(height: t.spacing.sm),
            Text(
              label,
              maxLines: 2,
              style: t.typography.eyebrow?.copyWith(
                fontSize: _kPaletteLabelFontSize,
                height: 1.15,
                color: selected ? selectedColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
