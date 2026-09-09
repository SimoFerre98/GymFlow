import 'dart:ui';
import 'package:flutter/material.dart';
/// Sfondo con masse sfocate che galleggiano lentamente — il bagliore
/// ambientale ricorrente di "Immersivo" (mockup 2a/2b/2c: `{{glow}}`). Non e
/// decorazione fine a se stessa: e la differenza fra "un quadrante su una
/// schermata vuota" e "un'app da palestra".
///
/// Nato per la sola schermata del tempo (da qui il nome e le dimensioni di
/// default, i pixel del mockup 03 convertiti — `dp = px × 1,20`: 210px→252,
/// 190px→228, 150px→180, blur 38px→46), ora generalizzato: [colors] sceglie
/// quante masse disegnare e con quale tinta, cosi altre schermate (Home,
/// Impostazioni, Obiettivi) possono riusarlo con i propri accenti invece di
/// duplicarlo.
///
/// Un solo `AnimationController` per tutte le masse, non uno a testa: e lo
/// stesso ticker, sfasato per massa con una velocita relativa, invece di piu
/// `Ticker` che girano a vuoto quando la schermata e sotto altre.
class TimerAurora extends StatefulWidget {
  const TimerAurora({super.key, this.colors});
  /// Una tinta per massa, nell'ordine in cui compaiono. `null` usa le tre
  /// masse originarie del mockup 03 (primary/tertiary/outline del tema).
  final List<Color>? colors;
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
  /// Posizione, diametro, verso e fase di ogni massa, nell'ordine in cui i
  /// colori vengono assegnati. Piu voci di quante ne servano: [_layouts]
  /// e ciclico (`%`), cosi un chiamante con due tinte prende solo le prime
  /// due invece di un errore fuori indice.
  static const _layouts = [
    (top: -60.0, right: -72.0, bottom: null, left: null, diametro: 252.0, direzione: Offset(-1, 1), reverse: false),
    (top: null, right: null, bottom: 72.0, left: -84.0, diametro: 228.0, direzione: Offset(1, -1), reverse: true),
    (top: 280.0, right: -60.0, bottom: null, left: null, diametro: 180.0, direzione: Offset(-1, 1), reverse: true),
    (top: null, right: -50.0, bottom: -70.0, left: null, diametro: 210.0, direzione: Offset(-1, -1), reverse: false),
  ];
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colori =
        widget.colors ??
        [
          scheme.primary.withValues(alpha: 0.30),
          scheme.tertiary.withValues(alpha: 0.24),
          // indigo600 originario: la stessa massa neutra del mockup
          // (rgba(90,83,132,.5)), letta dal ruolo invece che a mano.
          scheme.outline.withValues(alpha: 0.5),
        ];
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              children: [
                for (var i = 0; i < colori.length; i++)
                  Builder(
                    builder: (_) {
                      final l = _layouts[i % _layouts.length];
                      return _Massa(
                        top: l.top,
                        right: l.right,
                        bottom: l.bottom,
                        left: l.left,
                        diametro: l.diametro,
                        colore: colori[i],
                        spostamento: l.reverse ? 1 - t : t,
                        direzione: l.direzione,
                      );
                    },
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
