import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/expressive_tokens.dart';

/// I pezzi visivi della schermata del tempo, presi dal mockup 03.
///
/// I numeri qui sotto sono i pixel del mockup **convertiti**, non copiati: per
/// il mockup 03 la conversione e `dp = px × 1,20` (DESIGN-SPEC). Stanno qui, con
/// il pixel di partenza accanto, perche sono misure di **questi** componenti e
/// non spaziature generali: metterli fra i token di spaziatura li renderebbe
/// disponibili a chiunque, che e il modo in cui una misura di un disegno finisce
/// per caso in un altro.

/// Il pulsante grande, da fermo. Mockup: 76 px.
const double kDiametroPrimario = 91;

/// Il pulsante grande mentre scorre: cambia forma e si allarga. Mockup: 96 px.
const double kLarghezzaPrimarioInCorsa = 115;

/// Il raggio degli angoli quando e allargato. Mockup: 26 px.
const double kRaggioPrimarioInCorsa = 31;

/// Il raggio del quadrante. Mockup: `r="102"`.
const double kRaggioQuadrante = 122;

/// Lo spessore dell'anello. Mockup: `stroke-width="9"`.
const double kTrattoQuadrante = 11;

/// Il quadrante: un anello che occupa lo spazio, col tempo dentro.
///
/// «Tutta l'altezza, un solo protagonista» e la prima nota del mockup: il
/// quadrante prende lo spazio che avanza fra intestazione e comandi, invece di
/// stare dentro una card. Con le mani occupate il tempo si valuta dalla
/// porzione di anello rimasta, senza mettere a fuoco le cifre.
class TimeDial extends StatelessWidget {
  const TimeDial({
    super.key,
    required this.tempo,
    required this.etichetta,
    this.frazione,
    this.coloreArco,
    this.inCorsa = false,
  });

  /// Il tempo gia formattato.
  final String tempo;

  /// Lo stato sotto le cifre: «PRONTO», «IN CORSO», «IN PAUSA».
  final String etichetta;

  /// Quanto anello resta, da 0 a 1. `null` per il cronometro, che non ha una
  /// fine verso cui andare: li l'anello resta la cornice del tempo.
  final double? frazione;

  /// Il colore dell'arco. Il mockup lo fa virare sul salmone in modalita
  /// recupero: e un dato vitale del corpo, non un'azione.
  final Color? coloreArco;

  /// «Onde mentre scorre»: le tre onde concentriche vivono solo mentre il
  /// tempo avanza, e si fermano in pausa — e il segnale che qualcosa si
  /// muove anche guardando di sbieco, senza metter a fuoco le cifre.
  final bool inCorsa;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final colore = coloreArco ?? scheme.primary;

    return Center(
      child: SizedBox(
        width: kRaggioQuadrante * 2 + 40,
        height: kRaggioQuadrante * 2 + 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _OndeConcentriche(attiva: inCorsa, colore: colore),
            CustomPaint(
              size: const Size.square(kRaggioQuadrante * 2),
              painter: _AnelloTempo(
                frazione: frazione,
                coloreFondo: scheme.onSurface.withValues(alpha: 0.16),
                coloreArco: colore,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // `FittedBox` perche le cifre non si taglino: sulla schermata
                // vera «00:00:0» arrivava troncato a meta dell'ultima cifra.
                Padding(
                  // Il quadrante e largo: al tempo si lascia quasi tutto lo
                  // spazio dentro l'anello, che e il motivo per cui l'anello e
                  // grande.
                  padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _CifreRotanti(
                      testo: tempo,
                      // Il ruolo piu grande che il tema abbia, con le cifre a
                      // larghezza fissa: senza, i numeri ballano a ogni
                      // decimo. `FittedBox` lo rimpicciolisce solo se serve.
                      stile: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: t.spacing.xs),
                Text(
                  etichetta.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.4,
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

/// «Le cifre rotolano, non lampeggiano»: la cifra che cambia esce verso
/// l'alto e la nuova entra dal basso. I separatori (`:`) non animano mai — la
/// chiave e il carattere stesso, quindi `AnimatedSwitcher` scatta solo dove
/// il valore e davvero cambiato, senza doverlo confrontare a mano come nel
/// mockup (che e JavaScript puro e non ha questo lusso).
class _CifreRotanti extends StatelessWidget {
  const _CifreRotanti({required this.testo, required this.stile});

  final String testo;
  final TextStyle? stile;

  static final _cifra = RegExp(r'[0-9]');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: testo.split('').map((carattere) {
        if (!_cifra.hasMatch(carattere)) {
          return Text(carattere, style: stile);
        }
        return ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Easing.emphasizedDecelerate,
            switchOutCurve: Easing.emphasizedAccelerate,
            transitionBuilder: (child, animazione) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animazione),
              child: FadeTransition(opacity: animazione, child: child),
            ),
            child: Text(carattere, key: ValueKey(carattere), style: stile),
          ),
        );
      }).toList(),
    );
  }
}

/// «Onde mentre scorre»: tre cerchi che si espandono sfalsati di un terzo di
/// giro l'uno dall'altro (0,93s su un ciclo di 2,8s nel mockup), e si fermano
/// in pausa. Un solo `AnimationController`, non tre: le tre onde sono la
/// stessa fase letta a un terzo di giro di distanza.
class _OndeConcentriche extends StatefulWidget {
  const _OndeConcentriche({required this.attiva, required this.colore});

