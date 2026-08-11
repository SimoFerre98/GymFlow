import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/expressive_tokens.dart';

class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, AppPalette.success, Icons.check_circle);
  }

  static void showError(BuildContext context, String message) {
    _showToast(context, message, AppPalette.danger, Icons.error);
  }

  static void showInfo(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    // Nessun ruolo semantico "info" in AppPalette: `secondary` e l'indaco
    // riservato agli "elementi di supporto che non sono azioni", che e
    // esattamente il ruolo di questo avviso.
    _showToast(context, message, scheme.secondary, Icons.info);
  }

  static void _showToast(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + t.spacing.xl,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(
                      0.0,
                      1.0,
                    ), // Clamp to prevent assertion error
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: t.spacing.md,
                  vertical: t.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: t.shape.cornerFull,
                  boxShadow: t.elevation.level2(scheme.shadow),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: t.sizing.iconMd),
                    SizedBox(width: t.spacing.sm),
                    Flexible(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
