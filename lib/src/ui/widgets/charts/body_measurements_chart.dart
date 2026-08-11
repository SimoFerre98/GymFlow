import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/providers/firestore_provider.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/theme/expressive_tokens.dart';
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

/// Un campo misurabile: la chiave del modello, e le due chiavi di traduzione
/// per l'etichetta e l'unita.
///
/// Le stesse chiavi di traduzione di `body_measurements_screen.dart`
/// (`bm_chest`, `bm_arms` per i bicipiti, e cosi via): sono la stessa
/// grandezza vista da due schermate, e una sola parola per dirla — non
/// "Biceps" qui e "Braccia" nella schermata di inserimento.
class _Metrica {
  const _Metrica(this.chiave, this.etichetta, this.unita);
  final String chiave;
  final String etichetta;
  final String unita;
}

const _metriche = <_Metrica>[
  _Metrica('weight', 'bm_weight', 'bm_kg'),
  _Metrica('bodyFat', 'bm_body_fat', 'bm_percent'),
  _Metrica('chest', 'bm_chest', 'bm_cm'),
  _Metrica('waist', 'bm_waist', 'bm_cm'),
  _Metrica('hips', 'bm_hips', 'bm_cm'),
  _Metrica('biceps', 'bm_arms', 'bm_cm'),
  _Metrica('thighs', 'bm_thighs', 'bm_cm'),
  _Metrica('calves', 'bm_calves', 'bm_cm'),
  _Metrica('shoulders', 'bm_shoulders', 'bm_cm'),
  _Metrica('neck', 'bm_neck', 'bm_cm'),
];

class _BodyMeasurementsChartState extends ConsumerState<BodyMeasurementsChart> {
  String _selectedMetric = _metriche.first.chiave;

  double? _getValue(BodyMeasurement m, String chiave) {
    switch (chiave) {
      case 'weight':
        return m.weight;
      case 'bodyFat':
        return m.bodyFatPercentage;
      case 'chest':
        return m.chest;
      case 'waist':
        return m.waist;
      case 'hips':
        return m.hips;
      case 'biceps':
        return m.biceps;
      case 'thighs':
        return m.thighs;
      case 'calves':
        return m.calves;
      case 'shoulders':
        return m.shoulders;
      case 'neck':
        return m.neck;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.read(firestoreServiceProvider);
    final loc = ref.watch(localizationNotifierProvider);

    return StreamBuilder<List<BodyMeasurement>>(
      stream: firestore.getBodyMeasurements(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildMetricSelector(loc),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          );
        }

        final allData = snapshot.data ?? [];
        final dataPoints = allData
            .where((m) => _getValue(m, _selectedMetric) != null)
            .toList();
        dataPoints.sort((a, b) => a.date.compareTo(b.date));

        if (dataPoints.isEmpty) {
          return Column(
            children: [
              _buildMetricSelector(loc),
              Expanded(
                child: Center(
                  child: Text(
                    loc.t('no_data'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildMetricSelector(loc),
            SizedBox(height: context.expressive.spacing.sm),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: context.expressive.spacing.md,
                  top: context.expressive.spacing.lg,
                  bottom: context.expressive.spacing.sm,
                ),
                child: LineChart(_buildChartData(dataPoints, context, loc)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricSelector(Localization loc) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: t.spacing.sm),
      child: Row(
        children: _metriche.map((metrica) {
          final isSelected = metrica.chiave == _selectedMetric;
          return Padding(
            padding: EdgeInsets.only(right: t.spacing.sm),
            child: ChoiceChip(
              label: Text(loc.t(metrica.etichetta)),
              selected: isSelected,
              selectedColor: scheme.primary.withValues(alpha: 0.2),
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: scheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: t.shape.cornerFull,
                side: BorderSide(
                  color: isSelected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() => _selectedMetric = metrica.chiave);
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
    Localization loc,
  ) {
    if (data.isEmpty) return LineChartData();

    final scheme = Theme.of(context).colorScheme;
    final testoAsse = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final lingua = loc.locale.languageCode;
    final unita = loc.t(_metriche.firstWhere((m) => m.chiave == _selectedMetric).unita);

    final spots = data.asMap().entries.map((e) {
      final m = e.value;
      final val = _getValue(m, _selectedMetric) ?? 0;
      return FlSpot(m.date.millisecondsSinceEpoch.toDouble(), val);
    }).toList();

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final paddingY = (maxY - minY) * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: scheme.onSurface.withValues(alpha: 0.1),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: context.expressive.spacing.xxl,
            interval: 86400000 * 5, // Circa cinque giorni.
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Padding(
                padding: EdgeInsets.only(top: context.expressive.spacing.sm),
                child: Text(
                  DateFormat('MM/dd', lingua).format(date),
                  style: testoAsse,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: context.expressive.sizing.thumbnailSm,
            getTitlesWidget: (value, meta) {
              return Text(value.toStringAsFixed(1), style: testoAsse);
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
                scheme.primary.withValues(alpha: 0.2),
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
          getTooltipColor: (touchedSpot) => scheme.inverseSurface,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              return LineTooltipItem(
                '${DateFormat('MMM d', lingua).format(date)}\n'
                '${spot.y.toStringAsFixed(1)} $unita',
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
    );
  }
}
