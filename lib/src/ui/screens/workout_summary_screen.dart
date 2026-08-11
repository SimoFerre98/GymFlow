import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/expressive_tokens.dart';
import '../../core/utils/personal_record.dart';
import '../../core/utils/workout_summary.dart';
import '../../models/session.dart';
import '../widgets/workout_receipt.dart';

/// Schermata di riepilogo mostrata al termine dell'allenamento
/// o quando si tocca una sessione nello storico.
class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    this.records,
    this.calories,
    this.avgHeartRate,
  });

  final WorkoutSession session;
  final List<PersonalRecord>? records;
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

    final recordsList = records ??
        PersonalRecord.detectSessionRecords(
          session: session,
          allSessions: ref.watch(dashboardSessionsProvider).value ?? [],
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

              // Record personali battuti nella sessione
              if (recordsList.isNotEmpty) ...[
                for (final record in recordsList) ...[
                  SizedBox(height: expressive.spacing.md),
                  _PersonalRecordCard(record: record),
                ],
              ],

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
                          // Esplicito, e non e ridondante: il tema dipinge tutti
                          // i testi di `onSurface`, e uno stile che porta il
                          // colore dentro vince sul `foregroundColor` del
                          // pulsante. Senza questa riga l'etichetta era carta
                          // chiara su ambra chiara, circa 1,3:1: illeggibile.
                          color: theme.colorScheme.onPrimary,
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

/// Card contornata di evidenza per un record personale superato.
///
/// La variante «contornata» del mockup e trasparente con il solo bordo ambra:
/// e cio che la distingue dalla card piena, che grida «questo e il livello
/// primario». Un fondo la farebbe somigliare a una card normale col bordo.
class _PersonalRecordCard extends ConsumerWidget {
  const _PersonalRecordCard({required this.record});

  final PersonalRecord record;

  /// 2 — il bordo di 1,4 px del mockup convertito (`dp = px x 1,36`).
  ///
  /// Non e un token: `ExpressiveCard` non ha ancora la variante contornata, e
  /// `expressive_tokens.dart` non ospita costanti di un solo componente.
  static const double _borderWidth = 2;

  static String _formatWeight(double v) {
    final text = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
    return text.replaceAll('.', ',');
  }

  static String _formatDate(DateTime? date, String languageCode) {
    if (date == null) return '';
    final months = languageCode == 'it'
        ? WorkoutSummaryScreen._itMonths
        : WorkoutSummaryScreen._enMonths;
    final monthStr =
        (date.month >= 1 && date.month <= 12) ? months[date.month - 1] : '';
    return '${date.day} $monthStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expressive = context.expressive;
    final loc = ref.watch(localizationNotifierProvider);
    final previousDateStr =
        _formatDate(record.previousDate, loc.locale.languageCode);

    final previousText = previousDateStr.isNotEmpty
        ? '${loc.t('previous_max_was')} ${_formatWeight(record.previousWeight)} kg, ${loc.t('on_date')} $previousDateStr'
        : '${loc.t('previous_max_was')} ${_formatWeight(record.previousWeight)} kg';

    return Container(
      padding: EdgeInsets.all(expressive.spacing.md),
      decoration: BoxDecoration(
        borderRadius: expressive.shape.cornerLg,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: _borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: expressive.spacing.sm,
                  vertical: expressive.spacing.xs,
                ),
                decoration: BoxDecoration(
                  // «Fondo = accento al 20%», come tutte le pillole del mockup.
                  color: theme.colorScheme.primary.withValues(alpha: 0.20),
                  borderRadius: expressive.shape.cornerFull,
                ),
                child: Text(
                  loc.t('record_pill').toUpperCase(),
                  style: (theme.textTheme.labelSmall ?? const TextStyle())
                      .copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                ),
              ),
              Text(
                '+${_formatWeight(record.diffWeight)} kg',
                style: (expressive.typography.metricSmall ??
                        theme.textTheme.labelLarge ??
                        const TextStyle())
                    .copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          SizedBox(height: expressive.spacing.sm),
          Text(
            '${record.exerciseName} · ${_formatWeight(record.newWeight)} kg × ${record.newReps}',
            style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: expressive.spacing.xs),
          Text(
            previousText,
            style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
              // `onSurfaceVariant` e gia il ruolo del testo secondario:
              // smorzarlo ancora lo porterebbe fra i testi sbiaditi che
              // US-022 deve andare a recuperare. Come il resto di questa
              // schermata, che usa il ruolo pieno.
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

