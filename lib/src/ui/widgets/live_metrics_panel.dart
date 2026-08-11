import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/live_metrics_provider.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/expressive_tokens.dart';
import 'sparkline.dart';

/// Pannello superiore che mostra il cronometro della sessione e le metriche
/// dal vivo (calorie stimate e frequenza cardiaca) con sparkline integrate.
class LiveMetricsPanel extends ConsumerWidget {
  const LiveMetricsPanel({
    super.key,
    required this.formattedTime,
    this.statusText,
    this.action,
  });

  /// Tempo trascorso formattato per il cronometro (es. "00:24:12").
  final String formattedTime;

  /// Testo di stato opzionale (es. nome allenamento o "IN CORSO").
  final String? statusText;

  /// Widget di azione opzionale posizionato a destra nell'intestazione.
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveMetrics = ref.watch(liveMetricsNotifierProvider);
    final loc = ref.watch(localizationNotifierProvider);
    final theme = Theme.of(context);
    final expressive = context.expressive;

    final primaryColor = theme.colorScheme.primary;
    final tertiaryColor = theme.colorScheme.tertiary;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final onSurfaceVariantColor = theme.colorScheme.onSurfaceVariant;

    return ClipRRect(
      borderRadius: expressive.shape.cornerLg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(expressive.spacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.90),
            borderRadius: expressive.shape.cornerLg,
            border: Border.all(
              color: onSurfaceColor.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Riga intestazione: Stato + Cronometro + Azione opzionale
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (statusText ?? loc.t('live_metrics_in_progress'))
                              .toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: onSurfaceVariantColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: expressive.spacing.xs / 2),
                        Text(
                          formattedTime,
                          style:
                              (expressive.typography.metricLarge ??
                                      theme.textTheme.headlineMedium)
                                  ?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),

              SizedBox(height: expressive.spacing.md),

              // Sezione metriche dal vivo
              if (!liveMetrics.hasPermission)
                _PermissionPromptCard(
                  promptText: loc.t('live_metrics_permission_prompt'),
                  buttonText: loc.t('live_metrics_grant_permission'),
                  onRequestPermission: () {
                    ref
                        .read(liveMetricsNotifierProvider.notifier)
                        .requestPermissions();
                  },
                )
              else
                Row(
                  children: [
                    // Card Calorie
                    Expanded(
                      child: _MetricCard(
                        title: loc.t('live_metrics_calories'),
                        unit: loc.t('live_metrics_kcal'),
                        valueText: liveMetrics.calories != null
                            ? liveMetrics.calories!.toStringAsFixed(0)
                            : '—',
                        icon: Icons.local_fire_department,
                        color: primaryColor,
                        history: liveMetrics.calorieHistory,
                      ),
                    ),

                    // Card Battito Cardiaco (mostrata solo se il sensore e presente)
                    if (liveMetrics.canReadHeartRate) ...[
                      SizedBox(width: expressive.spacing.sm),
                      Expanded(
                        child: _MetricCard(
                          title: loc.t('live_metrics_heart_rate'),
                          unit: loc.t('live_metrics_bpm'),
                          valueText: liveMetrics.heartRate != null
                              ? '${liveMetrics.heartRate}'
                              : '—',
                          icon: Icons.favorite,
                          color: tertiaryColor,
                          history: liveMetrics.heartRateHistory,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.unit,
    required this.valueText,
    required this.icon,
    required this.color,
    required this.history,
  });

  final String title;
  final String unit;
  final String valueText;
  final IconData icon;
  final Color color;
  final List<double> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expressive = context.expressive;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: expressive.spacing.sm,
        vertical: expressive.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: expressive.shape.cornerMd,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: expressive.sizing.iconSm, color: color),
              SizedBox(width: expressive.spacing.xs),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: expressive.spacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valueText,
                style:
                    (expressive.typography.metricMedium ??
                            theme.textTheme.titleLarge)
                        ?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: expressive.spacing.xs / 2),
              Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: expressive.spacing.xs),
          Sparkline(values: history, color: color),
        ],
      ),
    );
  }
}

class _PermissionPromptCard extends StatelessWidget {
  const _PermissionPromptCard({
    required this.promptText,
    required this.buttonText,
    required this.onRequestPermission,
  });

  final String promptText;
  final String buttonText;
  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expressive = context.expressive;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: expressive.spacing.md,
        vertical: expressive.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: expressive.shape.cornerMd,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: expressive.sizing.iconMd,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: expressive.spacing.sm),
          Expanded(
            child: Text(
              promptText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: expressive.spacing.xs),
          TextButton(
            onPressed: onRequestPermission,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: expressive.spacing.sm,
                vertical: expressive.spacing.xs,
              ),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
