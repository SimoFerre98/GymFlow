import 'dart:ui';

import 'package:flutter/material.dart';

/// Lo sfondo della schermata del tempo: tre masse sfocate che galleggiano
/// lentamente, dal mockup 03 (`.aura`). Non e decorazione fine a se stessa —
/// e la differenza fra "un quadrante su una schermata vuota" e "un'app da
/// palestra": senza, la sensazione segnalata e proprio quella di piattezza.
///
/// Le dimensioni sono i pixel del mockup 03 convertiti — `dp = px × 1,20`,
/// DESIGN-SPEC — non copiati: 210px→252, 190px→228, 150px→180, blur 38px→46.
///
/// Un solo `AnimationController` per le tre masse, non tre: e lo stesso
/// ticker, sfasato per massa con una velocita relativa, invece di tre
/// `Ticker` che girano a vuoto quando la schermata e sotto altre due.
class TimerAurora extends StatefulWidget {
  const TimerAurora({super.key});

  @override
  State<TimerAurora> createState() => _TimerAuroraState();
}

class _TimerAuroraState extends State<TimerAurora>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Il piu lento delle tre curve del mockup (20s): le altre si sfasano
      // dentro lo stesso giro invece di avere ciascuna il proprio periodo,
      // che avrebbe richiesto tre controller.
      duration: const Duration(seconds: 20),
    );
  }

  @override
  void didChangeDependencies() {
    // Non in `initState`: `MediaQuery.of` iscrive questo widget ai suoi
    // cambiamenti, e farlo prima che `initState` sia finito e un errore —
    // `didChangeDependencies` e il posto giusto, e gira anche la prima volta.
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              children: [
                _Massa(
                  top: -60,
                  right: -72,
                  diametro: 252,
                  colore: scheme.primary.withValues(alpha: 0.30),
                  spostamento: t, // 14s: la piu rapida delle tre.
                  direzione: const Offset(-1, 1),
                ),
                _Massa(
                  bottom: 72,
                  left: -84,
                  diametro: 228,
                  colore: scheme.tertiary.withValues(alpha: 0.24),
                  spostamento: 1 - t, // 17s, in controfase.
                  direzione: const Offset(1, -1),
                ),
                _Massa(
                  top: 280,
                  right: -60,
                  diametro: 180,
                  // indigo600: la stessa massa neutra del mockup
                  // (rgba(90,83,132,.5)), letta dal ruolo invece che a mano.
                  colore: scheme.outline.withValues(alpha: 0.5),
                  spostamento: 1 - t, // 20s «reverse»: la curva di a1 al contrario.
                  direzione: const Offset(-1, 1),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Massa extends StatelessWidget {
  const _Massa({
    required this.diametro,
    required this.colore,
    required this.spostamento,
    required this.direzione,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double diametro;
  final Color colore;

  /// 0→1→0 nel tempo, dal controller condiviso.
  final double spostamento;

  /// Verso del moto: il mockup sposta ogni massa in una diagonale diversa.
  final Offset direzione;

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    final scala = 1.0 + spostamento * 0.14;
    final dx = direzione.dx * spostamento * 26;
    final dy = direzione.dy * spostamento * 28;

    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scala,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
            child: Container(
              width: diametro,
              height: diametro,
              decoration: BoxDecoration(shape: BoxShape.circle, color: colore),
            ),
          ),
        ),
      ),
    );
  }
}
