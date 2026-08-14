import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/localization_provider.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/expressive_tokens.dart';

/// Altezza del grafico e della sua attesa: geometria di questo widget, non
/// una spaziatura condivisa.
const double _kAltezzaGrafico = 180;

/// Spazio fra due fette adiacenti, per l'effetto "tagliato".
const double _kSpazioTraFette = 2;

/// Raggio del foro centrale: piu piccolo di [_kRaggioFetta], cosi la ciambella
/// resta leggibile.
const double _kRaggioCentro = 40;

/// Raggio di una fetta a riposo, e quando e toccata.
const double _kRaggioFetta = 50;
const double _kRaggioFettaToccata = 60;

/// Dimensione del testo dentro una fetta, a riposo e quando e toccata.
const double _kFontFetta = 16;
const double _kFontFettaToccata = 25;

/// Sfocatura dell'ombra dietro la percentuale, per leggerla sopra ogni tinta.
const double _kSfocaturaOmbraFetta = 2;

/// Le quattro tinte categoriche, in ordine fisso: la quinta categoria non ne
/// genera una quinta, ricade sul neutro passato a [_WorkoutTypePieChartState._colore].
const _paletteCategorica = <Color>[
  AppPalette.categoryBlue,
  AppPalette.categoryOrange,
  AppPalette.categoryAqua,
  AppPalette.categoryYellow,
];

/// A quale tinta corrisponde ciascun tipo noto, nello stesso ordine fisso
/// della palette: non e un indice arbitrario, e la storia di quale tinta
/// "appartiene" a quale tipo, cosi un tipo aggiunto in mezzo non sposta i
/// colori di quelli già mostrati altrove.
const _indiceTipoNoto = <String, int>{
  'strength': 0,
  'cardio': 1,
  'mobility': 2,
  'sport': 3,
  'hypertrophy': 0,
  'flexibility': 2,
};

const _chiaveTipoNoto = <String, String>{
  'strength': 'workout_type_strength',
  'cardio': 'workout_type_cardio',
  'mobility': 'workout_type_mobility',
  'sport': 'workout_type_sport',
  'hypertrophy': 'workout_type_hypertrophy',
  'flexibility': 'workout_type_flexibility',
};

class WorkoutTypePieChart extends ConsumerStatefulWidget {
  final Map<String, int> data;

  const WorkoutTypePieChart({super.key, required this.data});

  @override
  ConsumerState<WorkoutTypePieChart> createState() =>
      _WorkoutTypePieChartState();
}

class _WorkoutTypePieChartState extends ConsumerState<WorkoutTypePieChart> {
  int _indiceToccato = -1;

  Color _colore(String type, ColorScheme scheme) {
    final indice = _indiceTipoNoto[type.toLowerCase()];
    if (indice == null) return scheme.onSurface.withValues(alpha: 0.3);
    return _paletteCategorica[indice];
  }

  String _etichetta(String type, Localization loc) {
    final chiave = _chiaveTipoNoto[type.toLowerCase()];
    if (chiave == null) return type;
    return loc.t(chiave);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.expressive;
    final loc = ref.watch(localizationNotifierProvider);

    if (widget.data.isEmpty) {
      return SizedBox(
        height: _kAltezzaGrafico,
        child: Center(
          child: Text(
            loc.t('no_data'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final voci = widget.data.entries.toList();
    final total = widget.data.values.fold(0, (sum, val) => sum + val);

    return Column(
      children: [
        SizedBox(
          height: _kAltezzaGrafico,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _indiceToccato = -1;
                      return;
                    }
                    _indiceToccato =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: _kSpazioTraFette,
              centerSpaceRadius: _kRaggioCentro,
              sections: _showingSections(voci, total, scheme),
            ),
          ),
        ),
        SizedBox(height: t.spacing.xl),
        Wrap(
          spacing: t.spacing.md,
          runSpacing: t.spacing.sm,
          alignment: WrapAlignment.center,
          children: voci.map((entry) {
            final color = _colore(entry.key, scheme);
            final percentage = ((entry.value / total) * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: t.spacing.sm,
                  height: t.spacing.sm,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                SizedBox(width: t.spacing.xs),
                Text(
                  '${_etichetta(entry.key, loc)} ($percentage%)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _showingSections(
    List<MapEntry<String, int>> voci,
    int total,
    ColorScheme scheme,
  ) {
    return voci.asMap().entries.map((indexed) {
      final index = indexed.key;
      final entry = indexed.value;
      final isTouched = index == _indiceToccato;
      final fontSize = isTouched ? _kFontFettaToccata : _kFontFetta;
      final radius = isTouched ? _kRaggioFettaToccata : _kRaggioFetta;
      final shadows = [
        Shadow(color: scheme.shadow, blurRadius: _kSfocaturaOmbraFetta),
      ];
      final value = entry.value.toDouble();
      final percentage = (value / total) * 100;

      return PieChartSectionData(
        color: _colore(entry.key, scheme),
        value: value,
        title: '${percentage.toInt()}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: scheme.onPrimary,
          shadows: shadows,
        ),
      );
    }).toList();
  }
}
