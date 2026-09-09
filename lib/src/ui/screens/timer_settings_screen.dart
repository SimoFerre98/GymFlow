import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/providers/timer_settings_provider.dart';
import '../../core/theme/immersivo_tokens.dart';
import '../widgets/back_pill.dart';
/// Misure del mockup 3e Timer e recupero (telaio 1:1, nessuna conversione
/// px→dp).
const double _kTitleFontSize = 28;
const double _kDefaultTimeFontSize = 66;
/// I preset di recupero predefinito del mockup, in secondi. Uguali alle
/// opzioni gia esposte da `TimerSettingsNotifier.setDefaultRestSeconds`.
const _kRestPresets = <int>[30, 45, 60, 90, 120, 180, 300];
/// Timer e recupero: solo le tre preferenze che `TimerSettingsNotifier`
/// gestisce davvero (recupero automatico, durata predefinita, vibrazione).
///
/// Il mockup mostra anche suono a fine recupero, schermo sempre acceso,
/// conto alla rovescia vocale e un recupero diverso per forza/ipertrofia/
/// resistenza: nessuno di questi ha oggi un campo nel provider, quindi non
/// compare — inventarli vorrebbe dire un interruttore che non cambia niente.
class TimerSettingsScreen extends ConsumerWidget {
  const TimerSettingsScreen({super.key});
  String _formatRest(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final settings = ref.watch(timerSettingsNotifierProvider);
    final notifier = ref.read(timerSettingsNotifierProvider.notifier);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: Row(
                children: [
                  BackPill(label: loc.t('settings_title')),
                  SizedBox(width: t.spacing.md),
                  Text(
                    loc.t('timer_settings_title').toUpperCase(),
                    style: t.typography.headline?.copyWith(
                      fontSize: _kTitleFontSize,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDefaultRest(context, loc, t, scheme, settings, notifier),
                    _buildToggle(
                      context,
                      t,
                      scheme,
                      icon: Icons.play_arrow,
                      title: loc.t('auto_rest_timer'),
                      subtitle: loc.t('auto_rest_timer_desc'),
                      value: settings.autoRestEnabled,
                      onChanged: notifier.setAutoRestEnabled,
                    ),
                    _buildToggle(
                      context,
                      t,
                      scheme,
                      icon: Icons.vibration,
                      title: loc.t('vibrate_on_timer_end'),
                      value: settings.vibrateOnTimerEnd,
                      onChanged: notifier.setVibrateOnTimerEnd,
                    ),
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
  Widget _buildDefaultRest(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    TimerSettings settings,
    TimerSettingsNotifier notifier,
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
                loc.t('default_rest_time').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                _formatRest(settings.defaultRestSeconds),
                style: t.typography.headline?.copyWith(
                  fontSize: _kDefaultTimeFontSize,
                  color: scheme.primary,
                ),
              ),
              SizedBox(height: t.spacing.md),
              Wrap(
                spacing: t.spacing.xs,
                runSpacing: t.spacing.xs,
                children: [
                  for (final preset in _kRestPresets)
                    _RestPresetChip(
                      label: _formatRest(preset),
                      selected: settings.defaultRestSeconds == preset,
                      onTap: () => notifier.setDefaultRestSeconds(preset),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildToggle(
    BuildContext context,
    ImmersivoTokens t,
    ColorScheme scheme, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.md),
        child: Row(
          children: [
            Icon(icon, size: t.sizing.iconMd, color: scheme.onSurfaceVariant),
            SizedBox(width: t.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
/// Una scelta di durata predefinita: rettangolo pieno se selezionata.
class _RestPresetChip extends StatelessWidget {
  const _RestPresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md, vertical: t.spacing.sm),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          border: selected ? null : Border.all(color: scheme.outline),
        ),
        child: Text(
          label,
          style: t.typography.eyebrow?.copyWith(
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
