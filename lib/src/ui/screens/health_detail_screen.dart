import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:health/health.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/health_service.dart';
import '../../core/theme/expressive_tokens.dart';
import '../widgets/back_pill.dart';
import '../widgets/expressive_card.dart';
import '../widgets/expressive_segmented_control.dart';

class HealthDetailScreen extends ConsumerStatefulWidget {
  final HealthDataType dataType;
  final String title;
  final Color baseColor;
  final String unit;

  const HealthDetailScreen({
    super.key,
    required this.dataType,
    required this.title,
    required this.baseColor,
    required this.unit,
  });

  @override
  ConsumerState<HealthDetailScreen> createState() => _HealthDetailScreenState();
}

class _HealthDetailScreenState extends ConsumerState<HealthDetailScreen> {
  bool _isWeekly = true; // true = Week, false = Month
  DateTime _currentDate = DateTime.now();
  Map<DateTime, double> _data = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);

    DateTime start, end;
    if (_isWeekly) {
      // End is _currentDate (or today)
      // Start is 6 days before
      end = _currentDate;
      start = end.subtract(const Duration(days: 6));
    } else {
      // Month view
      // Start is 1st of month, End is last of month
      start = DateTime(_currentDate.year, _currentDate.month, 1);
      end = DateTime(
        _currentDate.year,
        _currentDate.month + 1,
        0,
      ); // Last day of month
    }

    // Ensure we don't fetch into the future if _currentDate is today
    if (end.isAfter(DateTime.now())) {
      end = DateTime.now();
    }

    final data = await HealthService().fetchHistoricalData(
      widget.dataType,
      start,
      end,
    );

    // Fill in missing dates with 0 (or null if line chart needs it, but 0 is usually safer for steps)
    // For heart rate maybe we don't want 0?
    // Let's iterate and fill
    Map<DateTime, double> fullData = {};

    if (_isWeekly) {
      for (int i = 0; i < 7; i++) {
        DateTime d = end.subtract(Duration(days: i));
        d = DateTime(d.year, d.month, d.day);
        // Find matching in data (dates in data should be normalized to midnight)
        // We'll normalize keys in data map when we get it
        fullData[d] = data[d] ?? 0.0;
      }
    } else {
      // Loop from day 1 to end day
      int daysInMonth = DateTime(
        _currentDate.year,
        _currentDate.month + 1,
        0,
      ).day;
      for (int i = 1; i <= daysInMonth; i++) {
        DateTime d = DateTime(_currentDate.year, _currentDate.month, i);
        if (d.isAfter(DateTime.now())) break;
        fullData[d] = data[d] ?? 0.0;
      }
    }

    // Sort by date
    var sortedKeys = fullData.keys.toList()..sort((a, b) => a.compareTo(b));
    Map<DateTime, double> sortedData = {
      for (var k in sortedKeys) k: fullData[k]!,
    };

    if (mounted) {
      setState(() {
        _data = sortedData;
        _isLoading = false;
      });
    }
  }

  void _changePeriod(int offset) {
    setState(() {
      if (_isWeekly) {
        _currentDate = _currentDate.add(Duration(days: offset * 7));
      } else {
        _currentDate = DateTime(
          _currentDate.year,
          _currentDate.month + offset,
          1,
        );
        // If moved to next month, maybe pick end of that month? Or keep 1st?
        // Usually moving months implies "Show me specific month".
        // Logic above uses _currentDate as anchor.
        // If month is current month, we clamp to Now.
        // If past month, we show full month.
      }

      // Prevent future navigation beyond today
      if (_currentDate.isAfter(DateTime.now())) {
        _currentDate = DateTime.now();
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: BackPill(label: loc.t('statistics_title')),
        leadingWidth: BackPill.leadingWidth,
      ),
      body: Column(
        children: [
          SizedBox(height: t.spacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spacing.xl),
            child: ExpressiveSegmentedControl(
              labels: [loc.t('week_tab'), loc.t('month_tab')],
              selectedIndex: _isWeekly ? 0 : 1,
              onChanged: (i) {
                setState(() {
                  _isWeekly = i == 0;
                  // Si torna a oggi cambiando modalita: restare sull'ultimo
                  // giorno del mese visto mentre si passa alla settimana non
                  // avrebbe senso per l'utente.
                  _currentDate = DateTime.now();
                });
                _loadData();
              },
            ),
          ),
          SizedBox(height: t.spacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changePeriod(-1),
                ),
                Text(
                  _getDateRangeLabel(loc),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _currentDate.isBefore(
                        DateTime.now().subtract(const Duration(days: 1)),
                      )
                      ? () => _changePeriod(1)
                      : null, // Disattivato se e gia oggi.
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.spacing.xl),
            child: ExpressiveCard(
              child: Column(
                children: [
                  Text(
                    loc.t('total_average'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: t.spacing.sm),
                  Text(
                    _calculateSummary(loc),
                    style: t.typography.metricLarge?.copyWith(
                      color: widget.baseColor,
                    ),
                  ),
                  Text(
                    widget.unit,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                t.spacing.xl,
                0,
                t.spacing.xl,
                t.spacing.xxl,
              ),
              child: ExpressiveCard(
                child: SizedBox(
                  height: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildChart(loc),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // `loc.locale.languageCode` e non l'omissione che c'era: senza, `DateFormat`
  // usa la lingua **del telefono**, che puo differire da quella scelta
  // dentro l'app — e allora meta pagina si legge in una lingua e l'asse del
  // grafico in un'altra.
  String _getDateRangeLabel(Localization loc) {
    final lingua = loc.locale.languageCode;
    final dateFormat = DateFormat('MMM d', lingua);
    if (_isWeekly) {
      final end = _currentDate;
      final start = end.subtract(const Duration(days: 6));
      return '${dateFormat.format(start)} - ${dateFormat.format(end)}';
    } else {
      return DateFormat('MMMM y', lingua).format(_currentDate);
    }
  }

  String _calculateSummary(Localization loc) {
    if (_data.isEmpty) return '0';
    double total = 0;
    for (var v in _data.values) {
      total += v;
    }

    // Battito e peso: la media ha senso, la somma di sette giorni di battito
    // no.
    if (widget.dataType == HealthDataType.HEART_RATE ||
        widget.dataType == HealthDataType.WEIGHT) {
      return (total / _data.length).toStringAsFixed(1);
    }

    if (widget.dataType == HealthDataType.SLEEP_SESSION) {
      final ore = (total / 60).toStringAsFixed(1);
      return loc.t('health_total_hours').replaceFirst('%s', ore);
    }

    if (total > 1000 && widget.dataType == HealthDataType.STEPS) {
      return '${(total / 1000).toStringAsFixed(1)}k';
    }

    return total.toInt().toString();
  }

  Widget _buildChart(Localization loc) {
    if (_data.isEmpty) return Center(child: Text(loc.t('no_data')));

    final scheme = Theme.of(context).colorScheme;
    final testoAsse = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final lingua = loc.locale.languageCode;

    // Steps/Calories/Water/Distance/Sleep sono conteggi del giorno: una
    // barra. Battito/peso sono un valore che varia con continuita: una linea.
    bool useBar =
        widget.dataType == HealthDataType.STEPS ||
        widget.dataType == HealthDataType.ACTIVE_ENERGY_BURNED ||
        widget.dataType == HealthDataType.WATER ||
        widget.dataType == HealthDataType.DISTANCE_DELTA ||
        widget.dataType == HealthDataType.SLEEP_SESSION;

    Widget etichettaAsse(DateTime date) {
      if (_isWeekly) {
        return Padding(
          padding: EdgeInsets.only(top: context.expressive.spacing.sm),
          child: Text(
            DateFormat('EEE', lingua).format(date).substring(0, 1),
            style: testoAsse,
          ),
        );
      }
      if (date.day % 5 == 0 || date.day == 1) {
        return Padding(
          padding: EdgeInsets.only(top: context.expressive.spacing.sm),
          child: Text('${date.day}', style: testoAsse),
        );
      }
      return const SizedBox.shrink();
    }

    if (useBar) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              _data.values.reduce((curr, next) => curr > next ? curr : next) *
              1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String date = DateFormat(
                  'EEE',
                  lingua,
                ).format(_data.keys.elementAt(group.x.toInt()));
                if (!_isWeekly) {
                  date = DateFormat(
                    'd',
                    lingua,
                  ).format(_data.keys.elementAt(group.x.toInt()));
                }
                return BarTooltipItem(
                  '$date\n',
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onInverseSurface,
                        fontWeight: FontWeight.bold,
                      ) ??
                      TextStyle(color: scheme.onInverseSurface),
                  children: [
                    TextSpan(
                      text: rod.toY.toInt().toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: widget.baseColor,
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
                  int index = value.toInt();
                  if (index < 0 || index >= _data.length) {
                    return const SizedBox.shrink();
                  }
                  return etichettaAsse(_data.keys.elementAt(index));
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _data.entries.mapIndexed((index, entry) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: widget.baseColor,
                  width: _isWeekly
                      ? context.expressive.sizing.iconLg
                      : context.expressive.spacing.sm,
                  borderRadius: context.expressive.shape.cornerXs,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY:
                        _data.values.reduce(
                          (curr, next) => curr > next ? curr : next,
                        ) *
                        1.2,
                    color: scheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    } else {
      return LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= _data.length) {
                    return const SizedBox.shrink();
                  }
                  return etichettaAsse(_data.keys.elementAt(index));
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (_data.length - 1).toDouble(),
          minY:
              _data.values.reduce((curr, next) => curr < next ? curr : next) *
              0.9,
          lineBarsData: [
            LineChartBarData(
              spots: _data.entries.mapIndexed((index, entry) {
                return FlSpot(index.toDouble(), entry.value);
              }).toList(),
              isCurved: true,
              color: widget.baseColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: scheme.surface,
                    strokeWidth: 2,
                    strokeColor: widget.baseColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: widget.baseColor.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = _data.keys.elementAt(spot.x.toInt());
                  return LineTooltipItem(
                    '${DateFormat('MM/dd', lingua).format(date)}\n${spot.y.toInt()}',
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                        ) ??
                        TextStyle(color: scheme.onInverseSurface),
                  );
                }).toList();
              },
            ),
          ),
        ),
      );
    }
  }
}

// Helper to get index
extension IterableExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) sync* {
    var index = 0;
    for (final element in this) {
      yield f(index, element);
      index++;
    }
  }
}
