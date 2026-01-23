import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WorkoutTypePieChart extends StatelessWidget {
  final Map<String, int> data;

  const WorkoutTypePieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data yet')),
      );
    }

    final total = data.values.fold(0, (sum, val) => sum + val);

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: [
          const SizedBox(height: 18),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: _showingSections(data, total),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries.map((entry) {
              final color = _getColor(entry.key);
              final percentage = ((entry.value / total) * 100).toStringAsFixed(
                1,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key} ($percentage%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections(Map<String, int> data, int total) {
    return data.entries.map((entry) {
      final isTouched = false;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      final value = entry.value.toDouble();
      final percentage = (value / total) * 100;

      return PieChartSectionData(
        color: _getColor(entry.key),
        value: value,
        title: '${percentage.toInt()}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
      );
    }).toList();
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'strength':
        return Colors.blue;
      case 'cardio':
        return Colors.red;
      case 'hypertrophy':
        return Colors.purple;
      case 'flexibility':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
