import 'package:flutter/material.dart';

import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';

class RatesDisclaimer extends StatelessWidget {
  const RatesDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Rates are indicative and for informational purposes only.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
