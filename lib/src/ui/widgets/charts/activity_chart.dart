import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ActivityChart extends StatelessWidget {
  final Map<int, int> weeklyData; // Map<DayIndex, Count>

  const ActivityChart({Key? key, required this.weeklyData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find the max value to scale graph efficiently, assume at least 4 for visual spacing
    int maxY = 4;
    for (var count in weeklyData.values) {
      if (count > maxY) maxY = count;
    }
    // Add a bit of buffer
    maxY = maxY + 1;

    return AspectRatio(
      aspectRatio: 1.7, // Wide aspect ratio
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY.toDouble(),
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  rod.toY.round().toString(),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
                  const style = TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 1:
                      text = 'Mon';
                      break;
                    case 2:
                      text = 'Tue';
                      break;
                    case 3:
                      text = 'Wed';
                      break;
                    case 4:
                      text = 'Thu';
                      break;
                    case 5:
                      text = 'Fri';
                      break;
                    case 6:
                      text = 'Sat';
                      break;
                    case 7:
                      text = 'Sun';
                      break;
                    default:
                      text = '';
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(text, style: style),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ), // Hide left axis numbers for cleaner look
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1, // Grid line every 1 unit
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    List<BarChartGroupData> groups = [];
    for (int day = 1; day <= 7; day++) {
      final count = weeklyData[day] ?? 0;
      groups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 0, // In case we want a background bar, set its max
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ],
          showingTooltipIndicators: count > 0
              ? [0]
              : [], // Show tooltip only if count > 0? optional
        ),
      );
    }
    return groups;
  }
}
