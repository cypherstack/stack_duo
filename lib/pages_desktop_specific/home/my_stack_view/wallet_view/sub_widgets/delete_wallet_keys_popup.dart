import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/global/wallets_service_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class DeleteWalletKeysPopup extends ConsumerStatefulWidget {
  const DeleteWalletKeysPopup({
    Key? key,
    required this.walletId,
    required this.words,
    this.clipboardInterface = const ClipboardWrapper(),
  }) : super(key: key);

  final String walletId;
  final List<String> words;
  final ClipboardInterface clipboardInterface;

  static const String routeName = "/desktopDeleteWalletKeysPopup";

  @override
  ConsumerState<DeleteWalletKeysPopup> createState() =>
      _DeleteWalletKeysPopup();
}

class _DeleteWalletKeysPopup extends ConsumerState<DeleteWalletKeysPopup> {
  late final String _walletId;
  late final List<String> _words;
  late final ClipboardInterface _clipboardInterface;

  @override
  void initState() {
    _walletId = widget.walletId;
    _words = widget.words;
    _clipboardInterface = widget.clipboardInterface;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 614,
      maxHeight: double.infinity,
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
                  "Wallet keys",
                  style: STextStyles.desktopH3(context),
                ),
              ),
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
          const SizedBox(
            height: 28,
          ),
          Text(
            "Recovery phrase",
            style: STextStyles.desktopTextMedium(context),
          ),
          const SizedBox(
            height: 8,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: Text(
                "Please write down your recovery phrase in the correct order and save it to keep your funds secure. You will also be asked to verify the words on the next screen.",
                style: STextStyles.desktopTextExtraExtraSmall(context),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: RawMaterialButton(
              hoverColor: Colors.transparent,
              onPressed: () async {
                await _clipboardInterface.setData(
                  ClipboardData(text: _words.join(" ")),
                );
                unawaited(
                  showFloatingFlushBar(
                    type: FlushBarType.info,
                    message: "Copied to clipboard",
                    iconAsset: Assets.svg.copy,
                    context: context,
                  ),
                );
              },
              child: MnemonicTable(
                words: widget.words,
                isDesktop: true,
                itemBorderColor: Theme.of(context)
                    .extension<StackColors>()!
                    .buttonBackSecondary,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: "Continue",
                    onPressed: () async {
                      await Navigator.of(context).push(
                        RouteGenerator.getRoute(
                          builder: (context) {
                            return ConfirmDelete(
                              walletId: _walletId,
                            );
                          },
                          settings: const RouteSettings(
                            name: "/desktopConfirmDelete",
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 32,
          ),
        ],
      ),
    );
  }
}

class ConfirmDelete extends ConsumerStatefulWidget {
  const ConfirmDelete({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<ConfirmDelete> createState() => _ConfirmDeleteState();
}

class _ConfirmDeleteState extends ConsumerState<ConfirmDelete> {
  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxHeight: 350,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              DesktopDialogCloseButton(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Thanks! "
                "\n\nYour wallet will be deleted.",
                style: STextStyles.desktopH2(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SecondaryButton(
                    width: 250,
                    buttonHeight: ButtonHeight.xl,
                    label: "Cancel",
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                  const SizedBox(width: 16),
                  PrimaryButton(
                    width: 250,
                    buttonHeight: ButtonHeight.xl,
                    label: "Continue",
                    onPressed: () async {
                      final walletsInstance =
                          ref.read(walletsChangeNotifierProvider);
                      final manager = ref
                          .read(walletsChangeNotifierProvider)
                          .getManager(widget.walletId);

                      final _managerWalletId = manager.walletId;
                      //
                      await ref
                          .read(walletsServiceChangeNotifierProvider)
                          .deleteWallet(manager.walletName, true);

                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).pop(true);
                      }

                      // wait for widget tree to dispose of any widgets watching the manager
                      await Future<void>.delayed(const Duration(seconds: 1));
                      walletsInstance.removeWallet(walletId: _managerWalletId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
