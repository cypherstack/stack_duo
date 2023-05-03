import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackduo/models/exchange/incomplete_exchange.dart';
import 'package:stackduo/notifications/show_flush_bar.dart';
import 'package:stackduo/pages/exchange_view/confirm_change_now_send.dart';
import 'package:stackduo/pages/exchange_view/send_from_view.dart';
import 'package:stackduo/pages/exchange_view/sub_widgets/step_row.dart';
import 'package:stackduo/pages/home_view/home_view.dart';
import 'package:stackduo/pages/send_view/sub_widgets/building_transaction_dialog.dart';
import 'package:stackduo/pages/wallet_view/wallet_view.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/route_generator.dart';
import 'package:stackduo/utilities/amount/amount.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/clipboard_interface.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/rounded_container.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';
import 'package:stackduo/widgets/stack_dialog.dart';
import 'package:tuple/tuple.dart';

class Step4View extends ConsumerStatefulWidget {
  const Step4View({
    Key? key,
    required this.model,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/exchangeStep4";

  final IncompleteExchangeModel model;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<Step4View> createState() => _Step4ViewState();
}

class _Step4ViewState extends ConsumerState<Step4View> {
  late final IncompleteExchangeModel model;
  late final ClipboardInterface clipboard;

  String _statusString = "New";

  Timer? _statusTimer;

  bool _isWalletCoinAndHasWallet(String ticker, WidgetRef ref) {
    try {
      final coin = coinFromTickerCaseInsensitive(ticker);
      return ref
          .read(walletsChangeNotifierProvider)
          .managers
          .where((element) => element.coin == coin)
          .isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updateStatus() async {
    final statusResponse =
        await ref.read(efExchangeProvider).updateTrade(model.trade!);
    String status = "Waiting";
    if (statusResponse.value != null) {
      status = statusResponse.value!.status;
    }

    // extra info if status is waiting
    if (status == "Waiting") {
      status += " for deposit";
    }

    if (mounted) {
      setState(() {
        _statusString = status;
      });
    }
  }

  @override
  void initState() {
    model = widget.model;
    clipboard = widget.clipboard;

    _statusTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _updateStatus();
    });

    super.initState();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _statusTimer = null;
    super.dispose();
  }

  Future<void> _close() async {
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 75));
    }
    if (mounted) {
      Navigator.of(context).popUntil(
        ModalRoute.withName(
          model.walletInitiated ? WalletView.routeName : HomeView.routeName,
        ),
      );
    }
  }

  Future<void> _confirmSend(Tuple2<String, Coin> tuple) async {
    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(tuple.item1);

    final Amount amount = model.sendAmount.toAmount(
      fractionDigits: manager.coin.decimals,
    );
    final address = model.trade!.payInAddress;

    bool wasCancelled = false;
    try {
      if (!mounted) return;

      unawaited(
        showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (context) {
            return BuildingTransactionDialog(
              coin: manager.coin,
              onCancel: () {
                wasCancelled = true;
              },
            );
          },
        ),
      );

      final time = Future<dynamic>.delayed(
        const Duration(
          milliseconds: 2500,
        ),
      );

      Future<Map<String, dynamic>> txDataFuture;

      txDataFuture = manager.prepareSend(
        address: address,
        amount: amount,
        args: {
          "feeRate": FeeRateType.average,
          // ref.read(feeRateTypeStateProvider)
        },
      );

      final results = await Future.wait([
        txDataFuture,
        time,
      ]);

      final txData = results.first as Map<String, dynamic>;

      if (!wasCancelled) {
        // pop building dialog

        if (mounted) {
          Navigator.of(context).pop();
        }

        txData["note"] =
            "${model.trade!.payInCurrency.toUpperCase()}/${model.trade!.payOutCurrency.toUpperCase()} exchange";
        txData["address"] = address;

        if (mounted) {
          unawaited(
            Navigator.of(context).push(
              RouteGenerator.getRoute(
                shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
                builder: (_) => ConfirmChangeNowSendView(
                  transactionInfo: txData,
                  walletId: tuple.item1,
                  routeOnSuccessName: HomeView.routeName,
                  trade: model.trade!,
                ),
                settings: const RouteSettings(
                  name: ConfirmChangeNowSendView.routeName,
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !wasCancelled) {
        // pop building dialog
        Navigator.of(context).pop();

        unawaited(
          showDialog<dynamic>(
            context: context,
            useSafeArea: false,
            barrierDismissible: true,
            builder: (context) {
              return StackDialog(
                title: "Transaction failed",
                message: e.toString(),
                rightButton: TextButton(
                  style: Theme.of(context)
                      .extension<StackColors>()!
                      .getSecondaryEnabledButtonStyle(context),
                  child: Text(
                    "Ok",
                    style: STextStyles.button(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .buttonTextSecondary,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWalletCoin =
        _isWalletCoinAndHasWallet(model.trade!.payInCurrency, ref);
    return WillPopScope(
      onWillPop: () async {
        await _close();
        return false;
      },
      child: Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: AppBarIconButton(
                size: 32,
                color: Theme.of(context).extension<StackColors>()!.background,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.x,
                  width: 24,
                  height: 24,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .topNavIconPrimary,
                ),
                onPressed: _close,
              ),
            ),
            title: Text(
              "Swap",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = MediaQuery.of(context).size.width - 32;
              return Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StepRow(
                              count: 4,
                              current: 3,
                              width: width,
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            Text(
                              "Send ${model.sendTicker.toUpperCase()} to the address below",
                              style: STextStyles.pageTitleH1(context),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              "Send ${model.sendTicker.toUpperCase()} to the address below. Once it is received, ${model.trade!.exchangeName} will send the ${model.receiveTicker.toUpperCase()} to the recipient address you provided. You can find this trade details and check its status in the list of trades.",
                              style: STextStyles.itemSubtitle(context),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            RoundedContainer(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .warningBackground,
                              child: RichText(
                                text: TextSpan(
                                  text:
                                      "You must send at least ${model.sendAmount.toString()} ${model.sendTicker}. ",
                                  style: STextStyles.label700(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .warningForeground,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          "If you send less than ${model.sendAmount.toString()} ${model.sendTicker}, your transaction may not be converted and it may not be refunded.",
                                      style:
                                          STextStyles.label(context).copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .warningForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            RoundedWhiteContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Amount",
                                        style:
                                            STextStyles.itemSubtitle(context),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final data = ClipboardData(
                                              text:
                                                  model.sendAmount.toString());
                                          await clipboard.setData(data);
                                          if (mounted) {
                                            unawaited(
                                              showFloatingFlushBar(
                                                type: FlushBarType.info,
                                                message: "Copied to clipboard",
                                                context: context,
                                              ),
                                            );
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              Assets.svg.copy,
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .infoItemIcons,
                                              width: 10,
                                            ),
                                            const SizedBox(
                                              width: 4,
                                            ),
                                            Text(
                                              "Copy",
                                              style: STextStyles.link2(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    "${model.sendAmount.toString()} ${model.sendTicker.toUpperCase()}",
                                    style: STextStyles.itemSubtitle12(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            RoundedWhiteContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Send ${model.sendTicker.toUpperCase()} to this address",
                                        style:
                                            STextStyles.itemSubtitle(context),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final data = ClipboardData(
                                              text: model.trade!.payInAddress);
                                          await clipboard.setData(data);
                                          if (mounted) {
                                            unawaited(
                                              showFloatingFlushBar(
                                                type: FlushBarType.info,
                                                message: "Copied to clipboard",
                                                context: context,
                                              ),
                                            );
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              Assets.svg.copy,
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .infoItemIcons,
                                              width: 10,
                                            ),
                                            const SizedBox(
                                              width: 4,
                                            ),
                                            Text(
                                              "Copy",
                                              style: STextStyles.link2(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    model.trade!.payInAddress,
                                    style: STextStyles.itemSubtitle12(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            RoundedWhiteContainer(
                              child: Row(
                                children: [
                                  Text(
                                    "Trade ID",
                                    style: STextStyles.itemSubtitle(context),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(
                                        model.trade!.tradeId,
                                        style:
                                            STextStyles.itemSubtitle12(context),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final data = ClipboardData(
                                              text: model.trade!.tradeId);
                                          await clipboard.setData(data);
                                          if (mounted) {
                                            unawaited(
                                              showFloatingFlushBar(
                                                type: FlushBarType.info,
                                                message: "Copied to clipboard",
                                                context: context,
                                              ),
                                            );
                                          }
                                        },
                                        child: SvgPicture.asset(
                                          Assets.svg.copy,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .infoItemIcons,
                                          width: 12,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            RoundedWhiteContainer(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Status",
                                    style: STextStyles.itemSubtitle(context),
                                  ),
                                  Text(
                                    _statusString,
                                    style: STextStyles.itemSubtitle(context)
                                        .copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .colorForStatus(_statusString),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(
                              height: 12,
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog<dynamic>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (_) {
                                    return StackDialogBase(
                                      child: Column(
                                        children: [
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          Center(
                                            child: Text(
                                              "Send ${model.sendTicker} to this address",
                                              style: STextStyles.pageTitleH2(
                                                  context),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 24,
                                          ),
                                          Center(
                                            child: QrImage(
                                              // TODO: grab coin uri scheme from somewhere
                                              // data: "${coin.uriScheme}:$receivingAddress",
                                              data: model.trade!.payInAddress,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2,
                                              foregroundColor: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorDark,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 24,
                                          ),
                                          Row(
                                            children: [
                                              const Spacer(),
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  style: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .getSecondaryEnabledButtonStyle(
                                                          context),
                                                  child: Text(
                                                    "Cancel",
                                                    style: STextStyles.button(
                                                            context)
                                                        .copyWith(
                                                      color: Theme.of(context)
                                                          .extension<
                                                              StackColors>()!
                                                          .buttonTextSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              style: Theme.of(context)
                                  .extension<StackColors>()!
                                  .getPrimaryEnabledButtonStyle(context),
                              child: Text(
                                "Show QR Code",
                                style: STextStyles.button(context),
                              ),
                            ),
                            if (isWalletCoin)
                              const SizedBox(
                                height: 12,
                              ),
                            if (isWalletCoin)
                              Builder(
                                builder: (context) {
                                  String buttonTitle = "Send from Stack Duo";

                                  final tuple = ref
                                      .read(
                                          exchangeSendFromWalletIdStateProvider
                                              .state)
                                      .state;
                                  if (tuple != null &&
                                      model.sendTicker.toLowerCase() ==
                                          tuple.item2.ticker.toLowerCase()) {
                                    final walletName = ref
                                        .read(walletsChangeNotifierProvider)
                                        .getManager(tuple.item1)
                                        .walletName;
                                    buttonTitle = "Send from $walletName";
                                  }

                                  return TextButton(
                                    onPressed: tuple != null &&
                                            model.sendTicker.toLowerCase() ==
                                                tuple.item2.ticker.toLowerCase()
                                        ? () async {
                                            await _confirmSend(tuple);
                                          }
                                        : () {
                                            Navigator.of(context).push(
                                              RouteGenerator.getRoute(
                                                shouldUseMaterialRoute:
                                                    RouteGenerator
                                                        .useMaterialPageRoute,
                                                builder:
                                                    (BuildContext context) {
                                                  final coin =
                                                      coinFromTickerCaseInsensitive(
                                                          model.trade!
                                                              .payInCurrency);
                                                  return SendFromView(
                                                    coin: coin,
                                                    amount: model.sendAmount
                                                        .toAmount(
                                                      fractionDigits:
                                                          coin.decimals,
                                                    ),
                                                    address: model
                                                        .trade!.payInAddress,
                                                    trade: model.trade!,
                                                  );
                                                },
                                                settings: const RouteSettings(
                                                  name: SendFromView.routeName,
                                                ),
                                              ),
                                            );
                                          },
                                    style: Theme.of(context)
                                        .extension<StackColors>()!
                                        .getSecondaryEnabledButtonStyle(
                                            context),
                                    child: Text(
                                      buttonTitle,
                                      style:
                                          STextStyles.button(context).copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .buttonTextSecondary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
