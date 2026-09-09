import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gymflow/src/core/providers/dashboard_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/providers/personal_best_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/core/utils/exercise_progression.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/ui/widgets/exercise_image.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';
/// Misure del mockup 2e Dettaglio esercizio (telaio 1:1, nessuna conversione
/// px→dp — vedi `DESIGN-SPEC.md`).
const double _kHeroHeight = 360;
const double _kIconBoxSide = 38;
const double _kTitleFontSize = 50;
const double _kStatFontSize = 30;
const double _kChartHeight = 240;
/// Le tre schede sotto la testata. "Tecnica" mostra la descrizione reale
/// dell'esercizio (non le note generiche del mockup, che per un esercizio
/// qualunque non esistono come dato), "Storico" le sessioni passate,
/// "Record" il primato.
enum _DetailTab { technique, history, record }
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});
  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}
class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  ProgressionPeriod _selectedPeriod = ProgressionPeriod.all;
  _DetailTab _selectedTab = _DetailTab.technique;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = ref.watch(localizationNotifierProvider);
    final sessionsAsync = ref.watch(dashboardSessionsProvider);
    final sessions = sessionsAsync.value ?? <WorkoutSession>[];
    final personalBests = ref.watch(personalBestsProvider);
    final personalBest = personalBests[widget.exercise.id];
    final progressionPoints = ExerciseProgression.calculateProgressionPoints(
      sessions: sessions,
      exerciseId: widget.exercise.id,
      period: _selectedPeriod,
    );
    return Scaffold(
      body: Column(
        children: [
          _buildHero(context, loc, t, scheme),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: t.spacing.bottomInset + t.spacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SegmentedRow<_DetailTab>(
                    values: _DetailTab.values,
                    selected: _selectedTab,
                    labelOf: (tab) => switch (tab) {
                      _DetailTab.technique => loc.t('exercise_tab_technique'),
                      _DetailTab.history => loc.t('exercise_tab_history'),
                      _DetailTab.record => loc.t('exercise_tab_record'),
                    },
                    onSelected: (tab) => setState(() => _selectedTab = tab),
                  ),
                  Padding(
                    padding: EdgeInsets.all(t.spacing.md),
                    child: switch (_selectedTab) {
                      _DetailTab.technique => _buildTechnique(
                          context, loc, theme, scheme, t),
                      _DetailTab.history => _buildHistory(
                          context, loc, theme, scheme, t, sessions),
                      _DetailTab.record => _buildRecord(
                          context, loc, theme, scheme, t, personalBest),
                    },
                  ),
                  _buildStatTrio(
                    context,
                    loc,
                    theme,
                    scheme,
                    t,
                    sessions,
                    personalBest,
                  ),
                  Padding(
                    padding: EdgeInsets.all(t.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('exercise_progression_title').toUpperCase(),
                          style: t.typography.eyebrow?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: t.spacing.sm),
                        _SegmentedRow<ProgressionPeriod>(
                          values: ProgressionPeriod.values,
                          selected: _selectedPeriod,
                          labelOf: (p) => loc.t(switch (p) {
                            ProgressionPeriod.oneMonth => 'exercise_period_1m',
                            ProgressionPeriod.threeMonths =>
                              'exercise_period_3m',
                            ProgressionPeriod.all => 'exercise_period_all',
                          }),
                          onSelected: (p) =>
                              setState(() => _selectedPeriod = p),
                        ),
                        SizedBox(height: t.spacing.md),
                        if (progressionPoints.isEmpty)
                          _buildEmptyHistoryCard(context, loc, theme, scheme, t)
                        else
                          _buildChartCard(
                            context,
                            loc,
                            theme,
                            scheme,
                            t,
                            progressionPoints,
                          ),
                      ],
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
  Widget _buildHero(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return SizedBox(
      height: _kHeroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExerciseImage(
            exercise: widget.exercise,
            size: ExerciseImageSize.hero,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.scrim.withValues(alpha: 0.45),
                  scheme.scrim.withValues(alpha: 0.05),
                  scheme.surfaceContainerLowest.withValues(alpha: 0.98),
                ],
                stops: const [0.0, 0.32, 0.95],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(t.spacing.md),
              child: Row(
                children: [
                  _HeroIconButton(
                    icon: Icons.arrow_back,
                    tooltip: loc.t('exercises_menu'),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  _HeroIconButton(
                    icon: Icons.play_circle_outline,
                    tooltip: loc.t('video_available'),
                    highlighted: true,
                    onTap: () =>
                        ExerciseVideoSheet.show(context, widget.exercise),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: t.spacing.md,
            right: t.spacing.md,
            bottom: t.spacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.spacing.sm,
                    vertical: t.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Text(
                    widget.exercise.type.name.toUpperCase(),
                    style: t.typography.eyebrow?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: t.spacing.sm),
                Text(
                  widget.exercise.name.toUpperCase(),
                  style: t.typography.headline?.copyWith(
                    fontSize: _kTitleFontSize,
                    color: scheme.onSurface,
                  ),
                ),
                if (widget.exercise.musclesTargeted.isNotEmpty) ...[
                  SizedBox(height: t.spacing.sm),
                  Wrap(
                    spacing: t.spacing.sm,
                    runSpacing: t.spacing.xs,
                    children: widget.exercise.musclesTargeted
                        .map(
                          (m) => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: t.spacing.sm,
                              vertical: t.spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHigh,
                              border: Border.all(color: scheme.outline),
                            ),
                            child: Text(
                              m.toUpperCase(),
                              style: t.typography.eyebrow?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTechnique(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ImmersivoTokens t,
  ) {
    final description = widget.exercise.description.trim();
    // "Custom exercise" e il segnaposto che `handleAddExerciseSubmit`
    // scrive per ogni esercizio personalizzato: non e una nota tecnica,
    // e non va mostrata come se lo fosse.
    final hasRealDescription =
        description.isNotEmpty && description != 'Custom exercise';
    return Text(
      hasRealDescription ? description : loc.t('exercise_no_description'),
      style: t.typography.paragraph?.copyWith(
        color: hasRealDescription ? scheme.onSurface : scheme.onSurfaceVariant,
      ),
    );
  }
  Widget _buildHistory(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ImmersivoTokens t,
    List<WorkoutSession> sessions,
  ) {
    final matching = sessions
        .where(
          (s) => s.exercises.any((e) => e.exerciseId == widget.exercise.id),
        )
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    if (matching.isEmpty) {
      return Text(
        loc.t('exercise_no_history_body'),
        style: t.typography.paragraph?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final session in matching)
          _buildHistoryEntry(context, loc, theme, scheme, t, session),
      ],
    );
  }
  Widget _buildHistoryEntry(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ImmersivoTokens t,
    WorkoutSession session,
  ) {
    final exerciseData = ExerciseProgression.getLastExerciseData(
      session: session,
      exerciseId: widget.exercise.id,
    );
    if (exerciseData == null) return const SizedBox.shrink();
    final formattedDate = DateFormat('dd/MM/yyyy').format(session.startTime);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.workoutName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: t.spacing.xs),
            ...exerciseData.sets.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final set = entry.value;
              final weightStr = set.weight % 1 == 0
                  ? set.weight.toInt().toString()
                  : set.weight.toStringAsFixed(1);
              return Padding(
                padding: EdgeInsets.symmetric(vertical: t.spacing.xs / 2),
                child: Row(
                  children: [
                    Text(
                      '${loc.t('exercise_set_label')} $index',
                      style: t.typography.eyebrow?.copyWith(
                        color: set.isCompleted
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: t.spacing.md),
                    Text(
                      '$weightStr kg × ${set.reps}',
                      style: t.typography.metricSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      set.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: t.sizing.iconSm,
                      color: set.isCompleted
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  Widget _buildRecord(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ImmersivoTokens t,
    dynamic personalBest,
  ) {
    if (personalBest == null) {
      return Text(
        loc.t('exercise_no_history_body'),
        style: t.typography.paragraph?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    final formattedDate = DateFormat('dd/MM/yyyy').format(personalBest.date);
    final weightStr = personalBest.weight % 1 == 0
        ? personalBest.weight.toInt().toString()
        : personalBest.weight.toStringAsFixed(1);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(t.spacing.sm),
          color: scheme.secondary,
          child: Icon(
            Icons.emoji_events,
            color: scheme.onSecondary,
            size: t.sizing.iconLg,
          ),
        ),
        SizedBox(width: t.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$weightStr kg',
                    style: t.typography.metricLarge?.copyWith(
                      color: scheme.secondary,
                    ),
                  ),
                  SizedBox(width: t.spacing.xs),
                  Text(
                    '× ${personalBest.reps}',
                    style: t.typography.metricMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: t.spacing.xs),
              Text(
                '${loc.t('on_date')} $formattedDate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildStatTrio(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ImmersivoTokens t,
    List<WorkoutSession> sessions,
    dynamic personalBest,
  ) {
    final maxWeightStr = personalBest == null
        ? '—'
        : (personalBest.weight % 1 == 0
            ? personalBest.weight.toInt().toString()
            : personalBest.weight.toStringAsFixed(1));
    final volume = _totalVolumeFor(sessions, widget.exercise.id);
    final sessionCount = _sessionCountFor(sessions, widget.exercise.id);
    final stats = [
      (loc.t('exercise_stat_max'), '$maxWeightStr kg', scheme.secondary),
      (loc.t('exercise_stat_volume'), '$volume kg', scheme.onSurface),
      (loc.t('exercise_stat_sessions'), '$sessionCount', scheme.onSurface),
    ];
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
                      SizedBox(height: t.spacing.xs),
                      Text(
                        stats[i].$2,
                        style: t.typography.metricMedium?.copyWith(
                          fontSize: _kStatFontSize,
                          color: stats[i].$3,
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
  Widget _buildEmptyHistoryCard(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ImmersivoTokens t,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: t.sizing.iconLg,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: t.spacing.sm),
          Text(
            loc.t('exercise_no_history_title'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: t.spacing.xs),
          Text(
            loc.t('exercise_no_history_body'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildChartCard(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ImmersivoTokens t,
    List<ProgressionPoint> points,
  ) {
    return Container(
      height: _kChartHeight,
      width: double.infinity,
      padding: EdgeInsets.only(
        left: t.spacing.sm,
        right: t.spacing.md,
        top: t.spacing.md,
        bottom: t.spacing.sm,
      ),
      decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
      child: LineChart(_buildChartData(context, scheme, points)),
    );
  }
  LineChartData _buildChartData(
    BuildContext context,
    ColorScheme scheme,
    List<ProgressionPoint> points,
  ) {
    final theme = Theme.of(context);
    final t = context.immersivo;
    final spots = points.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        e.value.weight,
      );
    }).toList();
    final weights = points.map((p) => p.weight).toList();
    final minY = weights.reduce((a, b) => a < b ? a : b);
    final maxY = weights.reduce((a, b) => a > b ? a : b);
    final rangeY = maxY - minY;
    final paddingY = rangeY == 0 ? (minY == 0 ? 5.0 : minY * 0.1) : rangeY * 0.15;
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: scheme.outline.withValues(alpha: 0.15),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} kg',
                // `labelSmall` e il ruolo piu piccolo del tema: le etichette
                // di un asse sono piccole per natura, e il design system non
                // ha una misura sotto `metricSmall`.
                //
                // Le cifre tabulari si aggiungono qui con lo stesso meccanismo
                // che `ImmersivoTypography` usa per gli stili `metric*`:
                // senza, i numeri dell'asse ballano da un valore all'altro. Il
                // font monospaziato scritto a mano non serve — le cifre
                // tabulari fanno la stessa cosa sul carattere del tema.
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: points.length > 5 ? (points.length / 4).ceilToDouble() : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              final date = points[index].date;
              return Padding(
                padding: EdgeInsets.only(top: t.spacing.sm),
                child: Text(
                  DateFormat('dd/MM').format(date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minY: (minY - paddingY).clamp(0, double.infinity),
      maxY: maxY + paddingY,
      minX: 0,
      maxX: (points.length - 1).toDouble().clamp(0, double.infinity),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: points.length > 2,
          color: scheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) => true,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.25),
                scheme.primary.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => scheme.surfaceContainerHighest,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= points.length) return null;
              final point = points[index];
              final dateStr = DateFormat('dd/MM/yyyy').format(point.date);
              final weightStr = point.weight % 1 == 0
                  ? point.weight.toInt().toString()
                  : point.weight.toStringAsFixed(1);
              return LineTooltipItem(
                '$dateStr\n$weightStr kg × ${point.reps}',
                t.typography.metricSmall?.copyWith(color: scheme.onSurface) ??
                    TextStyle(color: scheme.onSurface),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
/// Fila di segmenti a larghezza uguale, divisa da un filetto: sostituisce sia
/// le tre schede tecnica/storico/record sia il selettore di periodo del
/// grafico, che nel mockup sono lo stesso controllo ripetuto due volte.
class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final value in values)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(value),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == selected ? scheme.primary : Colors.transparent,
                  border: Border(
                    top: BorderSide(color: scheme.outline),
                    bottom: BorderSide(color: scheme.outline),
                  ),
                ),
                child: Text(
                  labelOf(value).toUpperCase(),
                  style: t.typography.eyebrow?.copyWith(
                    color: value == selected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
/// Pulsante quadrato sopra la foto di testata: sfondo scuro semitrasparente,
/// o pieno per l'azione con enfasi (il video).
class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlighted;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: _kIconBoxSide,
          height: _kIconBoxSide,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted
                ? scheme.primary
                : scheme.scrim.withValues(alpha: 0.5),
            border: highlighted ? null : Border.all(color: scheme.outline),
          ),
          child: Icon(
            icon,
            size: t.sizing.iconMd,
            color: highlighted ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
/// Volume totale sollevato per questo esercizio in tutte le sessioni, in kg:
/// stessa formula di `StatisticsHelper.calculateTotalVolume`, filtrata a un
/// solo esercizio invece che all'intera sessione.
int _totalVolumeFor(List<WorkoutSession> sessions, String exerciseId) {
  double volume = 0;
  for (final session in sessions) {
    for (final exercise in session.exercises) {
      if (exercise.exerciseId != exerciseId) continue;
      for (final set in exercise.sets) {
        if (set.isCompleted && set.weight > 0 && set.reps > 0) {
          volume += set.weight * set.reps;
        }
      }
    }
  }
  return volume.round();
}
/// Numero di sessioni in cui questo esercizio ha almeno una serie completata.
int _sessionCountFor(List<WorkoutSession> sessions, String exerciseId) {
  return sessions.where((session) {
    return session.exercises.any(
      (exercise) =>
          exercise.exerciseId == exerciseId &&
          exercise.sets.any(
            (set) => set.isCompleted && set.weight > 0 && set.reps > 0,
          ),
    );
  }).length;
}