  final bool attiva;
  final Color colore;

  @override
  State<_OndeConcentriche> createState() => _OndeConcentricheState();
}

class _OndeConcentricheState extends State<_OndeConcentriche>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    // Non in `initState`: `MediaQuery.of` iscrive questo widget ai suoi
    // cambiamenti, e farlo prima che `initState` sia finito e un errore —
    // `didChangeDependencies` e il posto giusto, e gira anche la prima volta.
    super.didChangeDependencies();
    _aggiorna();
  }

  @override
  void didUpdateWidget(_OndeConcentriche old) {
    super.didUpdateWidget(old);
    if (old.attiva != widget.attiva) _aggiorna();
  }

  void _aggiorna() {
    final consentito = !MediaQuery.of(context).disableAnimations;
    if (widget.attiva && consentito) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.attiva) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (i) {
            final fase = (_controller.value + i / 3) % 1.0;
            // .86 -> 1.3 come nel mockup, e sparisce dopo il 70% del giro
            // invece di restare visibile fino alla fine.
            final scala = 0.86 + fase * 0.44;
            final opacita = fase < 0.7 ? 0.5 * (1 - fase / 0.7) : 0.0;
            return Opacity(
              opacity: opacita.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scala,
                child: Container(
                  width: kRaggioQuadrante * 2 + 16,
                  height: kRaggioQuadrante * 2 + 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.colore, width: 1.5),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AnelloTempo extends CustomPainter {
  const _AnelloTempo({
    required this.frazione,
    required this.coloreFondo,
    required this.coloreArco,
  });

  final double? frazione;
  final Color coloreFondo;
  final Color coloreArco;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raggio = (size.width - kTrattoQuadrante) / 2;

    final fondo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kTrattoQuadrante
      ..strokeCap = StrokeCap.round
      ..color = coloreFondo;

    canvas.drawCircle(centro, raggio, fondo);

    final quanto = frazione;
    if (quanto == null || quanto <= 0) return;

    final arco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kTrattoQuadrante
      ..strokeCap = StrokeCap.round
      ..color = coloreArco;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raggio),
      // Da mezzogiorno, come il mockup ruota l'SVG di -90°.
      -math.pi / 2,
      2 * math.pi * quanto.clamp(0.0, 1.0),
      false,
      arco,
    );
  }

  @override
  bool shouldRepaint(_AnelloTempo old) =>
      old.frazione != frazione ||
      old.coloreArco != coloreArco ||
      old.coloreFondo != coloreFondo;
}

/// La riga dei comandi: due tondi neutri e uno grande in ambra che cambia forma.
///
/// «Il pulsante cambia forma»: da cerchio a rettangolo stondato quando parte, e
/// si allarga. La forma dice lo stato prima dell'icona.
class TimeControls extends StatelessWidget {
  const TimeControls({
    super.key,
    required this.inCorsa,
    required this.onPrimario,
    this.etichettaPrimario,
    this.onSinistra,
    this.iconaSinistra,
    this.etichettaSinistra,
    this.onDestra,
    this.iconaDestra,
    this.etichettaDestra,
  });

  final bool inCorsa;
  final VoidCallback onPrimario;

  /// Cosa fa il pulsante grande, detto a parole: e l'unica cosa che uno
  /// screen reader puo leggere, perche il pulsante e una forma con un'icona.
  final String? etichettaPrimario;
  final VoidCallback? onSinistra;
  final IconData? iconaSinistra;
  final String? etichettaSinistra;
  final VoidCallback? onDestra;
  final IconData? iconaDestra;
  final String? etichettaDestra;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    Widget secondario(IconData icona, VoidCallback? azione, String? etichetta) {
      return Semantics(
        label: etichetta,
        button: true,
        child: IconButton(
          onPressed: azione,
          iconSize: t.sizing.iconLg,
          style: IconButton.styleFrom(
            minimumSize: Size.square(t.sizing.minTouchTarget),
            backgroundColor: scheme.surfaceContainerHigh,
            foregroundColor: azione == null
                ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
                : scheme.onSurfaceVariant,
            shape: const CircleBorder(),
          ),
          icon: Icon(icona),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconaSinistra != null)
          secondario(iconaSinistra!, onSinistra, etichettaSinistra),
        SizedBox(width: t.spacing.md),
        // La forma e la larghezza sono animate insieme, con la curva elastica
        // del mockup: «la curva e elastica, non lineare».
        Semantics(
          label: etichettaPrimario,
          button: true,
          child: AnimatedContainer(
          duration: t.motion.standard,
          curve: t.motion.spring,
          width: inCorsa ? kLarghezzaPrimarioInCorsa : kDiametroPrimario,
          height: kDiametroPrimario,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(
              inCorsa ? kRaggioPrimarioInCorsa : kDiametroPrimario / 2,
            ),
            boxShadow: t.elevation.level2(scheme.primary),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPrimario,
              borderRadius: BorderRadius.circular(
                inCorsa ? kRaggioPrimarioInCorsa : kDiametroPrimario / 2,
              ),
              child: Icon(
                inCorsa ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: scheme.onPrimary,
                size: t.sizing.iconLg,
              ),
            ),
          ),
        ),
        ),
        SizedBox(width: t.spacing.md),
        if (iconaDestra != null)
          secondario(iconaDestra!, onDestra, etichettaDestra),
      ],
    );
  }
}
