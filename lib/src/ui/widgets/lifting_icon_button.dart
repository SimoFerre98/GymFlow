import 'package:flutter/material.dart';

import '../../core/theme/expressive_tokens.dart';

/// «Gruppo di pulsanti», dal repertorio del mockup 03: al tocco si solleva e
/// si arrotonda, invece di illuminarsi soltanto. Il mockup lo scrive per
/// `:hover`, che sul telefono non esiste: qui l'equivalente e la pressione
/// del dito, non il passaggio del mouse.
///
/// Un'icona alla volta, non un gruppo che reagisce insieme — e il punto della
/// nota originale: «si sollevano uno per volta, invece di illuminarsi tutti».
class LiftingIconButton extends StatefulWidget {
  const LiftingIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.pressedColor,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;

  /// Colore dell'icona a riposo. Assente, prende `onSurfaceVariant` — il
  /// neutro delle azioni che non sono "cosa fare adesso".
  final Color? color;

  /// Sfondo mentre e premuto. Assente, prende `scheme.primary`: qui l'ambra
  /// e legittima, perche segna esattamente l'istante dell'azione — non uno
  /// stato che resta acceso dopo.
  final Color? pressedColor;

  final String? semanticLabel;

  @override
  State<LiftingIconButton> createState() => _LiftingIconButtonState();
}

class _LiftingIconButtonState extends State<LiftingIconButton> {
  bool _premuto = false;

  void _imposta(bool valore) {
    if (widget.onTap == null) return;
    setState(() => _premuto = valore);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final coloreRiposo = widget.color ?? scheme.onSurfaceVariant;
    final coloreAttivo = widget.pressedColor ?? scheme.primary;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: widget.onTap != null,
      child: GestureDetector(
        onTapDown: (_) => _imposta(true),
        onTapUp: (_) => _imposta(false),
        onTapCancel: () => _imposta(false),
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: t.motion.quick,
          curve: t.motion.spring,
          offset: _premuto ? const Offset(0, -0.18) : Offset.zero,
          child: AnimatedContainer(
            duration: t.motion.quick,
            curve: t.motion.spring,
            width: t.sizing.minTouchTarget,
            height: t.sizing.minTouchTarget,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _premuto
                  ? coloreAttivo
                  : scheme.onSurface.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              size: t.sizing.iconMd,
              color: _premuto ? scheme.onPrimary : coloreRiposo,
            ),
          ),
        ),
      ),
    );
  }
}
