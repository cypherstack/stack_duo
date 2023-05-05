import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackduo/models/exchange/aggregate_currency.dart';
import 'package:stackduo/models/exchange/incomplete_exchange.dart';
import 'package:stackduo/models/exchange/response_objects/estimate.dart';
import 'package:stackduo/models/exchange/response_objects/range.dart';
import 'package:stackduo/models/isar/exchange_cache/currency.dart';
import 'package:stackduo/models/isar/exchange_cache/pair.dart';
import 'package:stackduo/pages/exchange_view/exchange_coin_selection/exchange_currency_selection_view.dart';
import 'package:stackduo/pages/exchange_view/exchange_step_views/step_1_view.dart';
import 'package:stackduo/pages/exchange_view/exchange_step_views/step_2_view.dart';
import 'package:stackduo/pages/exchange_view/sub_widgets/exchange_provider_options.dart';
import 'package:stackduo/pages/exchange_view/sub_widgets/rate_type_toggle.dart';
import 'package:stackduo/pages_desktop_specific/desktop_exchange/exchange_steps/step_scaffold.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackduo/services/exchange/exchange_data_loading_service.dart';
import 'package:stackduo/services/exchange/exchange_response.dart';
import 'package:stackduo/services/exchange/majestic_bank/majestic_bank_exchange.dart';
import 'package:stackduo/services/exchange/trocador/trocador_exchange.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/enums/exchange_rate_type_enum.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/conditional_parent.dart';
import 'package:stackduo/widgets/custom_loading_overlay.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/desktop/secondary_button.dart';
import 'package:stackduo/widgets/rounded_container.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';
import 'package:stackduo/widgets/stack_dialog.dart';
import 'package:stackduo/widgets/textfields/exchange_textfield.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

class ExchangeForm extends ConsumerStatefulWidget {
  const ExchangeForm({
    Key? key,
    this.walletId,
    this.coin,
  }) : super(key: key);

  final String? walletId;
  final Coin? coin;

  @override
  ConsumerState<ExchangeForm> createState() => _ExchangeFormState();
}

class _ExchangeFormState extends ConsumerState<ExchangeForm> {
  late final String? walletId;
  late final Coin? coin;
  late final bool walletInitiated;

  final exchanges = [
    MajesticBankExchange.instance,
    ChangeNowExchange.instance,
    TrocadorExchange.instance,
  ];

  late final TextEditingController _sendController;
  late final TextEditingController _receiveController;
  final isDesktop = Util.isDesktop;
  final FocusNode _sendFocusNode = FocusNode();
  final FocusNode _receiveFocusNode = FocusNode();

  bool _swapLock = false;

  // todo: check and adjust this value?
  static const _valueCheckInterval = Duration(milliseconds: 1500);

