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

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2, // Added space for 'cut' effect
              centerSpaceRadius: 40,
              sections: _showingSections(data, total),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: data.entries.map((entry) {
            final color = _getColor(entry.key);
            final percentage = ((entry.value / total) * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key} ($percentage%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
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
