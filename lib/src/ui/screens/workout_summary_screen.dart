import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/immersivo_tokens.dart';
import '../../core/utils/personal_record.dart';
import '../../core/utils/workout_summary.dart';
import '../../core/providers/goals_provider.dart';
import '../../models/session.dart';
/// Misure del mockup 2h Riepilogo (telaio 1:1, nessuna conversione px→dp —
/// vedi `DESIGN-SPEC.md`).
const double _kCloseIconBoxSide = 38;
const double _kWorkoutNameFontSize = 17;
const double _kHeadlineFontSize = 74;
const double _kStatFontSize = 34;
const double _kRecordWeightFontSize = 26;
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
  static String _formatWeight(double v) {
    final text = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
    return text.replaceAll('.', ',');
  }
  /// Frase reale composta dai dati del riepilogo — mai il testo
  /// d'atmosfera del mockup ("il volume più alto delle ultime cinque
  /// settimane"), che richiederebbe un confronto storico che questa
  /// schermata non calcola.
  String _buildSubtitle(
    Localization loc,
    WorkoutSummary summary,
    int recordCount,
  ) {
    final parts = <String>[
      '${summary.completedSets}/${summary.totalSets} ${loc.t('workout_summary_sets_closed_suffix')}',
    ];
    if (recordCount == 1) {
      parts.add(loc.t('workout_summary_one_record'));
    } else if (recordCount > 1) {
      parts.add('$recordCount ${loc.t('workout_summary_records_plural')}');
    }
    return '${parts.join('. ')}.';
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = context.immersivo;
    final loc = ref.watch(localizationNotifierProvider);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(userGoalsNotifierProvider.notifier)
          .updateProgressFromSessions([session]);
    });
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, loc, summary, t, scheme),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: t.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(
                      context,
                      loc,
                      summary,
                      recordsList.length,
                      t,
                      scheme,
                    ),
                    _buildStatsTrio(context, loc, summary, t, theme, scheme),
                    if (recordsList.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
                        child: Column(
                          children: [
                            SizedBox(height: t.spacing.md),
                            for (final record in recordsList)
                              Padding(
                                padding: EdgeInsets.only(bottom: t.spacing.sm),
                                child: _RecordBar(
                                  record: record,
                                  loc: loc,
                                ),
                              ),
                          ],
                        ),
                      ),
                    SizedBox(height: t.spacing.md),
                    _buildExercisesList(context, loc, summary, t, theme, scheme),
                  ],
                ),
              ),
            ),
            _buildCloseButton(context, loc, t, scheme),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(
    BuildContext context,
    Localization loc,
    WorkoutSummary summary,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: _kCloseIconBoxSide,
              height: _kCloseIconBoxSide,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                border: Border.all(color: scheme.outline),
              ),
              child: Icon(Icons.close, size: t.sizing.iconMd, color: scheme.onSurface),
            ),
          ),
          SizedBox(width: t.spacing.md),
          Text(
            (summary.workoutName.isNotEmpty
                    ? summary.workoutName
                    : loc.t('workout_untitled'))
                .toUpperCase(),
            style: t.typography.title?.copyWith(
              fontSize: _kWorkoutNameFontSize,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(width: t.spacing.md),
          Expanded(
            child: Container(
              height: 1,
              color: scheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHero(
    BuildContext context,
    Localization loc,
    WorkoutSummary summary,
    int recordCount,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    final weekday = DateFormat(
      'EEEE',
      loc.locale.languageCode,
    ).format(summary.startTime);
    final pillLabel =
        '$weekday ${summary.startTime.day} · ${summary.durationMinutes} ${loc.t('duration_min_short')}';
    return Padding(
      padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.lg, t.spacing.md, t.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.sm,
              vertical: t.spacing.xs,
            ),
            color: scheme.primary,
            child: Text(
              pillLabel.toUpperCase(),
              style: t.typography.eyebrow?.copyWith(color: scheme.onPrimary),
            ),
          ),
          SizedBox(height: t.spacing.sm),
          Text(
            loc.t('workout_summary_done_headline').toUpperCase(),
            style: t.typography.headline?.copyWith(
              fontSize: _kHeadlineFontSize,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: t.spacing.sm),
          Text(
            _buildSubtitle(loc, summary, recordCount),
            style: t.typography.paragraph?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
  Widget _buildStatsTrio(
    BuildContext context,
    Localization loc,
    WorkoutSummary summary,
    ImmersivoTokens t,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final stats = <(String, String)>[
      (loc.t('volume_label'), '${summary.totalVolume} kg'),
      (loc.t('sets_label'), '${summary.completedSets}/${summary.totalSets}'),
    ];
    if (summary.averageRpe != null) {
      stats.add((loc.t('rpe_label'), _formatWeight(summary.averageRpe!)));
    } else if (summary.calories != null) {
      stats.add((loc.t('workout_receipt_calories'), '${summary.calories} kcal'));
    } else if (summary.avgHeartRate != null) {
      stats.add((loc.t('workout_receipt_avg_heart_rate'), '${summary.avgHeartRate} bpm'));
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++)
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(
                    top: t.spacing.md,
                    bottom: t.spacing.md,
                    left: i > 0 ? t.spacing.md : 0,
                  ),
                  decoration: BoxDecoration(
                    border: i > 0
                        ? Border(left: BorderSide(color: scheme.outline))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats[i].$1.toUpperCase(),
                        style: t.typography.eyebrow?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        stats[i].$2,
                        style: t.typography.headline?.copyWith(
                          fontSize: _kStatFontSize,
                          color: i == 0 ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildExercisesList(
    BuildContext context,
    Localization loc,
    WorkoutSummary summary,
    ImmersivoTokens t,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    if (summary.exercises.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
      child: Column(
        children: [
          for (var i = 0; i < summary.exercises.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: scheme.outline)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                child: Row(
                  children: [
                    Text(
                      (i + 1).toString().padLeft(2, '0'),
                      style: t.typography.eyebrow?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: t.spacing.md),
                    Expanded(
                      child: Text(
                        summary.exercises[i].name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${summary.exercises[i].completedSets}/${summary.exercises[i].totalSets}',
                      style: t.typography.metricSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildCloseButton(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: EdgeInsets.all(t.spacing.md),
      child: SizedBox(
        height: t.sizing.minTouchTarget,
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: t.shape.cornerLg),
          ),
          icon: const Icon(Icons.check),
          label: Text(
            loc.t('workout_summary_close_cta'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              // Esplicito, e non e ridondante: il tema dipinge tutti i testi
              // di `onSurface`, e uno stile che porta il colore dentro vince
              // sul `foregroundColor` del pulsante. Senza questa riga
              // l'etichetta era carta chiara su ambra chiara, circa 1,3:1:
              // illeggibile.
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
/// La barra piena "nuovo record" del mockup 2h: sostituisce la card
/// contornata precedente, che non corrispondeva al riquadro pieno disegnato
/// li.
class _RecordBar extends StatelessWidget {
  const _RecordBar({required this.record, required this.loc});
  final PersonalRecord record;
  final Localization loc;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weightStr = WorkoutSummaryScreen._formatWeight(record.newWeight);
    final previousStr = WorkoutSummaryScreen._formatWeight(record.previousWeight);
    final previousDateStr = record.previousDate == null
        ? null
        : DateFormat('dd/MM/yyyy').format(record.previousDate!);
    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      color: scheme.primary,
      child: Row(
        children: [
          Icon(Icons.star, color: scheme.onPrimary, size: t.sizing.iconMd),
          SizedBox(width: t.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loc.t('record_pill')} · ${record.exerciseName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  (previousDateStr == null
                          ? '${loc.t('previous_max_was')} $previousStr kg'
                          : '${loc.t('previous_max_was')} $previousStr kg · $previousDateStr')
                      .toUpperCase(),
                  style: t.typography.eyebrow?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$weightStr kg',
                style: t.typography.headline?.copyWith(
                  fontSize: _kRecordWeightFontSize,
                  color: scheme.onPrimary,
                ),
              ),
              Text(
                '× ${record.newReps} ${loc.t('reps_label')}'.toUpperCase(),
                style: t.typography.eyebrow?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
