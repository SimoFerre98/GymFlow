import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Disegna l'andamento recente di una metrica come grafico minimale a linea.
///
/// La sparkline e puramente visiva: non ha assi, etichette ne griglie. Mostra
/// solo la forma della variazione recente nel riquadro della metrica.
///
/// Se i valori sono meno di due, il painter non traccia alcuna linea.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.strokeWidth = kSparklineStroke,
    this.height = kSparklineHeight,
    this.width,
  });

  /// 2,7 — il tratto di 2 px del mockup convertito (`dp = px x 1,36`).
  ///
  /// Non e un token del design system: la sparkline e l'unico posto dove
  /// serve, e `expressive_tokens.dart` dichiara di non voler ospitare costanti
  /// di un solo componente.
  static const double kSparklineStroke = 2.7;

  /// 22 — altezza della sparkline dentro la tessera della metrica.
  static const double kSparklineHeight = 22;

  /// Serie di campioni numerici recenti da visualizzare.
  final List<double> values;

  /// Colore del tratto (es. ambra per calorie, salmone per battito).
  final Color color;

  /// Spessore della linea in pixel logici.
  final double strokeWidth;

  /// Altezza del widget.
  final double height;

  /// Larghezza opzionale del widget (se null, occupa lo spazio disponibile).
  final double? width;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparklinePainter(
            values: values,
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    double minVal = values.first;
    double maxVal = values.first;
    for (final v in values) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }

    final path = Path();
    final verticalPadding = strokeWidth;
    final usableHeight = size.height - (verticalPadding * 2);

    // Se tutti i valori sono identici, disegna una linea orizzontale al centro.
    if (maxVal == minVal) {
      final y = size.height / 2;
      path.moveTo(0, y);
      path.lineTo(size.width, y);
      canvas.drawPath(path, paint);
      return;
    }

    final range = maxVal - minVal;
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minVal) / range;
      final y = (size.height - verticalPadding) - (normalized * usableHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        !listEquals(oldDelegate.values, values);
  }
}
