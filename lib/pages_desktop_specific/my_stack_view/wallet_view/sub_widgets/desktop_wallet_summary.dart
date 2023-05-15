import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/models/balance.dart';
import 'package:stackduo/pages/wallet_view/sub_widgets/wallet_refresh_button.dart';
import 'package:stackduo/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_balance_toggle_button.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:stackduo/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackduo/utilities/amount/amount.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/themes/stack_colors.dart';

class DesktopWalletSummary extends ConsumerStatefulWidget {
  const DesktopWalletSummary({
    Key? key,
    required this.walletId,
    required this.initialSyncStatus,
  }) : super(key: key);

  final String walletId;
  final WalletSyncStatus initialSyncStatus;

  @override
  ConsumerState<DesktopWalletSummary> createState() =>
      _WDesktopWalletSummaryState();
}

class _WDesktopWalletSummaryState extends ConsumerState<DesktopWalletSummary> {
  late final String walletId;

  @override
  void initState() {
    walletId = widget.walletId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final externalCalls = ref.watch(
      prefsChangeNotifierProvider.select(
        (value) => value.externalCalls,
      ),
    );
    final coin = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManager(widget.walletId).coin,
      ),
    );
    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    final baseCurrency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    final priceTuple = ref.watch(priceAnd24hChangeNotifierProvider
        .select((value) => value.getPrice(coin)));

    final _showAvailable =
        ref.watch(walletBalanceToggleStateProvider.state).state ==
            WalletBalanceToggleState.available;

    final unit = coin.ticker;
    final decimalPlaces = coin.decimals;

    Balance balance = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId).balance));

    Amount balanceToShow;

    if (_showAvailable) {
      balanceToShow = balance.spendable;
    } else {
      balanceToShow = balance.total;
    }

    return Consumer(
      builder: (context, ref, __) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${balanceToShow.localizedStringAsFixed(
                      locale: locale,
                      decimalPlaces: decimalPlaces,
                    )} $unit",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                if (externalCalls)
                  Text(
                    "${Amount.fromDecimal(
                      priceTuple.item1 * balanceToShow.decimal,
                      fractionDigits: 2,
                    ).localizedStringAsFixed(
                      locale: locale,
                      decimalPlaces: 2,
                    )} $baseCurrency",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle1,
                    ),
                  ),
              ],
            ),
            const SizedBox(
              width: 8,
            ),
            WalletRefreshButton(
              walletId: walletId,
              initialSyncStatus: widget.initialSyncStatus,
            ),
            const SizedBox(
              width: 8,
            ),
            const DesktopBalanceToggleButton(),
          ],
        );
      },
    );
  }
}
