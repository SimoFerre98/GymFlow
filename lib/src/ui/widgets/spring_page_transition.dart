import 'package:flutter/material.dart';

import 'package:gymflow/src/core/theme/expressive_tokens.dart';

/// Fa assestare con una molla il contenuto che entra, **senza smontare gli
/// altri**.
///
/// Esiste come widget proprio, e non come due righe dentro `MainScreen`, per due
/// ragioni.
///
/// **La prima e un difetto misurato.** Avvolgere l'`IndexedStack` delle voci in
/// un `AnimatedSwitcher` con una chiave che cambia sembra la strada breve, ma la
/// chiave nuova fa costruire un albero nuovo: a ogni cambio voce **tutte** le
/// schermate vengono smontate e ricreate. Misurato con un contatore nel `State`
/// dei figli: da **una** creazione a **tre** su tre cambi voce. Sulle schermate
/// vere significa rifare le query di Firestore e la lettura di Salute a ogni
/// tocco, e perdere la posizione di scorrimento. Qui l'albero dei figli non
/// cambia mai identita: si anima solo una trasformazione sopra.
///
/// **La seconda e che cosi si puo provare.** `MainScreen` monta dashboard e
/// calendario, che dipendono da Firebase e da Isar e non si montano in un test —
/// il limite dichiarato nella review di US-008. Questo widget invece si monta con
/// un figlio qualunque, e permette di verificare sia che animi sia che **non**
/// ricostruisca il figlio.
class SpringPageTransition extends StatefulWidget {
  const SpringPageTransition({
    super.key,
    required this.index,
    required this.child,
  });

  /// La voce attiva. Quando cambia, la molla riparte.
  final int index;

  /// Il contenuto, che **non** viene mai ricostruito da questo widget.
  final Widget child;

  @override
  State<SpringPageTransition> createState() => _SpringPageTransitionState();
}

class _SpringPageTransitionState extends State<SpringPageTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Parte a riposo: al primo frame non c'e niente da assestare, e la voce
    // iniziale non deve entrare in scena.
    _controller = AnimationController(vsync: this, value: 1);
  }

  @override
  void didUpdateWidget(SpringPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.duration = context.expressive.motion.standard;
      // `from: 0` e non `forward()`: un cambio voce durante l'assestamento
      // precedente riparte, invece di essere ignorato perche l'animazione era
      // gia in corsa.
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      // Nessun assestamento: il contenuto e subito a posto. Non basta azzerare
      // la durata, perche un'animazione a durata zero fa comunque passare un
      // frame trasformato.
      return widget.child;
    }

    final molla = context.expressive.motion.spring;

    return AnimatedBuilder(
      animation: _controller,
      // Il figlio si passa a `AnimatedBuilder` invece di costruirlo dentro
      // `builder`: cosi non viene ricostruito a ogni frame dell'animazione.
      child: widget.child,
      builder: (context, child) {
        final t = molla.transform(_controller.value);

        // La molla supera l'unita — arriva a 1,098 — e qui e voluto: la scala
        // sfora l'identita di un soffio e ci torna, che e cio che si vede come
        // «molla». Su un'opacita non si vedrebbe, perche l'eccedenza viene
        // troncata da `getAlphaFromOpacity`.
        return Transform.translate(
          offset: Offset(0, (1 - t) * context.expressive.spacing.sm),
          child: Transform.scale(
            scale: 0.96 + 0.04 * t,
            child: child,
          ),
        );
      },
    );
  }
}
