import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/providers/global/prefs_provider.dart';
import 'package:stackduo/themes/coin_icon_provider.dart';
import 'package:stackduo/themes/stack_colors.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/block_explorers.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/desktop/secondary_button.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';

class DesktopManageBlockExplorersDialog extends ConsumerWidget {
  const DesktopManageBlockExplorersDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool showTestNet = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.showTestNetCoins),
    );

    final List<Coin> coins = showTestNet
        ? Coin.values
        : Coin.values.sublist(0, Coin.values.length - kTestNetCoinCount);

    return DesktopDialog(
      maxHeight: 850,
      maxWidth: 600,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Manage block explorers",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
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
              child: ListView.separated(
                itemCount: coins.length,
                separatorBuilder: (_, __) => const SizedBox(
                  height: 12,
                ),
                itemBuilder: (_, index) {
                  final coin = coins[index];

                  return RoundedWhiteContainer(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 14,
                    ),
                    borderColor: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle6,
                    child: Row(
                      children: [
                        SvgPicture.file(
                          File(
                            ref.watch(coinIconProvider(coin)),
                          ),
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            "${coin.prettyName} block explorer",
                            style: STextStyles.desktopTextSmall(context),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        SvgPicture.asset(
                          Assets.svg.chevronRight,
                          width: 20,
                          height: 20,
                        ),
                      ],
                    ),
                    onPressed: () {
                      showDialog<dynamic>(
                        context: context,
                        useSafeArea: false,
                        barrierDismissible: true,
                        builder: (context) {
                          return _DesktopEditBlockExplorerDialog(
                            coin: coin,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopEditBlockExplorerDialog extends ConsumerStatefulWidget {
  const _DesktopEditBlockExplorerDialog({Key? key, required this.coin})
      : super(key: key);

  final Coin coin;

  @override
  ConsumerState<_DesktopEditBlockExplorerDialog> createState() =>
      _DesktopEditBlockExplorerDialogState();
}

class _DesktopEditBlockExplorerDialogState
    extends ConsumerState<_DesktopEditBlockExplorerDialog> {
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    _textEditingController = TextEditingController(
        text:
            getBlockExplorerTransactionUrlFor(coin: widget.coin, txid: "[TXID]")
                .toString()
                .replaceAll("%5BTXID%5D", "[TXID]"));
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxHeight: double.infinity,
      maxWidth: 600,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "${widget.coin.prettyName} block explorer",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
              bottom: 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    autocorrect: false,
                    enableSuggestions: false,
                    key: const Key("addCustomNodeNodeAddressFieldKey"),
                    controller: _textEditingController,
                    focusNode: _focusNode,
                    style: STextStyles.field(context),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                RoundedWhiteContainer(
                  borderColor:
                      Theme.of(context).extension<StackColors>()!.textSubtitle6,
                  child: Text(
                    "Edit your block explorer above. Keep in mind that"
                    " every block explorer has a slightly different URL scheme."
                    "\n\n"
                    "Paste in your block explorer of choice, then edit in"
                    " [TXID] where the transaction ID should go, and Stack"
                    " Wallet will auto fill the transaction ID in that place"
                    " of the URL.",
                    style: STextStyles.desktopTextExtraExtraSmall(context),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: "Cancel",
                        buttonHeight: ButtonHeight.l,
                        onPressed: Navigator.of(context).pop,
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: PrimaryButton(
                        label: "Save",
                        buttonHeight: ButtonHeight.l,
                        onPressed: () async {
                          _textEditingController.text =
                              _textEditingController.text.trim();
                          await setBlockExplorerForCoin(
                            coin: widget.coin,
                            url: Uri.parse(
                              _textEditingController.text,
                            ),
                          );

                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
