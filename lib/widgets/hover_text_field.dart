import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/global/wallets_service_provider.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';

class DesktopWalletNameField extends ConsumerStatefulWidget {
  const DesktopWalletNameField({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<DesktopWalletNameField> createState() => _HoverTextFieldState();
}

class _HoverTextFieldState extends ConsumerState<DesktopWalletNameField> {
  late final TextEditingController controller;
  late final FocusNode focusNode;
  bool readOnly = true;

  final InputBorder inputBorder = OutlineInputBorder(
    borderSide: const BorderSide(
      width: 0,
      color: Colors.transparent,
    ),
    borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
  );

  Future<void> onDone() async {
    final currentWalletName = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .walletName;
    final newName = controller.text;
    if (newName != currentWalletName) {
      final success =
          await ref.read(walletsServiceChangeNotifierProvider).renameWallet(
                from: currentWalletName,
                to: newName,
                shouldNotifyListeners: true,
              );
      if (success) {
        ref
            .read(walletsChangeNotifierProvider)
            .getManager(widget.walletId)
            .walletName = newName;
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.success,
            message: "Wallet renamed",
            context: context,
          ),
        );
      } else {
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message: "Wallet named \"$newName\" already exists",
            context: context,
          ),
        );
        controller.text = currentWalletName;
      }
    }
  }

  void listenerFunc() {
    if (!focusNode.hasPrimaryFocus && !readOnly) {
      setState(() {
        readOnly = true;
      });
      onDone.call();
    }
  }

  @override
  void initState() {
    controller = TextEditingController();
    focusNode = FocusNode();

    focusNode.addListener(listenerFunc);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.text = ref
          .read(walletsChangeNotifierProvider)
          .getManager(widget.walletId)
          .walletName;
    });

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.removeListener(listenerFunc);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      autocorrect: !Util.isDesktop,
      enableSuggestions: !Util.isDesktop,
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onTap: () {
        setState(() {
          readOnly = false;
        });
      },
      onEditingComplete: () {
        setState(() {
          readOnly = true;
        });
        onDone.call();
      },
      style: STextStyles.desktopH3(context),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 12,
        ),
        border: inputBorder,
        focusedBorder: inputBorder,
        disabledBorder: inputBorder,
        enabledBorder: inputBorder,
        errorBorder: inputBorder,
        fillColor: readOnly
            ? Colors.transparent
            : Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
      ),
    );
  }
}