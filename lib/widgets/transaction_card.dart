import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart' as isar_models;
import 'package:stackwallet/models/paymint/transactions_model.dart' as old;
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/tx_icon.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:tuple/tuple.dart';

import '../providers/blockchain/dogecoin/current_height_provider.dart';

class TransactionCard extends ConsumerStatefulWidget {
  const TransactionCard({
    Key? key,
    required this.transaction,
    required this.walletId,
  }) : super(key: key);

  final old.Transaction transaction;
  final String walletId;

  @override
  ConsumerState<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends ConsumerState<TransactionCard> {
  late final old.Transaction _transaction;
  late final String walletId;

  String whatIsIt(String type, Coin coin) {
    if (coin == Coin.epicCash && _transaction.slateId == null) {
      return "Restored Funds";
    }

    if (_transaction.subType == "mint") {
      // if (type == "Received") {
      if (_transaction.confirmedStatus) {
        return "Anonymized";
      } else {
        return "Anonymizing";
      }
      // } else if (type == "Sent") {
      //   if (_transaction.confirmedStatus) {
      //     return "Sent MINT";
      //   } else {
      //     return "Sending MINT";
      //   }
      // } else {
      //   return type;
      // }
    }

    if (type == "Received") {
      // if (_transaction.isMinting) {
      //   return "Minting";
      // } else
      if (_transaction.confirmedStatus) {
        return "Received";
      } else {
        return "Receiving";
      }
    } else if (type == "Sent") {
      if (_transaction.confirmedStatus) {
        return "Sent";
      } else {
        return "Sending";
      }
    } else {
      return type;
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    _transaction = widget.transaction;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId)));

    final baseCurrency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    final coin = manager.coin;

    final price = ref
        .watch(priceAnd24hChangeNotifierProvider
            .select((value) => value.getPrice(coin)))
        .item1;

    String prefix = "";
    if (Util.isDesktop) {
      if (_transaction.txType == "Sent") {
        prefix = "-";
      } else if (_transaction.txType == "Received") {
        prefix = "+";
      }
    }

