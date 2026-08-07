import 'package:flutter/material.dart';

import '../../core/theme/expressive_tokens.dart';

/// Un valore di una serie, impostato trascinando invece che digitando.
///
/// Esiste come componente e non come tre copie perche i criteri di US-046
/// chiedono su **tutti e tre** i valori le stesse tre cose: area di tocco da 48
/// dp, annuncio allo screen reader con valore e unita, e raggiungibilita da
/// tastiera. Scritte una volta sola, valgono per tutti; copiate tre volte,
/// prima o poi una copia le perde.
///
/// Il passo non e un dettaglio di comodo: 2,5 kg e lo scatto dei dischi
/// piccoli, e un cursore che si muove di 1 kg costringerebbe a otto trascinamenti
/// dove ne bastano tre.
class SetValueSlider extends StatelessWidget {
  const SetValueSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.color,
    this.formatValue,
    this.semanticUnit,
    this.onTapValue,
  });

  final String label;
  final double value;
  final double min;
  final double max;

  /// Di quanto si muove il valore a ogni scatto.
  final double step;

  final ValueChanged<double> onChanged;

  /// Colore dell'accento. Ambra per cio che si imposta, salmone per i dati
  /// vitali: sul mockup lo sforzo percepito e salmone per questo.
  final Color? color;

  /// Come si scrive il valore accanto all'etichetta. Di norma senza decimali.
  final String Function(double value)? formatValue;

  /// Unita annunciata allo screen reader: "kg", "ripetizioni", "RPE".
  ///
  /// Il criterio chiede valore **e** unita: "62,5" da solo non dice niente a
  /// chi non vede l'etichetta sopra.
  final String? semanticUnit;

  /// Cosa fare toccando il valore. E la via d'uscita da tastiera per i casi
  /// fuori scala, che un criterio chiede esplicitamente.
  final VoidCallback? onTapValue;

  String get _text => formatValue?.call(value) ?? value.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    // Il valore di partenza puo non essere un multiplo del passo: una serie
    // salvata a 61,3 kg resta 61,3 finche non la si tocca. Il cursore pero
    // lavora a scatti, quindi il conteggio delle divisioni parte dal minimo.
    final divisions = ((max - min) / step).round().clamp(1, 100000);
    final clamped = value.clamp(min, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            // Il valore e toccabile: e la porta della tastiera.
            InkWell(
              onTap: onTapValue,
              borderRadius: t.shape.cornerSm,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.spacing.sm,
                  vertical: t.spacing.xs,
                ),
                child: Text(
                  _text,
                  style: t.typography.metricSmall?.copyWith(color: accent) ??
                      TextStyle(color: accent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        // L'area di tocco non e il tratto disegnato: il cursore di Material e
        // alto meno di 48 dp, e il criterio ne chiede almeno 48.
        SizedBox(
          height: t.sizing.minTouchTarget,
          // Niente `Semantics` attorno allo `Slider`: Material ne crea gia uno
          // suo, e quello vince. Avvolgerlo faceva annunciare "14%" — la
          // percentuale di default — invece di "62,5 kg". Il modo giusto e
          // `semanticFormatterCallback`, che quel nodo lo scrive davvero.
          child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accent,
                thumbColor: accent,
                inactiveTrackColor: scheme.outlineVariant,
                // Le tacche a ogni scatto: sul mockup il tratto e punteggiato,
                // e i puntini dicono che il valore si muove a scatti.
                activeTickMarkColor: accent.withValues(alpha: 0.4),
                inactiveTickMarkColor: scheme.outline.withValues(alpha: 0.4),
              ),
              child: Slider(
                value: clamped.toDouble(),
                min: min,
                max: max,
                divisions: divisions,
                label: null,
                // Valore **e** unita, come chiede il criterio: "62,5" da solo
                // non dice nulla ad alta voce, e "14%" ancora meno.
                semanticFormatterCallback: _describe,
                onChanged: (raw) => onChanged(_snap(raw)),
              ),
            ),
          ),
        ],
    );
  }

  String _describe(double v) {
    final bounded = v.clamp(min, max);
    final text = formatValue?.call(bounded) ?? bounded.toStringAsFixed(0);
    return semanticUnit == null ? text : '$text $semanticUnit';
  }

  /// Riporta il valore sul multiplo del passo piu vicino, partendo dal minimo.
  double _snap(double raw) {
    final steps = ((raw - min) / step).round();
    final snapped = min + steps * step;
    // I decimali del passo si trascinano dietro errori di virgola mobile:
    // 62,499999 invece di 62,5 finirebbe a schermo cosi com'e.
    return double.parse(snapped.toStringAsFixed(3)).clamp(min, max).toDouble();
  }
}
