import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/notifications/show_flush_bar.dart';
import 'package:stackduo/pages/add_wallet_views/create_or_restore_wallet_view/sub_widgets/coin_image.dart';
import 'package:stackduo/pages/add_wallet_views/new_wallet_recovery_phrase_warning_view/new_wallet_recovery_phrase_warning_view.dart';
import 'package:stackduo/pages/add_wallet_views/restore_wallet_view/restore_options_view/restore_options_view.dart';
import 'package:stackduo/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackduo/providers/global/wallets_service_provider.dart';
import 'package:stackduo/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/enums/add_wallet_type_enum.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/name_generator.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/desktop/desktop_app_bar.dart';
import 'package:stackduo/widgets/desktop/desktop_scaffold.dart';
import 'package:stackduo/widgets/icon_widgets/dice_icon.dart';
import 'package:stackduo/widgets/icon_widgets/x_icon.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';
import 'package:stackduo/widgets/stack_text_field.dart';
import 'package:stackduo/widgets/textfield_icon_button.dart';
import 'package:tuple/tuple.dart';

class NameYourWalletView extends ConsumerStatefulWidget {
  const NameYourWalletView({
    Key? key,
    required this.addWalletType,
    required this.coin,
  }) : super(key: key);

  static const routeName = "/nameYourWallet";

  final AddWalletType addWalletType;
  final Coin coin;

  @override
  ConsumerState<NameYourWalletView> createState() => _NameYourWalletViewState();
}

class _NameYourWalletViewState extends ConsumerState<NameYourWalletView> {
  late final AddWalletType addWalletType;
  late final Coin coin;

  late TextEditingController textEditingController;
  late FocusNode textFieldFocusNode;

  bool _nextEnabled = false;

  bool _showDiceIcon = true;

  Set<String> namesToExclude = {};
  late final NameGenerator generator;

  late final bool isDesktop;

  Future<String> _generateRandomWalletName() async {
    final name = generator.generate(namesToExclude: namesToExclude);
    namesToExclude.add(name);
    return name;
  }

