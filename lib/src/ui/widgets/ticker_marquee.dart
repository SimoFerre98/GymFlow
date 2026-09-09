import 'package:flutter/material.dart';
import '../../core/theme/immersivo_tokens.dart';
/// La striscia che scorre fra due filetti — Home, Cronometro, Riepilogo nel
/// mockup Immersivo (`RECORD PANCA 92,5 KG / 4 SU 5 SESSIONI / ...`).
///
/// Il testo scorre a velocita costante e senza soluzione di continuita: la
/// stessa stringa (con [separator] in coda) e disegnata tre volte una dopo
/// l'altra, e l'animazione trasla di esattamente una copia prima di ripartire
/// da zero — la seconda copia occupa gia il posto della prima, quindi il
/// salto non si vede. La terza e un margine di sicurezza per gli schermi piu
/// larghi di una copia sola.
class TickerMarquee extends StatefulWidget {
  const TickerMarquee({
    super.key,
    required this.text,
    this.color,
    this.duration = const Duration(seconds: 12),
    this.separator = '   /   ',
  });
  /// Il testo che scorre, senza il separatore finale: lo aggiunge il widget.
  final String text;
  /// Colore del testo e dei due filetti. Di default l'accento del tema.
  final Color? color;
  /// Tempo per percorrere una copia intera. Piu lungo per i testi piu
  /// lunghi, cosi la velocita percepita resta simile.
  final Duration duration;
  final String separator;
  @override
  State<TickerMarquee> createState() => _TickerMarqueeState();
}
class _TickerMarqueeState extends State<TickerMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }
  @override
  void didChangeDependencies() {
    // Non in `initState`: `MediaQuery.of` iscrive questo widget ai suoi
    // cambiamenti, e farlo prima che `initState` sia finito e un errore.
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations && !_controller.isAnimating) {
      _controller.repeat();
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final colore = widget.color ?? scheme.primary;
    final stile =
        (t.typography.eyebrow ?? Theme.of(context).textTheme.labelSmall)
            ?.copyWith(color: colore, fontSize: 14, letterSpacing: 1.0);
    final unaCopia = '${widget.text}${widget.separator}';
    final painter = TextPainter(
      text: TextSpan(text: unaCopia, style: stile),
      textDirection: Directionality.of(context),
    )..layout();
    final larghezzaCopia = painter.width;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: colore, width: 1),
        ),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned(
                  left: -_controller.value * larghezzaCopia,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(unaCopia, style: stile, maxLines: 1, softWrap: false),
                      Text(unaCopia, style: stile, maxLines: 1, softWrap: false),
                      Text(unaCopia, style: stile, maxLines: 1, softWrap: false),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
