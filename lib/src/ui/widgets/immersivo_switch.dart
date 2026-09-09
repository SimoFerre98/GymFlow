import 'package:flutter/material.dart';
import '../../core/theme/immersivo_tokens.dart';
/// L'interruttore ad angoli vivi del linguaggio "Immersivo".
///
/// `Switch` di Material è strutturalmente circolare — pista a stadio, thumb
/// tondo — e non lo si squadra con `SwitchThemeData`: da qui il widget
/// proprio, per rispettare quanto dice `immersivo_tokens.dart` ("il mockup
/// non arrotonda quasi nulla — non i pulsanti, non i riquadri, non gli
/// interruttori").
class ImmersivoSwitch extends StatelessWidget {
  const ImmersivoSwitch({super.key, required this.value, this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;
  static const double _trackWidth = 44;
  static const double _trackHeight = 24;
  static const double _thumbSide = 16;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: t.motion.quick,
          curve: t.motion.standardCurve,
          width: _trackWidth,
          height: _trackHeight,
          padding: EdgeInsets.all(t.spacing.xs / 2),
          decoration: BoxDecoration(
            color: value ? scheme.primary : scheme.surfaceContainerHigh,
            border: Border.all(color: value ? scheme.primary : scheme.outline),
            boxShadow: value ? t.elevation.level1(scheme.primary) : t.elevation.none,
          ),
          child: AnimatedAlign(
            duration: t.motion.quick,
            curve: t.motion.standardCurve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _thumbSide,
              height: _thumbSide,
              color: value ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
