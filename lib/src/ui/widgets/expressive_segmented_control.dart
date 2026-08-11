import 'package:flutter/material.dart';

import '../../core/theme/expressive_tokens.dart';

/// Il segmentato del mockup 03 (`.seg`): un cursore ambra che **scivola** sotto
/// l'etichetta scelta, invece di un `TabBar` con l'indicatore predefinito di
/// Material.
///
/// «Il cursore scivola, non salta»: nel mockup l'ambra si muove con una curva
/// enfatizzata in 0,48 s (`transition: transform .48s var(--emph-dec)`), e il
/// testo cambia colore con una transizione propria — 0,3 s, curva standard —
/// non a scatto. Sono le due righe di CSS `.seg .glider` e `.seg button` che un
/// `TabBar` non lascia toccare: da qui il widget proprio invece che configurare
/// quello di Material.
///
/// Pensato per due voci — Cronometro/Recupero — ma funziona con qualunque
/// numero: la libreria del segmentato Tutti/Miei/Recenti (`DESIGN-SPEC.md`,
/// voce sulla libreria esercizi) è lo stesso componente.
class ExpressiveSegmentedControl extends StatelessWidget {
  const ExpressiveSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(labels.length >= 2, 'un segmentato con una voce sola non serve');

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final n = labels.length;

    // Il traguardo del cursore: da -1 (prima voce) a 1 (ultima), passo
    // regolare. Per due voci e esattamente lo `translateX(100%)` del mockup.
    final traguardo = -1.0 + (2.0 * selectedIndex / (n - 1));

    return Semantics(
      container: true,
      child: Container(
        // 3px del mockup: fra i token il piu vicino e `spacing.xs` (4).
        padding: EdgeInsets.all(t.spacing.xs),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.09),
          borderRadius: t.shape.cornerFull,
        ),
        child: Stack(
          children: [
            // `Positioned.fill`, non `LayoutBuilder`: lo `Stack` non ha
            // un'altezza propria, la prende dal `Row` delle etichette qui
            // sotto — che ce l'ha, per il testo e il suo padding. Un
            // `LayoutBuilder` qui dentro chiederebbe allo `Stack` l'altezza
            // che lo `Stack` sta ancora aspettando da lui: un vincolo
            // infinito, ed e la forma in cui il difetto si e visto nei test.
            // `Positioned.fill` invece e escluso dal calcolo — lo `Stack` si
            // dimensiona sul `Row`, e poi il cursore riempie quel risultato.
            Positioned.fill(
              child: AnimatedAlign(
                // 0,48 s e la curva enfatizzata: verificato nel CSS
                // (`--emph-dec`), non stimato. `t.motion.emphasized` e 500
                // ms — il token piu vicino, la differenza non si sente.
                duration: t.motion.emphasized,
                curve: t.motion.emphasizedCurve,
                alignment: Alignment(traguardo, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / n,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: t.shape.cornerFull,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == selectedIndex,
                      label: labels[i],
                      child: InkWell(
                        onTap: () => onChanged(i),
                        borderRadius: t.shape.cornerFull,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: t.spacing.sm,
                          ),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              // 0,3 s curva standard: `.seg button` nel CSS.
                              duration: t.motion.standard,
                              curve: t.motion.standardCurve,
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: i == selectedIndex
                                        ? scheme.onPrimary
                                        : scheme.onSurface.withValues(
                                            alpha: 0.62,
                                          ),
                                  ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
