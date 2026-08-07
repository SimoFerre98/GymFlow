import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/localization_provider.dart';
import '../../core/theme/expressive_tokens.dart';
import '../../core/utils/workout_summary.dart';
import '../../models/session.dart';
import '../widgets/workout_receipt.dart';

/// Schermata di riepilogo mostrata al termine dell'allenamento
/// o quando si tocca una sessione nello storico.
class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    this.calories,
    this.avgHeartRate,
  });

  final WorkoutSession session;
  final int? calories;
  final int? avgHeartRate;

  // Scritti a mano e non con `DateFormat`: il progetto non chiama mai
  // `initializeDateFormatting`, quindi `DateFormat.MMMd('it')` lancerebbe
  // un'eccezione a runtime. Verificato prima di cambiarli.
  static const _itMonths = [
    'gen',
    'feb',
    'mar',
    'apr',
    'mag',
    'giu',
    'lug',
    'ago',
    'set',
    'ott',
    'nov',
    'dic',
  ];

  static const _enMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime date, String languageCode) {
    final months = languageCode == 'it' ? _itMonths : _enMonths;
    final monthStr =
        (date.month >= 1 && date.month <= 12) ? months[date.month - 1] : '';
    return '${date.day} $monthStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = ref.watch(localizationNotifierProvider);
    final expressive = context.expressive;

    final summary = WorkoutSummary.of(
      session,
      calories: calories,
      avgHeartRate: avgHeartRate,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: expressive.spacing.md,
            vertical: expressive.spacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con pillola di stato e data
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: expressive.spacing.md,
                      vertical: expressive.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: expressive.shape.cornerFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: expressive.spacing.md,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: expressive.spacing.xs),
                        Text(
                          loc.t('workout_summary_completed_pill'),
                          style:
                              (theme.textTheme.labelMedium ?? const TextStyle())
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(session.startTime, loc.locale.languageCode),
                    style: (theme.textTheme.bodyMedium ?? const TextStyle())
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              SizedBox(height: expressive.spacing.md),

              // Scontrino di riepilogo
              WorkoutReceipt(summary: summary),

              SizedBox(height: expressive.spacing.xl),

              // CTA Salva e chiudi
              SizedBox(
                height: expressive.sizing.minTouchTarget,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: expressive.shape.cornerLg,
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: Text(
                    loc.t('workout_summary_close_cta'),
                    style: (theme.textTheme.titleMedium ?? const TextStyle())
                        .copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
              ),
              SizedBox(height: expressive.spacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