  @override
  void initState() {
    isDesktop = Util.isDesktop;

    ref.read(walletsServiceChangeNotifierProvider).walletNames.then(
          (value) => namesToExclude.addAll(
            value.values.map((e) => e.name),
          ),
        );
    generator = NameGenerator();
    addWalletType = widget.addWalletType;
    coin = widget.coin;
    textEditingController = TextEditingController();
    textFieldFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //todo: check if print needed
    // debugPrint(
    //     "BUILD: NameYourWalletView with ${coin.name} ${addWalletType.name}");

    if (isDesktop) {
      return DesktopScaffold(
        appBar: const DesktopAppBar(
          leading: AppBarBackButton(),
          trailing: ExitToMyStackButton(),
          isCompactHeight: false,
        ),
        body: SizedBox(
          width: 480,
          child: _content(),
        ),
      );
    } else {
      return Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                if (textFieldFocusNode.hasFocus) {
                  textFieldFocusNode.unfocus();
                  Future<void>.delayed(const Duration(milliseconds: 100))
                      .then((value) => Navigator.of(context).pop());
                } else {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ),
          body: Container(
            color: Theme.of(context).extension<StackColors>()!.background,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: _content(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _content() => Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            const Spacer(
              flex: 10,
            ),
          if (!isDesktop)
            const Spacer(
              flex: 1,
            ),
          if (!isDesktop)
            CoinImage(
              coin: coin,
              height: 100,
              width: 100,
            ),
          SizedBox(
            height: isDesktop ? 0 : 16,
          ),
          Text(
            "Name your ${coin.prettyName} wallet",
            textAlign: TextAlign.center,
            style: isDesktop
                ? STextStyles.desktopH2(context)
                : STextStyles.pageTitleH1(context),
          ),
          SizedBox(
            height: isDesktop ? 16 : 8,
          ),
          Text(
            "Enter a label for your wallet (e.g. Savings)",
            textAlign: TextAlign.center,
            style: isDesktop
                ? STextStyles.desktopSubtitleH2(context)
                : STextStyles.subtitle(context),
          ),
          SizedBox(
            height: isDesktop ? 40 : 16,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              autocorrect: Util.isDesktop ? false : true,
              enableSuggestions: Util.isDesktop ? false : true,
              onChanged: (string) {
                if (string.isEmpty) {
                  if (_nextEnabled) {
                    setState(() {
                      _nextEnabled = false;
                      _showDiceIcon = true;
                    });
                  }
                } else {
                  if (!_nextEnabled) {
                    setState(() {
                      _nextEnabled = true;
                      _showDiceIcon = false;
                    });
                  }
                }
              },
              focusNode: textFieldFocusNode,
              controller: textEditingController,
              style: isDesktop
                  ? STextStyles.desktopTextMedium(context).copyWith(
                      height: 2,
                    )
                  : STextStyles.field(context),
              decoration: standardInputDecoration(
                "Enter wallet name",
                textFieldFocusNode,
                context,
              ).copyWith(
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: isDesktop ? 6 : 0),
                  child: UnconstrainedBox(
                    child: Row(
                      children: [
                        TextFieldIconButton(
                          key: const Key("genRandomWalletNameButtonKey"),
                          child: _showDiceIcon
                              ? Semantics(
                                label: "Generate Random Wallet Name Button. Generates A Random Name For Wallet.",
                                excludeSemantics: true,
                                child: DiceIcon(
                                  width: isDesktop ? 20 : 17,
                                  height: isDesktop ? 20 : 17,
                              ),
                            )
                              : Semantics(
                                label: "Generate Random Wallet Name Button. Generates A Random Name For Wallet.",
                                excludeSemantics: true,
                                child: XIcon(
                                  width: isDesktop ? 21 : 18,
                                  height: isDesktop ? 21 : 18,
                              ),
                            ),
                          onTap: () async {
                            if (_showDiceIcon) {
                              textEditingController.text =
                                  await _generateRandomWalletName();
                              setState(() {
                                _nextEnabled = true;
                                _showDiceIcon = false;
                              });
                            } else {
                              textEditingController.text = "";
                              setState(() {
                                _nextEnabled = false;
                                _showDiceIcon = true;
                              });
                            }
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: isDesktop ? 16 : 8,
          ),
          GestureDetector(
            onTap: () async {
              textEditingController.text = await _generateRandomWalletName();
              setState(() {
                _nextEnabled = true;
                _showDiceIcon = false;
              });
            },
            child: RoundedWhiteContainer(
              child: Center(
                child: Text(
                  "Roll the dice to pick a random name.",
                  style: isDesktop
                      ? STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                        )
                      : STextStyles.itemSubtitle(context),
                ),
              ),
            ),
          ),
          if (!isDesktop)
            const Spacer(
              flex: 4,
            ),
          if (isDesktop)
            const SizedBox(
              height: 32,
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: isDesktop ? 480 : 0,
              minHeight: isDesktop ? 70 : 0,
            ),
            child: TextButton(
              onPressed: _nextEnabled
                  ? () async {
                      final walletsService =
                          ref.read(walletsServiceChangeNotifierProvider);
                      final name = textEditingController.text;

                      if (await walletsService.checkForDuplicate(name)) {
                        if (mounted) {
                          unawaited(
                            showFloatingFlushBar(
                              type: FlushBarType.warning,
                              message: "Wallet name already in use.",
                              iconAsset: Assets.svg.circleAlert,
                              context: context,
                            ),
                          );
                        }
                      } else {
                        // hide keyboard if has focus
                        if (mounted && FocusScope.of(context).hasFocus) {
                          FocusScope.of(context).unfocus();
                          await Future<void>.delayed(
                              const Duration(milliseconds: 50));
                        }

                        if (mounted) {
                          switch (widget.addWalletType) {
                            case AddWalletType.New:
                              unawaited(Navigator.of(context).pushNamed(
                                NewWalletRecoveryPhraseWarningView.routeName,
                                arguments: Tuple2(
                                  name,
                                  coin,
                                ),
                              ));
                              break;
                            case AddWalletType.Restore:
                              ref
                                  .read(mnemonicWordCountStateProvider.state)
                                  .state = Constants.possibleLengthsForCoin(
                                      coin)
                                  .first;
                              unawaited(Navigator.of(context).pushNamed(
                                RestoreOptionsView.routeName,
                                arguments: Tuple2(
                                  name,
                                  coin,
                                ),
                              ));
                              break;
                          }
                        }
                      }
                    }
                  : null,
              style: _nextEnabled
                  ? Theme.of(context)
                      .extension<StackColors>()!
                      .getPrimaryEnabledButtonStyle(context)
                  : Theme.of(context)
                      .extension<StackColors>()!
                      .getPrimaryDisabledButtonStyle(context),
              child: Text(
                "Next",
                style: isDesktop
                    ? _nextEnabled
                        ? STextStyles.desktopButtonEnabled(context)
                        : STextStyles.desktopButtonDisabled(context)
                    : STextStyles.button(context),
              ),
            ),
          ),
          if (isDesktop)
            const Spacer(
              flex: 15,
            ),
        ],
      );
}
