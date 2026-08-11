import 'package:flutter/material.dart';

import '../../core/theme/expressive_tokens.dart';

/// Il pulsante indietro dei mockup 01 e 02: non una freccia sola, una
/// pillola con scritto **dove si torna** — `.pill.calm` nel CSS dei mockup,
/// «← Annulla», «← Schede», «← Nuova scheda». Mai «Indietro» generico: il
/// mockup non lo scrive mai, dice sempre la destinazione.
///
/// Sostituisce la freccia automatica di `AppBar` solo nelle schermate
/// raggiunte scendendo da un'altra (non dal cassetto): quelle restano con
/// l'hamburger, per la stessa ragione per cui le due cose non si scambiano.
class BackPill extends StatelessWidget {
  const BackPill({super.key, required this.label, this.onTap});

  /// Dove si torna. Non un verbo, un nome — la schermata di destinazione.
  final String label;

  /// Assente: chiude con `Navigator.maybePop`, il comportamento di una
  /// normale freccia indietro.
  final VoidCallback? onTap;

  /// Larghezza generosa e fissa per il `leading` di un `AppBar`: `leadingWidth`
  /// non si adatta al contenuto, e una larghezza diversa per ogni etichetta
  /// renderebbe la fila delle azioni instabile da una schermata all'altra.
  static const double leadingWidth = 152;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(left: t.spacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: t.shape.cornerFull,
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.sm,
              vertical: t.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.13),
              borderRadius: t.shape.cornerFull,
            ),
            child: Text(
              '← $label',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
