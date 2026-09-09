import 'package:flutter/material.dart';
import '../../core/theme/immersivo_tokens.dart';
/// La card del design system.
///
/// Esiste perche la stessa decorazione era scritta a mano dentro
/// `dashboard_screen.dart`, in un metodo privato usato sei volte e invisibile a
/// chiunque altro. Sei valori numerici e un colore letterale, in un componente
/// che tredici storie del backlog devono riusare.
///
/// **Ogni valore viene dai token.** Il widget non sa quanto sia grande un
/// raggio: lo chiede. E cio che rende il cambio del design system un lavoro su
/// un file solo.
///
/// ```dart
/// ExpressiveCard(
///   title: 'Attivita',
///   onTap: _openDetail,
///   child: ActivityChart(sessions: sessions),
/// )
/// ```
class ExpressiveCard extends StatelessWidget {
  const ExpressiveCard({
    super.key,
    required this.child,
    this.title,
    this.onTap,
    this.padding,
  });
  final Widget child;
  /// Titolo della card. Assente significa nessuno spazio occupato.
  final String? title;
  /// Azione al tocco. Nulla rende la card non toccabile, senza onda ne
  /// reazione.
  final VoidCallback? onTap;
  /// Spaziatura interna. Assente, `spacing.md` su tutti i lati — il valore di
  /// sempre. Esiste per le righe compatte (il cassetto) che vogliono restare
  /// la stessa card, non un'altra decorazione scritta a mano.
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        // Il ruolo che significa "superficie di una card", invece di
        // `cardColor`: quel campo precede Material 3, il tema non lo imposta, e
        // oggi funziona per un valore di default, non per una decisione.
        color: scheme.surfaceContainerHigh,
        // Angoli vivi, filetto invece di ombra: il bagliore sfumato era
        // l'elevazione di Material 3 Expressive, non il linguaggio di
        // Immersivo/Toxic Forest, dove ogni riquadro (le nuove schermate di
        // Impostazioni, il profilo) si chiude con un bordo sottile su
        // `scheme.outline`, mai con un `boxShadow`.
        border: Border.all(color: scheme.outline),
      ),
      child: Material(
        // Nessun colore da scegliere: serve solo la superficie che disegna
        // l'onda del tocco sopra la decorazione.
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? EdgeInsets.all(t.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    // Uno stile, non una dimensione: cambiando la scala
                    // tipografica il titolo la segue.
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: t.spacing.md),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
