import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/theme/expressive_tokens.dart';
import '../../../models/session.dart';
import '../expressive_segmented_control.dart';

class ActivityChart extends ConsumerStatefulWidget {
  final List<WorkoutSession> sessions;

  const ActivityChart({super.key, required this.sessions});

  @override
  ConsumerState<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends ConsumerState<ActivityChart> {
  // 0 = Week, 1 = Month
  int _viewMode = 0;

  // Cached data
  late Map<int, int> _weeklyData; // Day 1-7 (Mon-Sun)
  late Map<int, int> _monthlyData; // Day 1-31

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(covariant ActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessions != widget.sessions) {
      _processData();
    }
  }

  void _processData() {
    final now = DateTime.now();

    // Initialize maps
    _weeklyData = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    _monthlyData = {};
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    for (int i = 1; i <= daysInMonth; i++) {
      _monthlyData[i] = 0;
    }

    // Filter and Count
    for (var session in widget.sessions) {
      // Weekly Logic: Current Week
      // We need to check if the session is in the current week (Mon-Sun window relative to now? Or strictly this calendar week?)
      // Let's do Calendar Week.
      final sessionDate = session.startTime;

      // Calculate start of current week (Monday)
      final currentWeekday = now.weekday;
      final startOfWeek = now.subtract(Duration(days: currentWeekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Normalize to Date only for comparison
      final dateOnly = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
      );
      final startOfWeekDate = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final endOfWeekDate = DateTime(
        endOfWeek.year,
        endOfWeek.month,
        endOfWeek.day,
      );

      // Check Week
      if (dateOnly.isAfter(startOfWeekDate.subtract(const Duration(days: 1))) &&
          dateOnly.isBefore(endOfWeekDate.add(const Duration(days: 1)))) {
        _weeklyData[sessionDate.weekday] =
            (_weeklyData[sessionDate.weekday] ?? 0) + 1;
      }

      // Check Month
      if (sessionDate.year == now.year && sessionDate.month == now.month) {
        _monthlyData[sessionDate.day] =
            (_monthlyData[sessionDate.day] ?? 0) + 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    return Column(
      children: [
        ExpressiveSegmentedControl(
          labels: [loc.t('week_tab'), loc.t('month_tab')],
          selectedIndex: _viewMode,
          onChanged: (i) => setState(() => _viewMode = i),
        ),
        SizedBox(height: context.expressive.spacing.md),
        Expanded(
          child: _viewMode == 0
              ? _buildBarChart(_weeklyData, loc)
              : _buildMonthlyHeatmap(_monthlyData, loc),
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<int, int> data, Localization loc) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.expressive;
    final testoAsse = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
    );

    int maxY = 0;
    data.forEach((_, count) {
      if (count > maxY) maxY = count;
    });
    maxY = (maxY < 4) ? 4 : maxY + 1; // Altezza minima della scala.

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toInt().toString(),
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                    ) ??
                    TextStyle(color: scheme.onInverseSurface),
                children: [
                  TextSpan(
                    text: '\n${_getWeekdayName(group.x.toInt(), loc)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onInverseSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: EdgeInsets.only(top: t.spacing.sm),
                  child: Text(_getWeekdayName(value.toInt(), loc), style: testoAsse),
                );
              },
              reservedSize: t.spacing.xxl,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.onSurface.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(data, scheme),
      ),
    );
  }

  Widget _buildMonthlyHeatmap(Map<int, int> data, Localization loc) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.expressive;
    final lingua = loc.locale.languageCode;

    int maxVal = 1;
    data.forEach((_, count) {
      if (count > maxVal) maxVal = count;
    });

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final offset = firstDayOfMonth.weekday - 1;
    final totalCells = daysInMonth + offset;

    // Le iniziali dei sette giorni, nella lingua scelta: lunedi e il giorno 1
    // di un lunedi vero (8 gennaio 2024), non una lettera scritta a mano —
    // «M T W T F S S» presume l'inglese, e in italiano «giovedi» e «venerdi»
    // cominciano con la stessa lettera di «giovedi» in inglese non lo fa.
    final iniziali = List.generate(7, (i) {
      final giorno = DateTime(2024, 1, 8 + i);
      return DateFormat('EEE', lingua).format(giorno)[0].toUpperCase();
    });

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: iniziali
              .map(
                (e) => SizedBox(
                  width: t.sizing.thumbnailSm - t.spacing.sm,
                  child: Text(
                    e,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: t.spacing.sm),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: t.spacing.sm,
              crossAxisSpacing: t.spacing.sm,
              childAspectRatio: 1,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();

              final day = index - offset + 1;
              final count = data[day] ?? 0;
              final isFuture = day > now.day;

              if (isFuture) {
                return Container(
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.04),
                    borderRadius: t.shape.cornerXs,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                );
              }

              Color colore;
              Color coloreTesto;

              if (count == 0) {
                colore = scheme.onSurface.withValues(alpha: 0.08);
                coloreTesto = scheme.onSurfaceVariant;
              } else {
                final opacita = 0.5 + (0.5 * (count / maxVal));
                colore = scheme.primary.withValues(alpha: opacita);
                coloreTesto = scheme.onPrimary;
              }

              final isToday = day == now.day;
              final dataGiorno = DateTime(now.year, now.month, day);

              return Tooltip(
                message: loc
                    .t('activity_heatmap_tooltip')
                    .replaceFirst(
                      '%s',
                      DateFormat('MMM d', lingua).format(dataGiorno),
                    )
                    .replaceFirst('%s', '$count'),
                child: Container(
                  decoration: BoxDecoration(
                    color: colore,
                    borderRadius: t.shape.cornerXs,
                    border: isToday
                        ? Border.all(color: scheme.primary, width: 2)
                        : null,
                    boxShadow: count > 0
                        ? t.elevation.level1(colore)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: coloreTesto,
                      fontWeight: count > 0 || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<int, int> data, ColorScheme scheme) {
    final t = context.expressive;
    final List<BarChartGroupData> items = [];
    final sortedKeys = data.keys.toList()..sort();

    for (var key in sortedKeys) {
      items.add(
        BarChartGroupData(
          x: key,
          barRods: [
            BarChartRodData(
              toY: data[key]!.toDouble(),
              // Un solo colore e non un gradiente indaco/ciano che non stava
              // nella palette: l'ambra e cio che significa «un dato che
              // conta», qui la quantita di allenamenti in un giorno.
              color: scheme.primary,
              width: 16.0,
              borderRadius: t.shape.cornerXs,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 0,
                color: scheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
      );
    }
    return items;
  }

  /// Il nome breve del giorno, nella lingua scelta dentro l'app.
  ///
  /// `DateFormat('EEE', lingua)` e non uno `switch` scritto a mano: il
  /// progetto ha due lingue, e un giorno la terza non deve tornare qui a
  /// scrivere un altro `case`. L'8 gennaio 2024 e un lunedi vero: `dayIndex`
  /// arriva da `DateTime.weekday` (1=lunedi..7=domenica), e la data di
  /// riferimento segue la stessa numerazione.
  String _getWeekdayName(int dayIndex, Localization loc) {
    if (dayIndex < 1 || dayIndex > 7) return '';
    final giorno = DateTime(2024, 1, 7 + dayIndex);
    return DateFormat('EEE', loc.locale.languageCode).format(giorno);
  }
}