  Future<T> showUpdatingExchangeRate<T>({
    required Future<T> whileFuture,
  }) async {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: Container(
            color: Theme.of(context)
                .extension<StackColors>()!
                .overlay
                .withOpacity(0.6),
            child: const CustomLoadingOverlay(
              message: "Updating exchange rate",
              eventBus: null,
            ),
          ),
        ),
      ),
    );

    final result = await whileFuture;

    if (mounted) {
      Navigator.of(context, rootNavigator: isDesktop).pop();
    }

    return result;
  }

  Timer? _sendFieldOnChangedTimer;
  void sendFieldOnChanged(String value) {
    if (_sendFocusNode.hasFocus) {
      _sendFieldOnChangedTimer?.cancel();

      _sendFieldOnChangedTimer = Timer(_valueCheckInterval, () async {
        final newFromAmount = _localizedStringToNum(value);

        ref.read(efSendAmountProvider.notifier).state = newFromAmount;
        if (!_swapLock && !ref.read(efReversedProvider)) {
          unawaited(update());
        }
      });
    }
  }

  Timer? _receiveFieldOnChangedTimer;
  void receiveFieldOnChanged(String value) async {
    _receiveFieldOnChangedTimer?.cancel();

    _receiveFieldOnChangedTimer = Timer(_valueCheckInterval, () async {
      final newToAmount = _localizedStringToNum(value);

      ref.read(efReceiveAmountProvider.notifier).state = newToAmount;
      if (!_swapLock && ref.read(efReversedProvider)) {
        unawaited(update());
      }
    });
  }

  Decimal? _localizedStringToNum(String? value) {
    if (value == null) {
      return null;
    }
    try {
      // wtf Dart?????
      // This turns "99999999999999999999" into 100000000000000000000.0
      // final numFromLocalised = NumberFormat.decimalPattern(
      //         ref.read(localeServiceChangeNotifierProvider).locale)
      //     .parse(value);
      // return Decimal.tryParse(numFromLocalised.toString());

      try {
        return Decimal.parse(value);
      } catch (_) {
        try {
          return Decimal.parse(value.replaceAll(",", "."));
        } catch (_) {
          rethrow;
        }
      }
    } catch (_) {
      return null;
    }
  }

  Future<AggregateCurrency> _getAggregateCurrency(Currency currency) async {
    final rateType = ref.read(efRateTypeProvider);
    final currencies = await ExchangeDataLoadingService.instance.isar.currencies
        .filter()
        .group((q) => rateType == ExchangeRateType.fixed
            ? q
                .rateTypeEqualTo(SupportedRateType.both)
                .or()
                .rateTypeEqualTo(SupportedRateType.fixed)
            : q
                .rateTypeEqualTo(SupportedRateType.both)
                .or()
                .rateTypeEqualTo(SupportedRateType.estimated))
        .and()
        .tickerEqualTo(
          currency.ticker,
          caseSensitive: false,
        )
        .findAll();

    final items = [Tuple2(currency.exchangeName, currency)];

    for (final currency in currencies) {
      items.add(Tuple2(currency.exchangeName, currency));
    }

    return AggregateCurrency(exchangeCurrencyPairs: items);
  }

  void selectSendCurrency() async {
    final type = ref.read(efRateTypeProvider);
    final fromTicker = ref.read(efCurrencyPairProvider).send?.ticker ?? "";

    if (walletInitiated &&
        fromTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
      // do not allow changing away from wallet coin
      return;
    }

    final selectedCurrency = await _showCurrencySelectionSheet(
      willChange: ref.read(efCurrencyPairProvider).send?.ticker,
      willChangeIsSend: true,
      paired: ref.read(efCurrencyPairProvider).receive?.ticker,
      isFixedRate: type == ExchangeRateType.fixed,
    );

    if (selectedCurrency != null) {
      await showUpdatingExchangeRate(
        whileFuture: _getAggregateCurrency(selectedCurrency).then(
          (aggregateSelected) => ref.read(efCurrencyPairProvider).setSend(
                aggregateSelected,
                notifyListeners: true,
              ),
        ),
      );
    }
  }

  void selectReceiveCurrency() async {
    final toTicker = ref.read(efCurrencyPairProvider).receive?.ticker ?? "";
    if (walletInitiated &&
        toTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
      // do not allow changing away from wallet coin
      return;
    }

    final selectedCurrency = await _showCurrencySelectionSheet(
      willChange: ref.read(efCurrencyPairProvider).receive?.ticker,
      willChangeIsSend: false,
      paired: ref.read(efCurrencyPairProvider).send?.ticker,
      isFixedRate: ref.read(efRateTypeProvider) == ExchangeRateType.fixed,
    );

    if (selectedCurrency != null) {
      await showUpdatingExchangeRate(
        whileFuture: _getAggregateCurrency(selectedCurrency).then(
          (aggregateSelected) => ref.read(efCurrencyPairProvider).setReceive(
                aggregateSelected,
                notifyListeners: true,
              ),
        ),
      );
    }
  }

  Future<void> _swap() async {
    _swapLock = true;
    _sendFocusNode.unfocus();
    _receiveFocusNode.unfocus();

    final temp = ref.read(efCurrencyPairProvider).send;
    ref.read(efCurrencyPairProvider).setSend(
          ref.read(efCurrencyPairProvider).receive,
          notifyListeners: true,
        );
    ref.read(efCurrencyPairProvider).setReceive(
          temp,
          notifyListeners: true,
        );

    // final reversed = ref.read(efReversedProvider);

    final amount = ref.read(efSendAmountProvider);
    ref.read(efSendAmountProvider.notifier).state =
        ref.read(efReceiveAmountProvider);

    ref.read(efReceiveAmountProvider.notifier).state = amount;

    unawaited(update());

    _swapLock = false;
  }

  Future<Currency?> _showCurrencySelectionSheet({
    required String? willChange,
    required String? paired,
    required bool isFixedRate,
    required bool willChangeIsSend,
  }) async {
    _sendFocusNode.unfocus();
    _receiveFocusNode.unfocus();

    final result = isDesktop
        ? await showDialog<Currency?>(
            context: context,
            builder: (context) {
              return DesktopDialog(
                maxHeight: 700,
                maxWidth: 580,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                          ),
                          child: Text(
                            "Choose a coin to exchange",
                            style: STextStyles.desktopH3(context),
                          ),
                        ),
                        const DesktopDialogCloseButton(),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 32,
                          bottom: 32,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RoundedWhiteContainer(
                                padding: const EdgeInsets.all(16),
                                borderColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .background,
                                child: ExchangeCurrencySelectionView(
                                  willChangeTicker: willChange,
                                  pairedTicker: paired,
                                  isFixedRate: isFixedRate,
                                  willChangeIsSend: willChangeIsSend,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
        : await Navigator.of(context).push(
            MaterialPageRoute<dynamic>(
              builder: (_) => ExchangeCurrencySelectionView(
                willChangeTicker: willChange,
                pairedTicker: paired,
                isFixedRate: isFixedRate,
                willChangeIsSend: willChangeIsSend,
              ),
            ),
          );

    if (mounted && result is Currency) {
      return result;
    } else {
      return null;
    }
  }

  void onRateTypeChanged(ExchangeRateType newType) {
    _receiveFocusNode.unfocus();
    _sendFocusNode.unfocus();

    ref.read(efRateTypeProvider.notifier).state = newType;
    update();
  }

  void onExchangePressed() async {
    final rateType = ref.read(efRateTypeProvider);
    final fromTicker = ref.read(efCurrencyPairProvider).send?.ticker ?? "";
    final toTicker = ref.read(efCurrencyPairProvider).receive?.ticker ?? "";
    final estimate = ref.read(efEstimateProvider)!;
    final sendAmount = ref.read(efSendAmountProvider)!;

    if (rateType == ExchangeRateType.fixed && toTicker.toUpperCase() == "WOW") {
      await showDialog<void>(
        context: context,
        builder: (context) => const StackOkDialog(
          title: "WOW error",
          message:
              "Wownero is temporarily disabled as a receiving currency for fixed rate trades due to network issues",
        ),
      );

      return;
    }

    String rate;

    final amountToSend =
        estimate.reversed ? estimate.estimatedAmount : sendAmount;
    final amountToReceive = estimate.reversed
        ? ref.read(efReceiveAmountProvider)!
        : estimate.estimatedAmount;

    switch (rateType) {
      case ExchangeRateType.estimated:
        rate =
            "1 ${fromTicker.toUpperCase()} ~${(amountToReceive / sendAmount).toDecimal(scaleOnInfinitePrecision: 8).toStringAsFixed(8)} ${toTicker.toUpperCase()}";
        break;
      case ExchangeRateType.fixed:
        bool? shouldCancel;

        if (estimate.warningMessage != null &&
            estimate.warningMessage!.isNotEmpty) {
          shouldCancel = await showDialog<bool?>(
            context: context,
            barrierDismissible: true,
            builder: (_) {
              if (isDesktop) {
                return DesktopDialog(
                  maxWidth: 500,
                  maxHeight: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Failed to update trade estimate",
                            style: STextStyles.desktopH3(context),
                          ),
                          const DesktopDialogCloseButton(),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        estimate.warningMessage!,
                        style: STextStyles.desktopTextSmall(context),
                      ),
                      const Spacer(),
                      Text(
                        "Do you want to attempt trade anyways?",
                        style: STextStyles.desktopTextSmall(context),
                      ),
                      const Spacer(
                        flex: 2,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: "Cancel",
                              buttonHeight: ButtonHeight.l,
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(true),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: PrimaryButton(
                              label: "Attempt",
                              buttonHeight: ButtonHeight.l,
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(false),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              } else {
                return StackDialog(
                  title: "Failed to update trade estimate",
                  message:
                      "${estimate.warningMessage!}\n\nDo you want to attempt trade anyways?",
                  leftButton: TextButton(
                    style: Theme.of(context)
                        .extension<StackColors>()!
                        .getSecondaryEnabledButtonStyle(context),
                    child: Text(
                      "Cancel",
                      style: STextStyles.itemSubtitle12(context),
                    ),
                    onPressed: () {
                      // notify return to cancel
                      Navigator.of(context).pop(true);
                    },
                  ),
                  rightButton: TextButton(
                    style: Theme.of(context)
                        .extension<StackColors>()!
                        .getPrimaryEnabledButtonStyle(context),
                    child: Text(
                      "Attempt",
                      style: STextStyles.button(context),
                    ),
                    onPressed: () {
                      // continue and try to attempt trade
                      Navigator.of(context).pop(false);
                    },
                  ),
                );
              }
            },
          );
        }

        if (shouldCancel is bool && shouldCancel) {
          return;
        }
        rate =
            "1 ${fromTicker.toUpperCase()} ~${(amountToReceive / amountToSend).toDecimal(
                  scaleOnInfinitePrecision: 12,
                ).toStringAsFixed(8)} ${toTicker.toUpperCase()}";
        break;
    }

    final model = IncompleteExchangeModel(
      sendTicker: fromTicker.toUpperCase(),
      receiveTicker: toTicker.toUpperCase(),
      rateInfo: rate,
      sendAmount: amountToSend,
      receiveAmount: amountToReceive,
      rateType: rateType,
      estimate: estimate,
      reversed: estimate.reversed,
      walletInitiated: walletInitiated,
    );

    if (mounted) {
      if (walletInitiated) {
        ref.read(exchangeSendFromWalletIdStateProvider.state).state =
            Tuple2(walletId!, coin!);
        if (isDesktop) {
          ref.read(ssss.state).state = model;
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return const DesktopDialog(
                maxWidth: 720,
                maxHeight: double.infinity,
                child: StepScaffold(
                  initialStep: 2,
                ),
              );
            },
          );
        } else {
          unawaited(
            Navigator.of(context).pushNamed(
              Step2View.routeName,
              arguments: model,
            ),
          );
        }
      } else {
        ref.read(exchangeSendFromWalletIdStateProvider.state).state = null;

        if (isDesktop) {
          ref.read(ssss.state).state = model;
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return const DesktopDialog(
                maxWidth: 720,
                maxHeight: double.infinity,
                child: StepScaffold(
                  initialStep: 1,
                ),
              );
            },
          );
        } else {
          unawaited(
            Navigator.of(context).pushNamed(
              Step1View.routeName,
              arguments: model,
            ),
          );
        }
      }
    }
  }

  bool isWalletCoin(Coin? coin, bool isSend) {
    if (coin == null) {
      return false;
    }

    String? ticker = isSend
        ? ref.read(efCurrencyPairProvider).send?.ticker
        : ref.read(efCurrencyPairProvider).receive?.ticker;

    if (ticker == null) {
      return false;
    }

    return coin.ticker.toUpperCase() == ticker.toUpperCase();
  }

  Future<void> update() async {
    final uuid = const Uuid().v1();
    _latestUuid = uuid;
    _addUpdate(uuid);
    for (final exchange in exchanges) {
      ref.read(efEstimatesListProvider(exchange.name).notifier).state = null;
    }

    final reversed = ref.read(efReversedProvider);
    final amount = reversed
        ? ref.read(efReceiveAmountProvider)
        : ref.read(efSendAmountProvider);

    final pair = ref.read(efCurrencyPairProvider);
    if (amount == null ||
        amount <= Decimal.zero ||
        pair.send == null ||
        pair.receive == null) {
      _removeUpdate(uuid);
      return;
    }
    final rateType = ref.read(efRateTypeProvider);
    final Map<String, Tuple2<ExchangeResponse<List<Estimate>>, Range?>>
        results = {};

    for (final exchange in exchanges) {
      final sendCurrency = pair.send?.forExchange(exchange.name);
      final receiveCurrency = pair.receive?.forExchange(exchange.name);

      if (sendCurrency != null && receiveCurrency != null) {
        final rangeResponse = await exchange.getRange(
          reversed ? receiveCurrency.ticker : sendCurrency.ticker,
          reversed ? sendCurrency.ticker : receiveCurrency.ticker,
          rateType == ExchangeRateType.fixed,
        );

        final estimateResponse = await exchange.getEstimates(
          sendCurrency.ticker,
          receiveCurrency.ticker,
          amount,
          rateType == ExchangeRateType.fixed,
          reversed,
        );

        results.addAll(
          {
            exchange.name: Tuple2(
              estimateResponse,
              rangeResponse.value,
            ),
          },
        );
      }
    }

    for (final exchange in exchanges) {
      if (uuid == _latestUuid) {
        ref.read(efEstimatesListProvider(exchange.name).notifier).state =
            results[exchange.name];
      }
    }

    _removeUpdate(uuid);
  }

  String? _latestUuid;
  final Set<String> _uuids = {};

  void _addUpdate(String uuid) {
    _uuids.add(uuid);
    ref.read(efRefreshingProvider.notifier).state = true;
  }

  void _removeUpdate(String uuid) {
    _uuids.remove(uuid);
    if (_uuids.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(efRefreshingProvider.notifier).state = false;
      });
    }
  }

  void updateSend(Estimate? estimate) {
    ref.read(efSendAmountProvider.notifier).state = estimate?.estimatedAmount;
  }

  void updateReceive(Estimate? estimate) {
    ref.read(efReceiveAmountProvider.notifier).state =
        estimate?.estimatedAmount;
  }

  @override
  void initState() {
    _sendController = TextEditingController();
    _receiveController = TextEditingController();

    walletId = widget.walletId;
    coin = widget.coin;
    walletInitiated = walletId != null && coin != null;

    _sendFocusNode.addListener(() {
      if (_sendFocusNode.hasFocus) {
        final reversed = ref.read(efReversedProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(efReversedProvider.notifier).state = false;
          if (reversed == true) {
            update();
          }
        });
      }
    });
    _receiveFocusNode.addListener(() {
      if (_receiveFocusNode.hasFocus &&
          ref.read(efExchangeProvider).name != ChangeNowExchange.exchangeName) {
        final reversed = ref.read(efReversedProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(efReversedProvider.notifier).state = true;
          if (reversed != true) {
            update();
          }
        });
      }
    });

    if (walletInitiated) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        ref.read(efSendAmountProvider.notifier).state = null;
        ref.read(efReceiveAmountProvider.notifier).state = null;
        ref.read(efReversedProvider.notifier).state = false;
        ref.read(efRefreshingProvider.notifier).state = false;
        ref.read(efCurrencyPairProvider).setSend(null, notifyListeners: true);
        ref
            .read(efCurrencyPairProvider)
            .setReceive(null, notifyListeners: true);
        ExchangeDataLoadingService.instance
            .getAggregateCurrency(
          coin!.ticker,
          ExchangeRateType.estimated,
          null,
        )
            .then((value) {
          if (value != null) {
            ref.read(efCurrencyPairProvider).setSend(
                  value,
                  notifyListeners: true,
                );
          }
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _sendController.text = ref.read(efSendAmountStringProvider);
        _receiveController.text = ref.read(efReceiveAmountStringProvider);
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    _receiveController.dispose();
    _sendController.dispose();
    _receiveFocusNode.dispose();
    _sendFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final rateType = ref.watch(efRateTypeProvider);

    final isEstimated = rateType == ExchangeRateType.estimated;

    ref.listen(efReceiveAmountStringProvider, (previous, String next) {
      if (!_receiveFocusNode.hasFocus) {
        _receiveController.text = isEstimated && next.isEmpty ? "-" : next;
        // if (_swapLock) {
        _sendController.text = ref.read(efSendAmountStringProvider);
        // }
      }
    });
    ref.listen(efSendAmountStringProvider, (previous, String next) {
      if (!_sendFocusNode.hasFocus) {
        _sendController.text = next;
        // if (_swapLock) {
        _receiveController.text =
            isEstimated && ref.read(efReceiveAmountStringProvider).isEmpty
                ? "-"
                : ref.read(efReceiveAmountStringProvider);
        // }
      }
    });

    ref.listen(efEstimateProvider.notifier, (previous, next) {
      final estimate = (next as StateController<Estimate?>).state;
      if (ref.read(efReversedProvider)) {
        updateSend(estimate);
      } else {
        updateReceive(estimate);
      }
    });

    ref.listen(efCurrencyPairProvider, (previous, next) {
      if (!_swapLock) {
        update();
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "You will send",
          style: STextStyles.itemSubtitle(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark3,
          ),
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        ExchangeTextField(
          key: Key("exchangeTextFieldKeyFor_"
              "${Theme.of(context).extension<StackColors>()!.themeType.name}"
              "${ref.watch(efCurrencyPairProvider.select((value) => value.send?.ticker))}"),
          controller: _sendController,
          focusNode: _sendFocusNode,
          textStyle: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          buttonColor:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          borderRadius: Constants.size.circularBorderRadius,
          background:
              Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
          onTap: () {
            if (_sendController.text == "-") {
              _sendController.text = "";
            }
          },
          onChanged: sendFieldOnChanged,
          onButtonTap: selectSendCurrency,
          isWalletCoin: isWalletCoin(coin, true),
          currency:
              ref.watch(efCurrencyPairProvider.select((value) => value.send)),
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "You will receive",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
            ConditionalParent(
              condition: isDesktop,
              builder: (child) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: child,
              ),
              child: Semantics(
                label: "Swap Button. Reverse The Exchange Currencies.",
                excludeSemantics: true,
                child: RoundedContainer(
                  padding: isDesktop
                      ? const EdgeInsets.all(6)
                      : const EdgeInsets.all(2),
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonBackSecondary,
                  radiusMultiplier: 0.75,
                  child: GestureDetector(
                    onTap: () async {
                      await _swap();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(
                        Assets.svg.swap,
                        width: 20,
                        height: 20,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: isDesktop ? 10 : 7,
        ),
        ExchangeTextField(
          key: Key(
              "exchangeTextFieldKeyFor1_${Theme.of(context).extension<StackColors>()!.themeType.name}"),
          focusNode: _receiveFocusNode,
          controller: _receiveController,
          textStyle: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          buttonColor:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          borderRadius: Constants.size.circularBorderRadius,
          background:
              Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
          onTap: rateType == ExchangeRateType.estimated &&
                  ref.watch(efExchangeProvider).name ==
                      ChangeNowExchange.exchangeName
              ? null
              : () {
                  if (_sendController.text == "-") {
                    _sendController.text = "";
                  }
                },
          onChanged: receiveFieldOnChanged,
          onButtonTap: selectReceiveCurrency,
          isWalletCoin: isWalletCoin(coin, true),
          currency: ref
              .watch(efCurrencyPairProvider.select((value) => value.receive)),
          readOnly: rateType == ExchangeRateType.estimated &&
              ref.watch(efExchangeProvider).name ==
                  ChangeNowExchange.exchangeName,
        ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        SizedBox(
          height: isDesktop ? 60 : 40,
          child: RateTypeToggle(
            key: UniqueKey(),
            onChanged: onRateTypeChanged,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: ref.watch(efSendAmountProvider) == null &&
                  ref.watch(efReceiveAmountProvider) == null
              ? const SizedBox(
                  height: 0,
                )
              : Padding(
                  padding: EdgeInsets.only(top: isDesktop ? 20 : 12),
                  child: ExchangeProviderOptions(
                    fixedRate: rateType == ExchangeRateType.fixed,
                    reversed: ref.watch(efReversedProvider),
                  ),
                ),
        ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        PrimaryButton(
          buttonHeight: isDesktop ? ButtonHeight.l : null,
          enabled: ref.watch(efCanExchangeProvider),
          onPressed: onExchangePressed,
          label: "Swap",
        )
      ],
    );
  }
}
