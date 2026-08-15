import 'package:flutter/material.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';

/// Circular flag image used across currency list and detail views.
class CurrencyFlagAvatar extends StatelessWidget {
  const CurrencyFlagAvatar({
    super.key,
    required this.flagAsset,
    this.radius = 24,
  });

  final String flagAsset;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.border,
      child: ClipOval(
        child: Image.asset(
          flagAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.flag,
            color: AppColors.textSecondary,
            size: radius,
          ),
        ),
      ),
    );
  }
}
