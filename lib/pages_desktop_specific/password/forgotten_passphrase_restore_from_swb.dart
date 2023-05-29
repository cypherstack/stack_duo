import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stackduo/db/hive/db.dart';
import 'package:stackduo/notifications/show_flush_bar.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/stack_backup_views/helpers/restore_create_backup.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/stack_backup_views/helpers/swb_file_system.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/stack_backup_views/sub_views/stack_restore_progress_view.dart';
import 'package:stackduo/pages_desktop_specific/password/create_password_view.dart';
import 'package:stackduo/providers/desktop/storage_crypto_handler_provider.dart';
import 'package:stackduo/providers/global/secure_store_provider.dart';
import 'package:stackduo/providers/global/wallets_provider.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/flutter_secure_storage_interface.dart';
import 'package:stackduo/utilities/logger.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/themes/stack_colors.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/desktop/desktop_app_bar.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_scaffold.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/loading_indicator.dart';
import 'package:stackduo/widgets/stack_text_field.dart';
import 'package:tuple/tuple.dart';

class ForgottenPassphraseRestoreFromSWB extends ConsumerStatefulWidget {
  const ForgottenPassphraseRestoreFromSWB({Key? key}) : super(key: key);

  static const String routeName = "/forgottenPassphraseRestoreFromSWB";

  @override
  ConsumerState<ForgottenPassphraseRestoreFromSWB> createState() =>
      _ForgottenPassphraseRestoreFromSWBState();
}

class _ForgottenPassphraseRestoreFromSWBState
    extends ConsumerState<ForgottenPassphraseRestoreFromSWB> {
  late final TextEditingController fileLocationController;
  late final TextEditingController passwordController;

  late final FocusNode passwordFocusNode;

  late final SWBFileSystem stackFileSystem;

  bool hidePassword = true;

  bool _enableButton = false;

  Future<void> restore() async {
    final String fileToRestore = fileLocationController.text;
    final String passphrase = passwordController.text;

    if (!(await File(fileToRestore).exists())) {
      await showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Backup file does not exist",
        context: context,
      );
      return;
    }

    bool shouldPop = false;
    unawaited(
      showDialog<dynamic>(
        barrierDismissible: false,
        context: context,
        builder: (_) => WillPopScope(
          onWillPop: () async {
            return shouldPop;
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: Center(
                  child: Text(
                    "Decrypting Stack backup file",
                    style: STextStyles.pageTitleH2(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 64,
              ),
              const Center(
                child: LoadingIndicator(
                  width: 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final String? jsonString = await compute(
      SWB.decryptStackWalletWithPassphrase,
      Tuple2(fileToRestore, passphrase),
      debugLabel: "stack wallet decryption compute",
    );

    if (mounted) {
      // pop LoadingIndicator
      shouldPop = true;
      Navigator.of(context).pop();

      passwordController.text = "";

      if (jsonString == null) {
        await showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Failed to decrypt backup file",
          context: context,
        );
        return;
      }

      ref.read(walletsChangeNotifierProvider);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return DesktopDialog(
            maxWidth: 580,
            maxHeight: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Restoring Stack wallet",
                        style: STextStyles.desktopH3(context),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 44,
                  ),
                  StackRestoreProgressView(
                    jsonString: jsonString,
                    shouldPushToHome: true,
                  ),
                ],
              ),
            ),
          );
        },
      );
      // await Navigator.of(context).push(
      //   RouteGenerator.getRoute(
      //     builder: (_) => StackRestoreProgressView(
      //       jsonString: jsonString,
      //     ),
      //   ),
      // );
    }
  }

  @override
  void initState() {
    stackFileSystem = SWBFileSystem();
    fileLocationController = TextEditingController();
    passwordController = TextEditingController();

    passwordFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    fileLocationController.dispose();
    passwordController.dispose();

    passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            await (ref.read(secureStoreProvider).store as DesktopSecureStore)
                .close();
            ref.refresh(secureStoreProvider);
            ref.refresh(storageCryptoHandlerProvider);
            await Hive.deleteBoxFromDisk(DB.boxNameDesktopData);
            await DB.instance.init();
            if (mounted) {
              Navigator.of(context)
                  .popUntil(ModalRoute.withName(CreatePasswordView.routeName));
              Navigator.of(context).pop();
            }
          },
        ),
        isCompactHeight: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Restore from backup",
                  style: STextStyles.desktopH1(context),
                ),
                const SizedBox(
                  height: 32,
                ),
                Text(
                  "Use your Stack wallet backup file to restore your wallets, address book, and wallet preferences.",
                  textAlign: TextAlign.center,
                  style: STextStyles.desktopTextSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle1,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                GestureDetector(
                  onTap: () async {
                    try {
                      await stackFileSystem.prepareStorage();
                      if (mounted) {
                        await stackFileSystem.openFile(context);
                      }

                      if (mounted) {
                        setState(() {
                          fileLocationController.text =
                              stackFileSystem.filePath ?? "";
                        });
                      }
                    } catch (e, s) {
                      Logging.instance.log("$e\n$s", level: LogLevel.Error);
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IgnorePointer(
                      child: TextField(
                        autocorrect: false,
                        enableSuggestions: false,
                        controller: fileLocationController,
                        style: STextStyles.field(context),
                        decoration: InputDecoration(
                          hintText: "Choose file...",
                          hintStyle: STextStyles.desktopTextFieldLabel(context),
                          suffixIcon: SizedBox(
                            height: 70,
                            child: UnconstrainedBox(
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 24,
                                  ),
                                  SvgPicture.asset(
                                    Assets.svg.folder,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark3,
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        key: const Key("restoreFromFileLocationTextFieldKey"),
                        readOnly: true,
                        toolbarOptions: const ToolbarOptions(
                          copy: true,
                          cut: false,
                          paste: false,
                          selectAll: false,
                        ),
                        onChanged: (newValue) {
                          setState(() {
                            _enableButton =
                                passwordController.text.isNotEmpty &&
                                    fileLocationController.text.isNotEmpty;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    key: const Key("restoreFromFilePasswordFieldKey"),
                    focusNode: passwordFocusNode,
                    controller: passwordController,
                    style: STextStyles.desktopTextMedium(context).copyWith(
                      height: 2,
                    ),
                    obscureText: hidePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: standardInputDecoration(
                      "Enter passphrase",
                      passwordFocusNode,
                      context,
                    ).copyWith(
                      suffixIcon: UnconstrainedBox(
                        child: SizedBox(
                          height: 70,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 24,
                              ),
                              GestureDetector(
                                key: const Key(
                                    "restoreFromFilePasswordFieldShowPasswordButtonKey"),
                                onTap: () async {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: SvgPicture.asset(
                                    hidePassword
                                        ? Assets.svg.eye
                                        : Assets.svg.eyeSlash,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark3,
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    onChanged: (newValue) {
                      setState(() {
                        _enableButton = passwordController.text.isNotEmpty &&
                            fileLocationController.text.isNotEmpty;
                      });
                    },
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                PrimaryButton(
                  label: "Restore",
                  enabled: _enableButton,
                  onPressed: () {
                    restore();
                  },
                ),
                const SizedBox(
                  height: kDesktopAppBarHeight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
