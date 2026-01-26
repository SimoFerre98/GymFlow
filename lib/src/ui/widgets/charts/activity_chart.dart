import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/session.dart';

class ActivityChart extends StatefulWidget {
  final List<WorkoutSession> sessions;

  const ActivityChart({super.key, required this.sessions});

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
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
    return Column(
      children: [
        // Toggle Control
        Container(
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleOption('Week', 0),
              _buildToggleOption('Month', 1),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chart
        Expanded(
          child: _viewMode == 0
              ? _buildChart(_weeklyData, isMonthly: false)
              : _buildChart(_monthlyData, isMonthly: true),
        ),
      ],
    );
  }

  Widget _buildToggleOption(String text, int mode) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(Map<int, int> data, {required bool isMonthly}) {
    // Determine Max Y
    int maxY = 0;
    data.forEach((_, count) {
      if (count > maxY) maxY = count;
    });
    maxY = (maxY < 4) ? 4 : maxY + 1; // Minimum scale height

    return BarChart(
      BarChartData(
        alignment: isMonthly
            ? BarChartAlignment.center
            : BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toInt().toString(),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text:
                        '\n${isMonthly ? 'Day ${group.x}' : _getWeekdayName(group.x)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                      fontSize: 10,
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
                if (isMonthly) {
                  // Only show titles every 5 days for Month view to avoid clutter
                  if (value.toInt() % 5 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _getWeekdayName(value.toInt()),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
              },
              reservedSize: 30,
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
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(data, isMonthly),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<int, int> data, bool isMonthly) {
    final List<BarChartGroupData> items = [];
    final sortedKeys = data.keys.toList()..sort();

    for (var key in sortedKeys) {
      items.add(
        BarChartGroupData(
          x: key,
          barRods: [
            BarChartRodData(
              toY: data[key]!.toDouble(),
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.cyanAccent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: isMonthly ? 6 : 16, // Thinner bars for monthly
              borderRadius: BorderRadius.circular(isMonthly ? 2 : 6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 0, // Could set max here for full background bar
                color: Colors.grey.withOpacity(0.05),
              ),
            ),
          ],
        ),
      );
    }
    return items;
  }

  String _getWeekdayName(int dayIndex) {
    switch (dayIndex) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
