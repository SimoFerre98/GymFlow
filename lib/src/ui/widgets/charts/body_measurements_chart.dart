import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/providers/firestore_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/body_measurement.dart';

class BodyMeasurementsChart extends ConsumerStatefulWidget {
  final String userId;

  const BodyMeasurementsChart({super.key, required this.userId});

  @override
  ConsumerState<BodyMeasurementsChart> createState() =>
      _BodyMeasurementsChartState();
}

class _BodyMeasurementsChartState extends ConsumerState<BodyMeasurementsChart> {
  String _selectedMetric = 'Weight'; // Default

  final Map<String, String> _metrics = {
    'Weight': 'kg',
    'Body Fat': '%',
    'Chest': 'cm',
    'Waist': 'cm',
    'Hips': 'cm',
    'Biceps': 'cm',
    'Thighs': 'cm',
    'Calves': 'cm',
    'Shoulders': 'cm',
    'Neck': 'cm',
  };

  // Helper to extract value based on key
  double? _getValue(BodyMeasurement m, String key) {
    switch (key) {
      case 'Weight':
        return m.weight;
      case 'Body Fat':
        return m.bodyFatPercentage;
      case 'Chest':
        return m.chest;
      case 'Waist':
        return m.waist;
      case 'Hips':
        return m.hips;
      case 'Biceps':
        return m.biceps;
      case 'Thighs':
        return m.thighs;
      case 'Calves':
        return m.calves;
      case 'Shoulders':
        return m.shoulders;
      case 'Neck':
        return m.neck;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.read(firestoreServiceProvider);

    return StreamBuilder<List<BodyMeasurement>>(
      stream: firestore.getBodyMeasurements(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allData = snapshot.data ?? [];

        // Filter data points that have value for selected metric
        final dataPoints = allData
            .where((m) => _getValue(m, _selectedMetric) != null)
            .toList();

        // Sort by date ascending for the chart
        dataPoints.sort((a, b) => a.date.compareTo(b.date));

        // If no data
        if (dataPoints.isEmpty) {
          return SizedBox(
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMetricSelector(),
                const Expanded(
                  child: Center(
                    child: Text(
                      'No data for this metric yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: Column(
            children: [
              _buildMetricSelector(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 16,
                    left: 0,
                    top: 20,
                    bottom: 10,
                  ),
                  child: LineChart(_buildChartData(dataPoints, context)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _metrics.keys.map((key) {
          final isSelected = key == _selectedMetric;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(key),
              selected: isSelected,
              selectedColor: Colors.blueAccent.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Colors.blueAccent
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() => _selectedMetric = key);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  LineChartData _buildChartData(
    List<BodyMeasurement> data,
    BuildContext context,
  ) {
    if (data.isEmpty) return LineChartData();

    final spots = data.asMap().entries.map((e) {
      final m = e.value;
      final val = _getValue(m, _selectedMetric) ?? 0;
      // Use index as X for equidistant points, usually better for discrete measurements than date value
      // But using date allows seeing gaps. Let's try Using Date.millisecondsSinceEpoch as double
      return FlSpot(m.date.millisecondsSinceEpoch.toDouble(), val);
    }).toList();

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    // Add padding to Y axis
    final paddingY = (maxY - minY) * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 86400000 * 5, // ~5 days? Roughly.
            // Dynamically calculate interval based on range?
            // FlChart is tricky with date axes.
            // Let's simplified approach: Just show Start and End dates or sparse titles.
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ), // Hide left titles for cleaner look
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minY: (minY - paddingY).floorToDouble(),
      maxY: (maxY + paddingY).ceilToDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blueAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) => true,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blueAccent.withValues(alpha: 0.1),
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.withValues(alpha: 0.2),
                Colors.blueAccent.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.grey[800] ?? Colors.black,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              return LineTooltipItem(
                '${DateFormat('MMM d').format(date)}\n${spot.y.toStringAsFixed(1)} ${_metrics[_selectedMetric]}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