    return Material(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(Constants.size.circularBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: RawMaterialButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: () async {
            if (coin == Coin.epicCash && _transaction.slateId == null) {
              unawaited(showFloatingFlushBar(
                context: context,
                message:
                    "Restored Epic funds from your Seed have no Data.\nUse Stack Backup to keep your transaction history.",
                type: FlushBarType.warning,
                duration: const Duration(seconds: 5),
              ));
              return;
            }
            if (Util.isDesktop) {
              await showDialog<void>(
                context: context,
                builder: (context) => DesktopDialog(
                  maxHeight: MediaQuery.of(context).size.height - 64,
                  maxWidth: 580,
                  child: TransactionDetailsView(
                    transaction: _transaction,
                    coin: coin,
                    walletId: walletId,
                  ),
                ),
              );
            } else {
              unawaited(
                Navigator.of(context).pushNamed(
                  TransactionDetailsView.routeName,
                  arguments: Tuple3(
                    _transaction,
                    coin,
                    walletId,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                TxIcon(transaction: _transaction),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _transaction.isCancelled
                                    ? "Cancelled"
                                    : whatIsIt(_transaction.txType, coin),
                                style: STextStyles.itemSubtitle12(context),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Builder(
                                builder: (_) {
                                  final amount = _transaction.amount;
                                  return Text(
                                    "$prefix${Format.satoshiAmountToPrettyString(amount, locale, coin)} ${coin.ticker}",
                                    style:
                                        STextStyles.itemSubtitle12_600(context),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Format.extractDateFrom(_transaction.timestamp),
                                style: STextStyles.label(context),
                              ),
                            ),
                          ),
                          if (ref.watch(prefsChangeNotifierProvider
                              .select((value) => value.externalCalls)))
                            const SizedBox(
                              width: 10,
                            ),
                          if (ref.watch(prefsChangeNotifierProvider
                              .select((value) => value.externalCalls)))
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Builder(
                                  builder: (_) {
                                    int value = _transaction.amount;

                                    return Text(
                                      "$prefix${Format.localizedStringAsFixed(
                                        value: Format.satoshisToAmount(value,
                                                coin: coin) *
                                            price,
                                        locale: locale,
                                        decimalPlaces: 2,
                                      )} $baseCurrency",
                                      style: STextStyles.label(context),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionCard2 extends ConsumerStatefulWidget {
  const TransactionCard2({
    Key? key,
    required this.transaction,
    required this.walletId,
  }) : super(key: key);

  final isar_models.Transaction transaction;
  final String walletId;

  @override
  ConsumerState<TransactionCard2> createState() => _TransactionCardState2();
}

class _TransactionCardState2 extends ConsumerState<TransactionCard2> {
  late final isar_models.Transaction _transaction;
  late final String walletId;

  String whatIsIt(
    isar_models.TransactionType type,
    Coin coin,
    int currentHeight,
  ) {
    if (coin == Coin.epicCash && _transaction.slateId == null) {
      return "Restored Funds";
    }

    final confirmedStatus = _transaction.isConfirmed(
      currentHeight,
      coin.requiredConfirmations,
    );

    if (_transaction.subType == isar_models.TransactionSubType.mint) {
      // if (type == "Received") {
      if (confirmedStatus) {
        return "Anonymized";
      } else {
        return "Anonymizing";
      }
      // } else if (type == "Sent") {
      //   if (_transaction.confirmedStatus) {
      //     return "Sent MINT";
      //   } else {
      //     return "Sending MINT";
      //   }
      // } else {
      //   return type;
      // }
    }

    if (type == isar_models.TransactionType.incoming) {
      // if (_transaction.isMinting) {
      //   return "Minting";
      // } else
      if (confirmedStatus) {
        return "Received";
      } else {
        return "Receiving";
      }
    } else if (type == isar_models.TransactionType.outgoing) {
      if (confirmedStatus) {
        return "Sent";
      } else {
        return "Sending";
      }
    } else {
      return type.name;
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    _transaction = widget.transaction;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId)));

    final baseCurrency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    final coin = manager.coin;

    final price = ref
        .watch(priceAnd24hChangeNotifierProvider
            .select((value) => value.getPrice(coin)))
        .item1;

    String prefix = "";
    if (Util.isDesktop) {
      if (_transaction.type == isar_models.TransactionType.outgoing) {
        prefix = "-";
      } else if (_transaction.type == isar_models.TransactionType.incoming) {
        prefix = "+";
      }
    }

    final currentHeight = ref.watch(currentHeightProvider(coin).state).state;

    return Material(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(Constants.size.circularBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: RawMaterialButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: () async {
            if (coin == Coin.epicCash && _transaction.slateId == null) {
              unawaited(showFloatingFlushBar(
                context: context,
                message:
                    "Restored Epic funds from your Seed have no Data.\nUse Stack Backup to keep your transaction history.",
                type: FlushBarType.warning,
                duration: const Duration(seconds: 5),
              ));
              return;
            }
            if (Util.isDesktop) {
              // await showDialog<void>(
              //   context: context,
              //   builder: (context) => DesktopDialog(
              //     maxHeight: MediaQuery.of(context).size.height - 64,
              //     maxWidth: 580,
              //     child: TransactionDetailsView(
              //       transaction: _transaction,
              //       coin: coin,
              //       walletId: walletId,
              //     ),
              //   ),
              // );
            } else {
              unawaited(
                Navigator.of(context).pushNamed(
                  TransactionDetailsView.routeName,
                  arguments: Tuple3(
                    _transaction,
                    coin,
                    walletId,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                TxIcon2(
                  transaction: _transaction,
                  coin: ref.watch(walletsChangeNotifierProvider.select(
                      (value) => value.getManager(widget.walletId).coin)),
                  currentHeight: currentHeight,
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _transaction.isCancelled
                                    ? "Cancelled"
                                    : whatIsIt(
                                        _transaction.type,
                                        coin,
                                        currentHeight,
                                      ),
                                style: STextStyles.itemSubtitle12(context),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Builder(
                                builder: (_) {
                                  final amount = _transaction.amount;
                                  return Text(
                                    "$prefix${Format.satoshiAmountToPrettyString(amount, locale, coin)} ${coin.ticker}",
                                    style:
                                        STextStyles.itemSubtitle12_600(context),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Format.extractDateFrom(_transaction.timestamp),
                                style: STextStyles.label(context),
                              ),
                            ),
                          ),
                          if (ref.watch(prefsChangeNotifierProvider
                              .select((value) => value.externalCalls)))
                            const SizedBox(
                              width: 10,
                            ),
                          if (ref.watch(prefsChangeNotifierProvider
                              .select((value) => value.externalCalls)))
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Builder(
                                  builder: (_) {
                                    int value = _transaction.amount;

                                    return Text(
                                      "$prefix${Format.localizedStringAsFixed(
                                        value: Format.satoshisToAmount(value,
                                                coin: coin) *
                                            price,
                                        locale: locale,
                                        decimalPlaces: 2,
                                      )} $baseCurrency",
                                      style: STextStyles.label(context),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
