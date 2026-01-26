import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/health_service.dart';

class HealthDetailScreen extends StatefulWidget {
  final HealthDataType dataType;
  final String title;
  final Color baseColor;
  final String unit;

  const HealthDetailScreen({
    Key? key,
    required this.dataType,
    required this.title,
    required this.baseColor,
    required this.unit,
  }) : super(key: key);

  @override
  State<HealthDetailScreen> createState() => _HealthDetailScreenState();
}

class _HealthDetailScreenState extends State<HealthDetailScreen> {
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
    int daysCount = _isWeekly
        ? 7
        : (DateTime(_currentDate.year, _currentDate.month + 1, 0).day);

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Period Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildPeriodTab('Week', _isWeekly),
                _buildPeriodTab('Month', !_isWeekly),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date Navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changePeriod(-1),
                ),
                Text(
                  _getDateRangeLabel(),
                  style: const TextStyle(
                    fontSize: 16,
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
                      : null, // Disable if current
                ),
              ],
            ),
          ),

          // Stats Summary
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('Total / Average', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  _calculateSummary(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: widget.baseColor,
                  ),
                ),
                Text(
                  widget.unit,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          ),

          // Chart
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildChart(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelected) return;
          setState(() {
            _isWeekly = text == 'Week';
            // Reset date to now on switch? Or keep context?
            // Resetting to latest is usually better UX
            _currentDate = DateTime.now();
          });
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  String _getDateRangeLabel() {
    final dateFormat = DateFormat('MMM d');
    if (_isWeekly) {
      final end = _currentDate;
      final start = end.subtract(const Duration(days: 6));
      return '${dateFormat.format(start)} - ${dateFormat.format(end)}';
    } else {
      return DateFormat('MMMM y').format(_currentDate);
    }
  }

  String _calculateSummary() {
    if (_data.isEmpty) return '0';
    double total = 0;
    _data.values.forEach((v) => total += v);

    // For heart rate or weight, we likely want Average
    if (widget.dataType == HealthDataType.HEART_RATE ||
        widget.dataType == HealthDataType.WEIGHT) {
      return (total / _data.length).toStringAsFixed(1);
    }

    // For others (Steps, Distance, Calories, Sleep, Water) Sum is better?
    // Wait, sleep usually "Avg 7h" is better than "Total 50h".
    // Activity usually "Total 10k steps".
    // Let's decide based on type.

    if (widget.dataType == HealthDataType.SLEEP_SESSION) {
      // Total minutes -> Hours
      return (total / 60).toStringAsFixed(1) + " h (Total)";
    }

    // Default sum
    if (total > 1000 && widget.dataType == HealthDataType.STEPS) {
      return '${(total / 1000).toStringAsFixed(1)}k';
    }

    return total.toInt().toString();
  }

  Widget _buildChart() {
    if (_data.isEmpty) return Center(child: Text('No Data'));

    // Check if we use Bar or Line
    // Usually Steps/Calories -> Bar
    // Heart Rate/Weight -> Line
    bool useBar =
        widget.dataType == HealthDataType.STEPS ||
        widget.dataType == HealthDataType.ACTIVE_ENERGY_BURNED ||
        widget.dataType == HealthDataType.WATER ||
        widget.dataType == HealthDataType.DISTANCE_DELTA ||
        widget.dataType == HealthDataType.SLEEP_SESSION;

    if (useBar) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              _data.values.reduce((curr, next) => curr > next ? curr : next) *
              1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String date = DateFormat(
                  'EEE',
                ).format(_data.keys.elementAt(group.x.toInt()));
                if (!_isWeekly)
                  date = DateFormat(
                    'd',
                  ).format(_data.keys.elementAt(group.x.toInt()));
                return BarTooltipItem(
                  '$date\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: rod.toY.toInt().toString(),
                      style: TextStyle(color: widget.baseColor, fontSize: 12),
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
                  if (index < 0 || index >= _data.length)
                    return const SizedBox.shrink();
                  final date = _data.keys.elementAt(index);

                  if (_isWeekly) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('EEE').format(date).substring(0, 1),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  } else {
                    // Show every 5th day
                    if (date.day % 5 == 0 || date.day == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }
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
                  width: _isWeekly ? 16 : 6,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY:
                        _data.values.reduce(
                          (curr, next) => curr > next ? curr : next,
                        ) *
                        1.2,
                    color: Colors.grey[100],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    } else {
      // Line Chart for Heart Rate / Weight
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
                  if (index < 0 || index >= _data.length)
                    return const SizedBox.shrink();
                  final date = _data.keys.elementAt(index);

                  if (_isWeekly) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('EEE').format(date).substring(0, 1),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  } else {
                    if (date.day % 5 == 0 || date.day == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }
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
              0.9, // Start y-axis near min value
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
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: widget.baseColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: widget.baseColor.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = _data.keys.elementAt(spot.x.toInt());
                  return LineTooltipItem(
                    '${DateFormat('MM/dd').format(date)}\n${spot.y.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
