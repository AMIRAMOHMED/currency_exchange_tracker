import 'package:flutter/material.dart';

class ChartWeekSectionHeader extends StatelessWidget {
  const ChartWeekSectionHeader({
    super.key,
    this.title = 'Past 7 Days',
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
