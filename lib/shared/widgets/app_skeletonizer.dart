import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Centralized skeletonizer wrapper for the entire app.
/// Handles theme colors, reduced motion, and performance optimizations.
class AppSkeletonizer extends StatelessWidget {
  const AppSkeletonizer({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final skeletonEnabled = enabled && !disableAnimations;

    Widget skeleton = Skeletonizer(
      enabled: skeletonEnabled,
      enableSwitchAnimation: true,
      effect: ShimmerEffect(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        duration: const Duration(milliseconds: 1200),
      ),
      child: child,
    );

    if (skeletonEnabled) {
      skeleton = RepaintBoundary(child: skeleton);
    }

    return skeleton;
  }
}
