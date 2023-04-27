import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/pages/wallet_view/wallet_view.dart';
import 'package:stackduo/pages/wallets_view/wallets_overview.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/utilities/amount/amount.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';
import 'package:tuple/tuple.dart';

class WalletListItem extends ConsumerWidget {
  const WalletListItem({
    Key? key,
    required this.coin,
    required this.walletCount,
  }) : super(key: key);

  final Coin coin;
  final int walletCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");
    final walletCountString =
        walletCount == 1 ? "$walletCount wallet" : "$walletCount wallets";
    final currency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("walletListItemButtonKey_${coin.name}"),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        onPressed: () async {
          if (walletCount == 1) {
            final providersByCoin = ref
                .watch(walletsChangeNotifierProvider
                    .select((value) => value.getManagerProvidersByCoin()))
                .where((e) => e.item1 == coin)
                .map((e) => e.item2)
                .expand((e) => e)
                .toList();
            final manager = ref.read(providersByCoin.first);
            if (coin == Coin.monero) {
              await manager.initializeExisting();
            }
            if (context.mounted) {
              unawaited(
                Navigator.of(context).pushNamed(
                  WalletView.routeName,
                  arguments: Tuple2(
                    manager.walletId,
                    providersByCoin.first,
                  ),
                ),
              );
            }
          } else {
            unawaited(
              Navigator.of(context).pushNamed(
                WalletsOverview.routeName,
                arguments: coin,
              ),
            );
          }
        },
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.iconFor(coin: coin),
              width: 28,
              height: 28,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Consumer(
                builder: (_, ref, __) {
                  final tuple = ref.watch(priceAnd24hChangeNotifierProvider
                      .select((value) => value.getPrice(coin)));
                  final calls =
                      ref.watch(prefsChangeNotifierProvider).externalCalls;

                  final priceString = tuple.item1
                      .toAmount(fractionDigits: 2)
                      .localizedStringAsFixed(
                        locale: ref.watch(localeServiceChangeNotifierProvider
                            .select((value) => value.locale)),
                      );

                  final double percentChange = tuple.item2;

                  var percentChangedColor =
                      Theme.of(context).extension<StackColors>()!.textDark;
                  if (percentChange > 0) {
                    percentChangedColor = Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorGreen;
                  } else if (percentChange < 0) {
                    percentChangedColor = Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorRed;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            coin.prettyName,
                            style: STextStyles.titleBold12(context),
                          ),
                          const Spacer(),
                          if (calls)
                            Text(
                              "$priceString $currency/${coin.ticker}",
                              style: STextStyles.itemSubtitle(context),
                            ),
                        ],
                      ),
                      const SizedBox(
                        height: 1,
                      ),
                      Row(
                        children: [
                          Text(
                            walletCountString,
                            style: STextStyles.itemSubtitle(context),
                          ),
                          const Spacer(),
                          if (calls)
                            Text(
                              "${percentChange.toStringAsFixed(2)}%",
                              style: STextStyles.itemSubtitle(context).copyWith(
                                color: percentChangedColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
