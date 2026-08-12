import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/localization_provider.dart';
import '../../core/theme/expressive_tokens.dart';
import '../../core/utils/workout_summary.dart';

/// Clipper che ritaglia il contenitore con angoli superiori arrotondati (22 dp)
/// e bordo inferiore dentellato a semicerchi (raggio 7 dp, passo 14 dp).
class ReceiptClipper extends CustomClipper<Path> {
  const ReceiptClipper({
    this.topRadius = defaultTopRadius,
    this.scallopRadius = defaultScallopRadius,
  });

  /// 20 px del mockup convertiti: `dp = px x 1,36`.
  static const defaultTopRadius = 22.0;

  /// 5 px del mockup convertiti, arrotondati.
  static const defaultScallopRadius = 7.0;

  final double topRadius;
  final double scallopRadius;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Angolo in alto a sinistra
    path.moveTo(0, topRadius);
    path.arcToPoint(
      Offset(topRadius, 0),
      radius: Radius.circular(topRadius),
    );

    // Lato superiore
    path.lineTo(w - topRadius, 0);

    // Angolo in alto a destra
    path.arcToPoint(
      Offset(w, topRadius),
      radius: Radius.circular(topRadius),
    );

    // Lato destro verso il basso
    path.lineTo(w, h);

    // Bordo inferiore dentellato (archi rientranti verso l'alto)
    final step = scallopRadius * 2;
    // Almeno un dente: sotto i 7 dp di larghezza `round()` darebbe zero, il
    // ciclo non girerebbe e il bordo inferiore diventerebbe una diagonale.
    final count = (w / step).round().clamp(1, 1000);
    final actualStep = count > 0 ? w / count : w;
    final actualRadius = actualStep / 2;

    for (int i = 0; i < count; i++) {
      final nextX = w - (i + 1) * actualStep;
      path.arcToPoint(
        Offset(nextX.clamp(0.0, w), h),
        radius: Radius.circular(actualRadius),
        clockwise: false,
      );
    }

    // Lato sinistro verso l'alto fino al raccordo
    path.lineTo(0, topRadius);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant ReceiptClipper oldClipper) {
    return oldClipper.topRadius != topRadius ||
        oldClipper.scallopRadius != scallopRadius;
  }
}

/// Scontrino di riepilogo di fine allenamento.
///
/// Disegna una card con fondo ambra, testo scuro e bordo inferiore dentellato,
/// esponendo le metriche chiave: volume sollevato, serie completate, sforzo medio
/// ed eventuali calorie e battito cardiaco.
class WorkoutReceipt extends ConsumerWidget {
  const WorkoutReceipt({
    super.key,
    required this.summary,
  });

  final WorkoutSummary summary;

  String _formatVolume(int volume) {
    final str = volume.toString();
    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
  }

