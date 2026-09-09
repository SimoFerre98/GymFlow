import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/immersivo_tokens.dart';
import '../../services/auth_service.dart';
import '../widgets/back_pill.dart';
import 'image_credits_screen.dart';
/// Misure del mockup 3f Lingua e info (telaio 1:1, nessuna conversione
/// px→dp).
const double _kTitleFontSize = 28;
/// Versione mostrata nella riga "Versione": allineata a `pubspec.yaml`
/// (`version: 1.0.0+1`). Non c'e una dipendenza (`package_info_plus`) che la
/// legga a runtime — va aggiornata a mano se cambia il numero in pubspec.
const String _kAppVersion = '1.0.0';
/// Generali: lingua e crediti immagini/versione, gli unici tre elementi
/// reali della schermata 3f del mockup.
///
/// Il mockup mostra anche uno spagnolo non tradotto, un selettore di unita di
/// misura, sincronizzazione/esportazione dati, "Privacy e permessi", "Aiuto e
/// assistenza" ed "Elimina account": nessuno di questi ha un campo, un
/// provider o un metodo reale dietro (la sola lingua supportata e IT/EN, non
/// esiste esportazione dati ne cancellazione account) — inventarli userebbe
/// un controllo che non farebbe nulla, quindi non compaiono.
class GeneralSettingsScreen extends ConsumerWidget {
  const GeneralSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
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
                    loc.t('general_settings_section').toUpperCase(),
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
                    _buildLanguage(context, loc, t, scheme, ref),
                    _buildInfo(context, loc, t, scheme),
                    SizedBox(height: t.spacing.lg),
                    _buildSignOut(context, loc, t, scheme),
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
  Widget _buildLanguage(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    WidgetRef ref,
  ) {
    final languages = [
      ('it', 'IT', loc.t('language_name_it')),
      ('en', 'EN', loc.t('language_name_en')),
    ];
    final current = loc.locale.languageCode;
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
                loc.t('language').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: t.spacing.sm),
              for (final (code, abbr, name) in languages)
                InkWell(
                  onTap: () => ref
                      .read(localizationNotifierProvider.notifier)
                      .setLocale(Locale(code)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: scheme.outline)),
                      color: current == code
                          ? scheme.primary.withValues(alpha: 0.08)
                          : null,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                      child: Row(
                        children: [
                          SizedBox(
                            width: t.spacing.xl,
                            child: Text(
                              abbr,
                              style: t.typography.eyebrow?.copyWith(
                                color: current == code
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: current == code ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (current == code)
                            Icon(Icons.check, size: t.sizing.iconSm, color: scheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildInfo(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
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
                loc.t('info_section').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImageCreditsScreen()),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: scheme.outline)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined, size: t.sizing.iconMd, color: scheme.onSurfaceVariant),
                        SizedBox(width: t.spacing.md),
                        Expanded(
                          child: Text(
                            loc.t('image_credits_settings_tile'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, size: t.sizing.iconSm, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
                    bottom: BorderSide(color: scheme.outline),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: t.sizing.iconMd, color: scheme.onSurfaceVariant),
                      SizedBox(width: t.spacing.md),
                      Expanded(
                        child: Text(
                          loc.t('app_version_label'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _kAppVersion,
                        style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSignOut(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return InkWell(
      onTap: () async {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: t.spacing.md),
        decoration: BoxDecoration(
          color: AppPalette.danger.withValues(alpha: 0.12),
          border: Border.all(color: AppPalette.danger.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: AppPalette.danger),
            SizedBox(width: t.spacing.sm),
            Text(
              loc.t('sign_out'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppPalette.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
