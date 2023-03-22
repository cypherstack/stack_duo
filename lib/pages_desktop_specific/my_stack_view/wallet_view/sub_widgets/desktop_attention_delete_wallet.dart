import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/delete_wallet_keys_popup.dart';
import 'package:stackduo/providers/global/wallets_provider.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/desktop/secondary_button.dart';
import 'package:stackduo/widgets/rounded_container.dart';
import 'package:tuple/tuple.dart';

class DesktopAttentionDeleteWallet extends ConsumerStatefulWidget {
  const DesktopAttentionDeleteWallet({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  static const String routeName = "/desktopAttentionDeleteWallet";

  @override
  ConsumerState<DesktopAttentionDeleteWallet> createState() =>
      _DesktopAttentionDeleteWallet();
}

class _DesktopAttentionDeleteWallet
    extends ConsumerState<DesktopAttentionDeleteWallet> {
  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 610,
      maxHeight: 530,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DesktopDialogCloseButton(
                onPressedOverride: () {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop();
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
            child: Column(
              children: [
                Text(
                  "Attention!",
                  style: STextStyles.desktopH2(context),
                ),
                const SizedBox(
                  height: 16,
                ),
                RoundedContainer(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .snackBarBackError,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "You are going to permanently delete your wallet.\n\nIf you delete your wallet, "
                      "the only way you can have access to your funds is by using your backup key."
                      "\n\nStack Duo does not keep nor is able to restore your backup key or your wallet."
                      "\n\nPLEASE SAVE YOUR BACKUP KEY.",
                      style: STextStyles.desktopTextExtraExtraSmall(context)
                          .copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .snackBarTextError,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SecondaryButton(
                      width: 250,
                      buttonHeight: ButtonHeight.xl,
                      label: "Cancel",
                      onPressed: () {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop();
                      },
                    ),
                    const SizedBox(width: 16),
                    PrimaryButton(
                      width: 250,
                      buttonHeight: ButtonHeight.xl,
                      label: "View Backup Key",
                      onPressed: () async {
                        final words = await ref
                            .read(walletsChangeNotifierProvider)
                            .getManager(widget.walletId)
                            .mnemonic;

                        if (mounted) {
                          await Navigator.of(context).pushNamed(
                            DeleteWalletKeysPopup.routeName,
                            arguments: Tuple2(
                              widget.walletId,
                              words,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
