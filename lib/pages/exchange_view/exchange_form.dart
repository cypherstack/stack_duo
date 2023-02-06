import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/pages/exchange_view/exchange_coin_selection/exchange_currency_selection_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_1_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_2_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_provider_options.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/rate_type_toggle.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/step_scaffold.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
// import 'package:stackwallet/services/exchange/simpleswap/simpleswap_exchange.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/desktop/simple_desktop_dialog.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/textfields/exchange_textfield.dart';
import 'package:tuple/tuple.dart';

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

  late final TextEditingController _sendController;
  late final TextEditingController _receiveController;
  final isDesktop = Util.isDesktop;
  final FocusNode _sendFocusNode = FocusNode();
  final FocusNode _receiveFocusNode = FocusNode();

  bool _swapLock = false;

  // todo: check and adjust this value?
  static const _valueCheckInterval = Duration(milliseconds: 500);

  Timer? _sendFieldOnChangedTimer;
  void sendFieldOnChanged(String value) async {
    if (_sendFocusNode.hasFocus) {
      _sendFieldOnChangedTimer?.cancel();

      _sendFieldOnChangedTimer = Timer(_valueCheckInterval, () async {
        final newFromAmount = Decimal.tryParse(value);

        await ref
            .read(exchangeFormStateProvider)
            .setSendAmountAndCalculateReceiveAmount(newFromAmount, true);
      });
    }
  }

  Timer? _receiveFieldOnChangedTimer;
  void receiveFieldOnChanged(String value) async {
    _receiveFieldOnChangedTimer?.cancel();

    _receiveFieldOnChangedTimer = Timer(_valueCheckInterval, () async {
      final newToAmount = Decimal.tryParse(value);

      await ref
          .read(exchangeFormStateProvider)
          .setReceivingAmountAndCalculateSendAmount(newToAmount, true);
    });
  }

  void selectSendCurrency() async {
    final type = (ref.read(prefsChangeNotifierProvider).exchangeRateType);
    final fromTicker = ref.read(exchangeFormStateProvider).fromTicker ?? "";

    if (walletInitiated &&
        fromTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
      // do not allow changing away from wallet coin
      return;
    }

    // TODO: return currency and await update while showing loading
    await _showCurrencySelectionSheet(
      willChange: ref.read(exchangeFormStateProvider).sendCurrency,
      willChangeIsSend: true,
      paired: ref.read(exchangeFormStateProvider).receiveCurrency,
      isFixedRate: type == ExchangeRateType.fixed,
      onSelected: (selectedCurrency) => ref
          .read(exchangeFormStateProvider)
          .updateSendCurrency(selectedCurrency, true),
    );

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

    // await Future<void>.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void selectReceiveCurrency() async {
    final type = (ref.read(prefsChangeNotifierProvider).exchangeRateType);
    final toTicker = ref.read(exchangeFormStateProvider).toTicker ?? "";

    if (walletInitiated &&
        toTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
      // do not allow changing away from wallet coin
      return;
    }

    // TODO: return currency and await update while showing loading
    await _showCurrencySelectionSheet(
      willChange: ref.read(exchangeFormStateProvider).receiveCurrency,
      willChangeIsSend: false,
      paired: ref.read(exchangeFormStateProvider).sendCurrency,
      isFixedRate: type == ExchangeRateType.fixed,
      onSelected: (selectedCurrency) => ref
          .read(exchangeFormStateProvider)
          .updateReceivingCurrency(selectedCurrency, true),
    );

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

    // await Future<void>.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _swap() async {
    _swapLock = true;
    _sendFocusNode.unfocus();
    _receiveFocusNode.unfocus();

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

    await ref.read(exchangeFormStateProvider).swap(shouldNotifyListeners: true);

    if (mounted) {
      Navigator.of(context, rootNavigator: isDesktop).pop();
    }
    _swapLock = false;
  }

  Future<void> _showCurrencySelectionSheet({
    required Currency? willChange,
    required Currency? paired,
    required bool isFixedRate,
    required bool willChangeIsSend,
    required void Function(Currency) onSelected,
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
                                  exchangeName: ref
                                      .read(currentExchangeNameStateProvider
                                          .state)
                                      .state,
                                  willChange: willChange,
                                  paired: paired,
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
                exchangeName:
                    ref.read(currentExchangeNameStateProvider.state).state,
                willChange: willChange,
                paired: paired,
                isFixedRate: isFixedRate,
                willChangeIsSend: willChangeIsSend,
              ),
            ),
          );

    if (mounted && result is Currency) {
      onSelected(result);
    }
  }

  void onRateTypeChanged(ExchangeRateType newType) async {
    _receiveFocusNode.unfocus();
    _sendFocusNode.unfocus();

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

    ref.read(exchangeFormStateProvider).exchangeRateType = newType;

    final fromTicker = ref.read(exchangeFormStateProvider).fromTicker ?? "-";
    final toTicker = ref.read(exchangeFormStateProvider).toTicker ?? "-";

    ref.read(exchangeFormStateProvider).reversed = false;

    if (!(toTicker == "-" || fromTicker == "-")) {
      final available = await ExchangeDataLoadingService.instance.isar.pairs
          .where()
          .exchangeNameEqualTo(
              ref.read(currentExchangeNameStateProvider.state).state)
          .filter()
          .fromEqualTo(fromTicker)
          .and()
          .toEqualTo(toTicker)
          .findAll();

      if (available.isNotEmpty) {
        final availableCurrencies = await ExchangeDataLoadingService
            .instance.isar.currencies
            .where()
            .exchangeNameEqualTo(
                ref.read(currentExchangeNameStateProvider.state).state)
            .filter()
            .tickerEqualTo(fromTicker)
            .or()
            .tickerEqualTo(toTicker)
            .findAll();

        if (availableCurrencies.length > 1) {
          final from =
              availableCurrencies.firstWhere((e) => e.ticker == fromTicker);
          final to =
              availableCurrencies.firstWhere((e) => e.ticker == toTicker);

          final newFromAmount = Decimal.tryParse(_sendController.text);
          ref.read(exchangeFormStateProvider).receiveAmount = newFromAmount;
          if (newFromAmount == null) {
            _receiveController.text = "";
          }

          await ref
              .read(exchangeFormStateProvider)
              .updateReceivingCurrency(to, false);
          await ref
              .read(exchangeFormStateProvider)
              .updateSendCurrency(from, true);

          _receiveController.text =
              ref.read(exchangeFormStateProvider).toAmountString.isEmpty
                  ? "-"
                  : ref.read(exchangeFormStateProvider).toAmountString;
          if (mounted) {
            Navigator.of(context, rootNavigator: isDesktop).pop();
          }
          return;
        }
      }
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: isDesktop).pop();
    }
    // if (!(fromTicker == "-" || toTicker == "-")) {
    //   unawaited(
    //     showFloatingFlushBar(
    //       type: FlushBarType.warning,
    //       message:
    //           "${ref.read(exchangeFormStateProvider).exchangeRateType.name} rate trade pair \"$fromTicker-$toTicker\" unavailable. Reverting to last estimated rate pair.",
    //       context: context,
    //     ),
    //   );
    // }
  }

  void onExchangePressed() async {
    final rateType = ref.read(prefsChangeNotifierProvider).exchangeRateType;
    final fromTicker = ref.read(exchangeFormStateProvider).fromTicker ?? "";
    final toTicker = ref.read(exchangeFormStateProvider).toTicker ?? "";
    final sendAmount = ref.read(exchangeFormStateProvider).sendAmount!;
    final estimate = ref.read(exchangeFormStateProvider).estimate!;

    final exchangeName = ref.read(currentExchangeNameStateProvider.state).state;

    String rate;

    switch (rateType) {
      case ExchangeRateType.estimated:
        final pair = await ExchangeDataLoadingService.instance.isar.pairs
            .where()
            .exchangeNameEqualTo(exchangeName)
            .filter()
            .group((q) => q
                .rateTypeEqualTo(SupportedRateType.estimated)
                .or()
                .rateTypeEqualTo(SupportedRateType.both))
            .and()
            .fromEqualTo(fromTicker, caseSensitive: false)
            .and()
            .toEqualTo(toTicker, caseSensitive: false)
            .findFirst();

        if (pair == null) {
          unawaited(
            showDialog<dynamic>(
              context: context,
              barrierDismissible: true,
              builder: (_) {
                if (isDesktop) {
                  return SimpleDesktopDialog(
                    title: "Selected trade pair unavailable",
                    message:
                        "The $fromTicker - $toTicker market is currently disabled for estimated/floating rate trades",
                  );
                } else {
                  return StackDialog(
                    title: "Selected trade pair unavailable",
                    message:
                        "The $fromTicker - $toTicker market is currently disabled for estimated/floating rate trades",
                  );
                }
              },
            ),
          );
          return;
        }
        rate =
            "1 ${fromTicker.toUpperCase()} ~${(estimate.estimatedAmount / sendAmount).toDecimal(scaleOnInfinitePrecision: 8).toStringAsFixed(8)} ${toTicker.toUpperCase()}";
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
            "1 ${fromTicker.toUpperCase()} ~${ref.read(exchangeFormStateProvider).rate!.toStringAsFixed(8)} ${toTicker.toUpperCase()}";
        break;
    }

    final model = IncompleteExchangeModel(
      sendTicker: fromTicker.toUpperCase(),
      receiveTicker: toTicker.toUpperCase(),
      rateInfo: rate,
      sendAmount: estimate.reversed ? estimate.estimatedAmount : sendAmount,
      receiveAmount: estimate.reversed
          ? ref.read(exchangeFormStateProvider).receiveAmount!
          : estimate.estimatedAmount,
      rateType: rateType,
      rateId: estimate.rateId,
      reversed: estimate.reversed,
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

    String? ticker;

    if (isSend) {
      ticker = ref.read(exchangeFormStateProvider).fromTicker;
    } else {
      ticker = ref.read(exchangeFormStateProvider).toTicker;
    }

    if (ticker == null) {
      return false;
    }

    return coin.ticker.toUpperCase() == ticker.toUpperCase();
  }

  @override
  void initState() {
    _sendController = TextEditingController();
    _receiveController = TextEditingController();

    walletId = widget.walletId;
    coin = widget.coin;
    walletInitiated = walletId != null && coin != null;

    if (walletInitiated) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        ref.read(exchangeFormStateProvider).reset(shouldNotifyListeners: true);
        // ref.read(fixedRateExchangeFormProvider);
      });
    } else {
      final rateType = (ref.read(prefsChangeNotifierProvider).exchangeRateType);
      final isEstimated = rateType == ExchangeRateType.estimated;
      _sendController.text =
          ref.read(exchangeFormStateProvider).fromAmountString;
      _receiveController.text = isEstimated
          ? "-" //ref.read(estimatedRateExchangeFormProvider).toAmountString
          : ref.read(exchangeFormStateProvider).toAmountString;
    }

    super.initState();
  }

  @override
  void dispose() {
    _receiveController.dispose();
    _sendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final rateType = ref.watch(
        prefsChangeNotifierProvider.select((value) => value.exchangeRateType));

    ref.listen<String>(currentExchangeNameStateProvider, (previous, next) {
      ref.read(exchangeFormStateProvider).updateExchange(
            exchange: ref.read(exchangeProvider),
            shouldUpdateData: true,
            shouldNotifyListeners: true,
          );
    });

    final isEstimated = ref.watch(prefsChangeNotifierProvider
            .select((pref) => pref.exchangeRateType)) ==
        ExchangeRateType.estimated;

    ref.listen(
        exchangeFormStateProvider.select((value) => value.toAmountString),
        (previous, String next) {
      if (!_receiveFocusNode.hasFocus) {
        _receiveController.text = isEstimated && next.isEmpty ? "-" : next;
        if (_swapLock) {
          _sendController.text =
              ref.read(exchangeFormStateProvider).fromAmountString;
        }
      }
    });
    ref.listen(
        exchangeFormStateProvider.select((value) => value.fromAmountString),
        (previous, String next) {
      if (!_sendFocusNode.hasFocus) {
        _sendController.text = next;
        if (_swapLock) {
          _receiveController.text = isEstimated
              ? ref.read(exchangeFormStateProvider).toAmountString.isEmpty
                  ? "-"
                  : ref.read(exchangeFormStateProvider).toAmountString
              : ref.read(exchangeFormStateProvider).toAmountString;
        }
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
          key: Key(
              "exchangeTextFieldKeyFor_${Theme.of(context).extension<StackColors>()!.themeType.name}"),
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
          image: ref.watch(exchangeFormStateProvider
              .select((value) => value.sendCurrency?.image)),
          ticker: ref.watch(
              exchangeFormStateProvider.select((value) => value.fromTicker)),
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        if (ref
                .watch(
                    exchangeFormStateProvider.select((value) => value.warning))
                .isNotEmpty &&
            !ref.watch(
                exchangeFormStateProvider.select((value) => value.reversed)))
          Text(
            ref.watch(
                exchangeFormStateProvider.select((value) => value.warning)),
            style: STextStyles.errorSmall(context),
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
          onTap: () {
            if (!(ref.read(prefsChangeNotifierProvider).exchangeRateType ==
                    ExchangeRateType.estimated) &&
                _receiveController.text == "-") {
              _receiveController.text = "";
            }
          },
          onChanged: receiveFieldOnChanged,
          onButtonTap: selectReceiveCurrency,
          isWalletCoin: isWalletCoin(coin, true),
          image: ref.watch(exchangeFormStateProvider
                  .select((value) => value.receiveCurrency?.image)) ??
              "",
          ticker: ref.watch(
              exchangeFormStateProvider.select((value) => value.toTicker)),
          readOnly: (rateType) == ExchangeRateType.estimated &&
              ref.watch(exchangeProvider).name ==
                  ChangeNowExchange.exchangeName,
        ),
        if (ref
                .watch(
                    exchangeFormStateProvider.select((value) => value.warning))
                .isNotEmpty &&
            ref.watch(
                exchangeFormStateProvider.select((value) => value.reversed)))
          Text(
            ref.watch(
                exchangeFormStateProvider.select((value) => value.warning)),
            style: STextStyles.errorSmall(context),
          ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        SizedBox(
          height: 60,
          child: RateTypeToggle(
            key: UniqueKey(),
            onChanged: onRateTypeChanged,
          ),
        ),
        // these reads should be watch
        if (ref.watch(exchangeFormStateProvider).sendAmount != null &&
            ref.watch(exchangeFormStateProvider).sendAmount != Decimal.zero)
          SizedBox(
            height: isDesktop ? 20 : 12,
          ),
        // these reads should be watch
        if (ref.watch(exchangeFormStateProvider).sendAmount != null &&
            ref.watch(exchangeFormStateProvider).sendAmount != Decimal.zero)
          ExchangeProviderOptions(
            from: ref.watch(exchangeFormStateProvider).fromTicker,
            to: ref.watch(exchangeFormStateProvider).toTicker,
            fromAmount: ref.watch(exchangeFormStateProvider).sendAmount,
            toAmount: ref.watch(exchangeFormStateProvider).receiveAmount,
            fixedRate: ref.watch(prefsChangeNotifierProvider
                    .select((value) => value.exchangeRateType)) ==
                ExchangeRateType.fixed,
            reversed: ref.watch(
                exchangeFormStateProvider.select((value) => value.reversed)),
          ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        PrimaryButton(
          buttonHeight: isDesktop ? ButtonHeight.l : null,
          enabled: ref.watch(
              exchangeFormStateProvider.select((value) => value.canExchange)),
          onPressed: onExchangePressed,
          label: "Exchange",
        )
      ],
    );
  }
}
