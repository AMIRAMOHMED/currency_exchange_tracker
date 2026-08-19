import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';

typedef RefreshSnack = ({DateTime at, String text, bool ok});

const refreshCooldown = Duration(minutes: 2);
const alreadyUpToDateText = 'Already up to date';
const refreshFailedText = "Couldn't refresh — check your connection";

RefreshSnack refreshSnack(String text, {bool ok = true}) =>
    (at: DateTime.now(), text: text, ok: ok);

bool isRefreshCoolingDown(DateTime? lastRefreshAt) {
  return lastRefreshAt != null &&
      DateTime.now().difference(lastRefreshAt) < refreshCooldown;
}

RefreshSnack updatedRatesSnack(DateTime? rateDate) {
  if (rateDate == null) return refreshSnack('Rates updated');
  final now = DateTime.now();
  final fromToday =
      rateDate.year == now.year &&
      rateDate.month == now.month &&
      rateDate.day == now.day;
  if (fromToday) return refreshSnack('Rates updated');
  return refreshSnack(
    'Up to date — latest rates are from ${DateFormat.MMMd().format(rateDate)}',
  );
}

mixin HasRefreshSnack {
  RefreshSnack? get snack => null;
}

class RefreshSnackListener<B extends BlocBase<S>, S extends HasRefreshSnack>
    extends StatelessWidget {
  const RefreshSnackListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: (previous, current) =>
          current.snack != null && current.snack != previous.snack,
      listener: (context, state) {
        final snack = state.snack!;
        final textTheme = Theme.of(context).textTheme;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    snack.ok
                        ? Icons.check_circle_rounded
                        : Icons.wifi_off_rounded,
                    color: snack.ok ? AppColors.primary500 : AppColors.negative,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(snack.text, style: textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          );
      },
      child: child,
    );
  }
}