  String _formatRpe(double rpe, String languageCode) {
    final formatted = rpe.toStringAsFixed(1);
    if (languageCode == 'it') {
      return formatted.replaceAll('.', ',');
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.expressive;
    final loc = ref.watch(localizationNotifierProvider);

    // Fondo ambra e testo scuro in entrambi i temi per fedelta al mockup
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final bgColor =
        isDark ? theme.colorScheme.primary : theme.colorScheme.primaryContainer;
    final inkColor =
        isDark
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onPrimaryContainer;

    final dividerColor = inkColor.withValues(alpha: 0.28);

    // Prepariamo le righe visibili
    final rows = <_ReceiptRowData>[
      _ReceiptRowData(
        label: loc.t('workout_receipt_volume'),
        value: '${_formatVolume(summary.totalVolume)} kg',
      ),
      _ReceiptRowData(
        label: loc.t('workout_receipt_completed_sets'),
        value: '${summary.completedSets} / ${summary.totalSets}',
      ),
      if (summary.averageRpe != null)
        _ReceiptRowData(
          label: loc.t('workout_receipt_avg_rpe'),
          value: 'RPE ${_formatRpe(summary.averageRpe!, loc.locale.languageCode)}',
        ),
      if (summary.calories != null)
        _ReceiptRowData(
          label: loc.t('workout_receipt_calories'),
          value: '${summary.calories} kcal',
        ),
      if (summary.avgHeartRate != null)
        _ReceiptRowData(
          label: loc.t('workout_receipt_avg_heart_rate'),
          value: '${summary.avgHeartRate} bpm',
        ),
    ];

    return ClipPath(
      clipper: const ReceiptClipper(),
      child: Container(
        color: bgColor,
        // In basso serve piu spazio: i denti mangiano l'altezza del raggio.
        padding: EdgeInsets.fromLTRB(
          t.spacing.md,
          t.spacing.md,
          t.spacing.md,
          t.spacing.md + ReceiptClipper.defaultScallopRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intestazione: SCHEDA / Nome allenamento e chip durata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('workout_receipt_header'),
                        style: (theme.textTheme.labelSmall ?? const TextStyle())
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: inkColor.withValues(alpha: 0.62),
                            ),
                      ),
                      SizedBox(height: t.spacing.xs / 2),
                      Text(
                        summary.workoutName.isNotEmpty
                            ? summary.workoutName
                            : loc.t('workout_untitled'),
                        style: (theme.textTheme.titleMedium ?? const TextStyle())
                            .copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: inkColor,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.spacing.sm,
                    vertical: t.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: inkColor,
                    borderRadius: t.shape.cornerFull,
                  ),
                  child: Text(
                    '${summary.durationMinutes} min',
                    style: (theme.textTheme.labelSmall ?? const TextStyle())
                        .copyWith(fontWeight: FontWeight.w700, color: bgColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: t.spacing.sm),
            _ReceiptDashedDivider(color: dividerColor),

            // Elenco degli esercizi: e quello che fa riconoscere
            // l'allenamento sullo scontrino, non solo quattro numeri
            // aggregati — segnalato dall'utente come "scontrino povero".
            // Solo le serie finite sul totale, non pesi o ripetizioni: fino
            // a US-083 una serie pianificata non ha un formato solo da
            // riassumere in una riga, e un numero sbagliato qui sarebbe
            // peggio di non mostrarlo.
            if (summary.exercises.isNotEmpty) ...[
              SizedBox(height: t.spacing.xs),
              Text(
                loc.t('workout_receipt_exercises'),
                style: (theme.textTheme.labelSmall ?? const TextStyle())
                    .copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: inkColor.withValues(alpha: 0.62),
                    ),
              ),
              for (final esercizio in summary.exercises)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: t.spacing.xs / 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          esercizio.name,
                          style: (theme.textTheme.bodySmall ??
                                  const TextStyle())
                              .copyWith(color: inkColor.withValues(alpha: 0.85)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${esercizio.completedSets}/${esercizio.totalSets}',
                        style: (t.typography.metricSmall ?? const TextStyle())
                            .copyWith(
                              fontSize: theme.textTheme.bodySmall?.fontSize,
                              fontWeight: FontWeight.w700,
                              color: inkColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: t.spacing.xs),
              _ReceiptDashedDivider(color: dividerColor),
            ],
            SizedBox(height: t.spacing.xs),

            // Righe di riepilogo con separatori tratteggiati
            for (int i = 0; i < rows.length; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      rows[i].label,
                      style: (theme.textTheme.bodySmall ?? const TextStyle())
                          .copyWith(
                            fontWeight: FontWeight.w500,
                            color: inkColor.withValues(alpha: 0.85),
                          ),
                    ),
                    Text(
                      rows[i].value,
                      // Misura dalla stessa riga dell'etichetta, famiglia e
                      // cifre tabulari dal token: il mockup vuole i numeri
                      // monospaziati ma non piu grandi del testo accanto.
                      style: (t.typography.metricSmall ?? const TextStyle())
                          .copyWith(
                            fontSize: theme.textTheme.bodySmall?.fontSize,
                            fontWeight: FontWeight.w700,
                            color: inkColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: t.spacing.xs / 2),
                  child: _ReceiptDashedDivider(color: dividerColor),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptRowData {
  const _ReceiptRowData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _ReceiptDashedDivider extends StatelessWidget {
  const _ReceiptDashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        if (dashCount <= 0) return const SizedBox.shrink();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
