import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/expressive_tokens.dart';

/// Catalogo dei token del design system, visibile solo nelle build di debug.
///
/// Serve a due cose: vedere i token invece di immaginarli quando si sceglie
/// quale usare, e accorgersi subito se una modifica al design system rompe
/// qualcosa. Man mano che EP-005 aggiunge forme, componenti e movimento,
/// questa schermata cresce con loro.
///
/// L'accesso e protetto da [kDebugMode]: nelle build di release la voce non
/// compare nel menu e la schermata non e raggiungibile.
class DesignCatalogScreen extends StatelessWidget {
  const DesignCatalogScreen({super.key});

  /// Vero solo nelle build di debug: usato da chi mostra la voce di menu.
  static bool get isAvailable => kDebugMode;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Design system')),
      body: ListView(
        padding: EdgeInsets.all(t.spacing.xl),
        children: [
          _Section(title: 'Colore', children: [_ColorRoles(scheme: scheme)]),
          _Section(title: 'Spaziature', children: [_SpacingScale(tokens: t)]),
          _Section(title: 'Forme', children: [_ShapeScale(tokens: t)]),
          _Section(
            title: 'Elevazioni',
            children: [_ElevationScale(tokens: t, scheme: scheme)],
          ),
          _Section(title: 'Movimento', children: [_MotionScale(tokens: t)]),
          SizedBox(height: t.spacing.bottomInset),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: t.spacing.xl, bottom: t.spacing.md),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ColorRoles extends StatelessWidget {
  const _ColorRoles({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final roles = <String, Color>{
      'primary': scheme.primary,
      'onPrimary': scheme.onPrimary,
      'secondary': scheme.secondary,
      'surface': scheme.surface,
      'onSurface': scheme.onSurface,
      'error': scheme.error,
    };

    return Wrap(
      spacing: t.spacing.sm,
      runSpacing: t.spacing.sm,
      children: roles.entries.map((e) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 48,
              decoration: BoxDecoration(
                color: e.value,
                borderRadius: t.shape.cornerSm,
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.15),
                ),
              ),
            ),
            SizedBox(height: t.spacing.xs),
            SizedBox(
              width: 72,
              child: Text(
                e.key,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _SpacingScale extends StatelessWidget {
  const _SpacingScale({required this.tokens});

  final ExpressiveTokens tokens;

  @override
  Widget build(BuildContext context) {
    final s = tokens.spacing;
    final steps = <String, double>{
      'xs': s.xs,
      'sm': s.sm,
      'md': s.md,
      'lg': s.lg,
      'xl': s.xl,
      'xxl': s.xxl,
    };

    return Column(
      children: steps.entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: s.sm),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(e.key, style: Theme.of(context).textTheme.bodySmall),
              ),
              Container(
                width: e.value,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: tokens.shape.cornerXs,
                ),
              ),
              SizedBox(width: s.sm),
              Text(
                '${e.value.toStringAsFixed(0)} dp',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ShapeScale extends StatelessWidget {
  const _ShapeScale({required this.tokens});

  final ExpressiveTokens tokens;

  @override
  Widget build(BuildContext context) {
    final sh = tokens.shape;
    final shapes = <String, BorderRadius>{
      'xs': sh.cornerXs,
      'sm': sh.cornerSm,
      'md': sh.cornerMd,
      'lg': sh.cornerLg,
      'xl': sh.cornerXl,
      'full': sh.cornerFull,
    };

    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.sm,
      children: shapes.entries.map((e) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: e.value,
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(e.key, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}

class _ElevationScale extends StatelessWidget {
  const _ElevationScale({required this.tokens, required this.scheme});

  final ExpressiveTokens tokens;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final el = tokens.elevation;
    final levels = <String, List<BoxShadow>>{
      'level1': el.level1(scheme.shadow),
      'level2': el.level2(scheme.shadow),
      'level3': el.level3(scheme.shadow),
    };

    return Wrap(
      spacing: tokens.spacing.xl,
      runSpacing: tokens.spacing.xl,
      children: levels.entries.map((e) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: tokens.shape.cornerLg,
                boxShadow: e.value,
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
            Text(e.key, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}

/// Mostra le durate facendole vedere: ogni barra percorre la propria
/// larghezza nel tempo del token, cosi la differenza si osserva invece di
/// doverla immaginare leggendo un numero.
class _MotionScale extends StatefulWidget {
  const _MotionScale({required this.tokens});

  final ExpressiveTokens tokens;

  @override
  State<_MotionScale> createState() => _MotionScaleState();
}

class _MotionScaleState extends State<_MotionScale> {
  bool _moved = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final m = t.motion;
    final durations = <String, Duration>{
      'instant': m.instant,
      'quick': m.quick,
      'standard': m.standard,
      'emphasized': m.emphasized,
      'expressive': m.expressive,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...durations.entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(bottom: t.spacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    e.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: _moved
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: e.value,
                      curve: m.standardCurve,
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: t.shape.cornerFull,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${e.value.inMilliseconds} ms',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: t.spacing.sm),
        FilledButton.tonal(
          onPressed: () => setState(() => _moved = !_moved),
          child: const Text('Anima'),
        ),
      ],
    );
  }
}
