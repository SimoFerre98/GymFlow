import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:gymflow/src/core/providers/dashboard_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/providers/personal_best_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/core/utils/exercise_progression.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
import 'package:gymflow/src/ui/widgets/exercise_image.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  ProgressionPeriod _selectedPeriod = ProgressionPeriod.all;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = ref.watch(localizationNotifierProvider);

    final sessionsAsync = ref.watch(dashboardSessionsProvider);
    final sessions = sessionsAsync.value ?? [];

    final personalBests = ref.watch(personalBestsProvider);
    final personalBest = personalBests[widget.exercise.id];

    final progressionPoints = ExerciseProgression.calculateProgressionPoints(
      sessions: sessions,
      exerciseId: widget.exercise.id,
      period: _selectedPeriod,
    );

    final lastSession = ExerciseProgression.getLastSession(
      sessions: sessions,
      exerciseId: widget.exercise.id,
    );

    final lastExercise = lastSession != null
        ? ExerciseProgression.getLastExerciseData(
            session: lastSession,
            exerciseId: widget.exercise.id,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        leading: BackPill(label: loc.t('exercises_menu')),
        leadingWidth: BackPill.leadingWidth,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: t.spacing.md,
          right: t.spacing.md,
          top: t.spacing.sm,
          bottom: t.spacing.bottomInset + t.spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card con miniatura e dettagli
            _buildHeaderCard(context, loc, theme, scheme, t),

            SizedBox(height: t.spacing.md),

            // Record Personale (se presente)
            if (personalBest != null) ...[
              _buildPersonalBestCard(context, loc, theme, scheme, t, personalBest),
              SizedBox(height: t.spacing.md),
            ],

            // Sezione Grafico Progressioni
            _buildProgressionSection(
              context,
              loc,
              theme,
              scheme,
              t,
              progressionPoints,
            ),

            SizedBox(height: t.spacing.md),

            // Sezione Ultima Sessione
            if (lastSession != null && lastExercise != null) ...[
              _buildLastSessionCard(
                context,
                loc,
                theme,
                scheme,
                t,
                lastSession,
                lastExercise,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ExpressiveTokens t,
  ) {
    final subtitleParts = <String>[];
    if (widget.exercise.musclesTargeted.isNotEmpty) {
      subtitleParts.add(widget.exercise.musclesTargeted.join(' · '));
    }
    if (widget.exercise.isCustom) {
      subtitleParts.add(loc.t('exercise_tag_yours'));
    }

    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: t.shape.cornerLg,
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: t.sizing.thumbnailMd,
            child: ExerciseImage(
              exercise: widget.exercise,
            ),
          ),
          SizedBox(width: t.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exercise.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  SizedBox(height: t.spacing.xs),
                  Text(
                    subtitleParts.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => ExerciseVideoSheet.show(context, widget.exercise),
            icon: Icon(
              Icons.play_circle_outline,
              color: scheme.primary,
            ),
            tooltip: loc.t('video_available'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestCard(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ExpressiveTokens t,
    dynamic personalBest,
  ) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(personalBest.date);
    final weightStr = personalBest.weight % 1 == 0
        ? personalBest.weight.toInt().toString()
        : personalBest.weight.toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: t.shape.cornerLg,
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(t.spacing.sm),
            decoration: ShapeDecoration(
              color: scheme.primary.withValues(alpha: 0.15),
              shape: const CircleBorder(),
            ),
            child: Icon(
              Icons.emoji_events,
              color: scheme.primary,
              size: 28,
            ),
          ),
          SizedBox(width: t.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('exercise_personal_best_title'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: t.spacing.xs / 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$weightStr kg',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: scheme.primary,
                      ),
                    ),
                    SizedBox(width: t.spacing.xs),
                    Text(
                      '× ${personalBest.reps}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: t.spacing.xs / 2),
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
      ),
    );
  }

  Widget _buildProgressionSection(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ExpressiveTokens t,
    List<ProgressionPoint> points,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.t('exercise_progression_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: t.spacing.sm),

        // Filtro Periodo (1 Mese, 3 Mesi, Tutto)
        Container(
          decoration: ShapeDecoration(
            color: scheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: t.shape.cornerFull,
            ),
          ),
          padding: EdgeInsets.all(t.spacing.xs),
          child: Row(
            children: ProgressionPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              final labelKey = switch (period) {
                ProgressionPeriod.oneMonth => 'exercise_period_1m',
                ProgressionPeriod.threeMonths => 'exercise_period_3m',
                ProgressionPeriod.all => 'exercise_period_all',
              };

              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedPeriod = period),
                  borderRadius: t.shape.cornerFull,
                  child: AnimatedContainer(
                    duration: t.motion.quick,
                    padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                    decoration: ShapeDecoration(
                      color: isSelected
                          ? scheme.primary
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: t.shape.cornerFull,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      loc.t(labelKey),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: t.spacing.md),

        // Grafico o messaggio di invito (senza storico vuoto)
        if (points.isEmpty)
          _buildEmptyHistoryCard(context, loc, theme, scheme, t)
        else
          _buildChartCard(context, loc, theme, scheme, t, points),
      ],
    );
  }

  Widget _buildEmptyHistoryCard(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ExpressiveTokens t,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(t.spacing.lg),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: t.shape.cornerLg,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
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
    ExpressiveTokens t,
    List<ProgressionPoint> points,
  ) {
    return Container(
      height: 240,
      width: double.infinity,
      padding: EdgeInsets.only(
        left: t.spacing.sm,
        right: t.spacing.md,
        top: t.spacing.md,
        bottom: t.spacing.sm,
      ),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: t.shape.cornerLg,
        ),
      ),
      child: LineChart(_buildChartData(context, scheme, points)),
    );
  }

  LineChartData _buildChartData(
    BuildContext context,
    ColorScheme scheme,
    List<ProgressionPoint> points,
  ) {
    final theme = Theme.of(context);
    final t = context.expressive;
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
                // che `ExpressiveTypography` usa per gli stili `metric*`:
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
                TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildLastSessionCard(
    BuildContext context,
    Localization loc,
    ThemeData theme,
    ColorScheme scheme,
    ExpressiveTokens t,
    dynamic lastSession,
    dynamic lastExercise,
  ) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(lastSession.startTime);

    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: t.shape.cornerLg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.t('exercise_last_session_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
          Text(
            lastSession.workoutName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: t.spacing.sm),
          Divider(color: scheme.outline.withValues(alpha: 0.2)),
          SizedBox(height: t.spacing.xs),
          ...lastExercise.sets.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final set = entry.value;
            final weightStr = set.weight % 1 == 0
                ? set.weight.toInt().toString()
                : set.weight.toStringAsFixed(1);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: t.spacing.xs / 2),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.spacing.sm,
                      vertical: t.spacing.xs / 2,
                    ),
                    decoration: ShapeDecoration(
                      color: set.isCompleted
                          ? scheme.primary.withValues(alpha: 0.15)
                          : scheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: t.shape.cornerSm,
                      ),
                    ),
                    child: Text(
                      '${loc.t('exercise_set_label')} $index',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: set.isCompleted
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Text(
                    '$weightStr kg × ${set.reps}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    set.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
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
    );
  }
}
