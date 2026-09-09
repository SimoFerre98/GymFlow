import 'package:flutter/material.dart';
import '../../core/theme/immersivo_tokens.dart';
/// Il pulsante d'azione del mockup: fondo in accento, testo scuro, un glifo in
/// un riquadro a sé col bordo dello stesso accento — angolo vivo, non un
/// cerchio: `.btn-main-icon` di Immersivo, vedi `DESIGN-SPEC.md`.
///
/// Il glifo cambia con l'azione, verificato nei tre usi diversi del mockup 02 e
/// non inventato: `→` per «Riprendi» e «Continua», `+` per «Nuovo esercizio»,
/// `✓` per «Salva esercizio». `null` quando l'azione è già ovvia dal testo, come
/// «Metti in pausa»: il cerchio non compare.
///
/// È un carattere disegnato come testo, non un'`Icon` — così lo disegna il
/// mockup (`<span class="arw">→</span>`), e così lo aveva già fatto la prima
/// implementazione di questo pulsante, dentro `HomeHeroCard`. Restare sulla
/// stessa forma tiene ogni pulsante d'azione dell'app identico agli altri.
///
/// Per impostazione predefinita si stringe al contenuto: `mainAxisSize.min` sul
/// `Row` interno. Chi lo vuole a piena larghezza — «Riprendi l'allenamento» che
/// occupa tutta la card — lo avvolge in `SizedBox(width: double.infinity, ...)`:
/// il vincolo teso che ne risulta forza il contenitore a riempirlo, e
/// `spaceBetween` torna a separare testo e cerchio come nel mockup.
class ExpressiveCtaButton extends StatelessWidget {
  const ExpressiveCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.arw = '→',
  });
  final String label;
  final VoidCallback onTap;
  final String? arw;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    // L'ambra come **fondo** non è `primary` nel tema chiaro, dove `primary` è
    // un marrone scuro pensato per il testo: è `primaryContainer`.
    final scuro = scheme.brightness == Brightness.dark;
    final fondo = scuro ? scheme.primary : scheme.primaryContainer;
    final testoColore = scuro ? scheme.onPrimary : scheme.onPrimaryContainer;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: t.shape.cornerXs,
          ),
          padding: arw == null
              ? EdgeInsets.symmetric(
                  horizontal: t.spacing.lg,
                  vertical: t.spacing.sm,
                )
              : EdgeInsets.fromLTRB(
                  t.spacing.lg,
                  t.spacing.sm,
                  t.spacing.sm,
                  t.spacing.sm,
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: testoColore,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
              if (arw != null) ...[
                SizedBox(width: t.spacing.sm),
                // `.btn-main-icon` del mockup Immersivo: un riquadro (non un
                // cerchio) col fondo dello scaffold, bordo e glifo nello
                // stesso colore d'accento del pulsante.
                Container(
                  width: t.sizing.iconLg + t.spacing.sm,
                  height: t.sizing.iconLg + t.spacing.sm,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: t.shape.cornerXs,
                    border: Border.all(color: fondo),
                  ),
                  child: Center(
                    child: Text(
                      arw!,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: fondo),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
