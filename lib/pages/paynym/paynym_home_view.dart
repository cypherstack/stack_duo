import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/paynym/add_new_paynym_follow_view.dart';
import 'package:stackwallet/pages/paynym/dialogs/paynym_qr_popup.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_followers_list.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_following_list.dart';
import 'package:stackwallet/providers/wallet/my_paynym_account_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/copy_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/share_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/toggle.dart';

class PaynymHomeView extends ConsumerStatefulWidget {
  const PaynymHomeView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  static const String routeName = "/paynymHome";

  @override
  ConsumerState<PaynymHomeView> createState() => _PaynymHomeViewState();
}

class _PaynymHomeViewState extends ConsumerState<PaynymHomeView> {
  bool showFollowers = false;
  int secretCount = 0;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? DesktopAppBar(
              isCompactHeight: true,
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              leading: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 20,
                    ),
                    child: AppBarIconButton(
                      size: 32,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                      shadows: const [],
                      icon: SvgPicture.asset(
                        Assets.svg.arrowLeft,
                        width: 18,
                        height: 18,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .topNavIconPrimary,
                      ),
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  SvgPicture.asset(
                    Assets.svg.user,
                    width: 32,
                    height: 32,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "PayNym",
                    style: STextStyles.desktopH3(context),
                  )
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 22),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => AddNewPaynymFollowView(
                          walletId: widget.walletId,
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              Assets.svg.plus,
                              width: 16,
                              height: 16,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Add new",
                                  style:
                                      STextStyles.desktopButtonSecondaryEnabled(
                                              context)
                                          .copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              titleSpacing: 0,
              title: Text(
                "PayNym",
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppBarIconButton(
                      icon: SvgPicture.asset(
                        Assets.svg.circlePlusFilled,
                        width: 20,
                        height: 20,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AddNewPaynymFollowView.routeName,
                          arguments: widget.walletId,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppBarIconButton(
                      icon: SvgPicture.asset(
                        Assets.svg.circleQuestion,
                        width: 20,
                        height: 20,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark,
                      ),
                      onPressed: () {
                        // todo info ?
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  width: 4,
                ),
              ],
            ),
      body: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (!isDesktop)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      secretCount++;
                      if (secretCount > 5) {
                        debugPrint(
                            "My Account: ${ref.read(myPaynymAccountStateProvider.state).state}");
                        debugPrint(
                            "My Account: ${ref.read(myPaynymAccountStateProvider.state).state!.following}");
                        secretCount = 0;
                      }

                      timer ??= Timer(
                        const Duration(milliseconds: 1500),
                        () {
                          secretCount = 0;
                          timer = null;
                        },
                      );
                    },
                    child: PayNymBot(
                      paymentCodeString: ref
                          .watch(myPaynymAccountStateProvider.state)
                          .state!
                          .codes
                          .first
                          .code,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    ref
                        .watch(myPaynymAccountStateProvider.state)
                        .state!
                        .nymName,
                    style: STextStyles.desktopMenuItemSelected(context),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    Format.shorten(
                        ref
                            .watch(myPaynymAccountStateProvider.state)
                            .state!
                            .codes
                            .first
                            .code,
                        12,
                        5),
                    style: STextStyles.label(context),
                  ),
                  const SizedBox(
                    height: 11,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: "Copy",
                          buttonHeight: ButtonHeight.l,
                          iconSpacing: 4,
                          icon: CopyIcon(
                            width: 10,
                            height: 10,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: ref
                                    .read(myPaynymAccountStateProvider.state)
                                    .state!
                                    .codes
                                    .first
                                    .code,
                              ),
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
                        ),
                      ),
                      const SizedBox(
                        width: 13,
                      ),
                      Expanded(
                        child: SecondaryButton(
                          label: "Share",
                          buttonHeight: ButtonHeight.l,
                          iconSpacing: 4,
                          icon: ShareIcon(
                            width: 10,
                            height: 10,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                          onPressed: () {
                            // copy to clipboard
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 13,
                      ),
                      Expanded(
                        child: SecondaryButton(
                          label: "Address",
                          buttonHeight: ButtonHeight.l,
                          iconSpacing: 4,
                          icon: QrCodeIcon(
                            width: 10,
                            height: 10,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) => PaynymQrPopup(
                                paynymAccount: ref
                                    .read(myPaynymAccountStateProvider.state)
                                    .state!,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.all(24),
                child: RoundedWhiteContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 4,
                      ),
                      GestureDetector(
                        onTap: () {
                          secretCount++;
                          if (secretCount > 5) {
                            debugPrint(
                                "My Account: ${ref.read(myPaynymAccountStateProvider.state).state}");
                            debugPrint(
                                "My Account: ${ref.read(myPaynymAccountStateProvider.state).state!.following}");
                            secretCount = 0;
                          }

                          timer ??= Timer(
                            const Duration(milliseconds: 1500),
                            () {
                              secretCount = 0;
                              timer = null;
                            },
                          );
                        },
                        child: PayNymBot(
                          paymentCodeString: ref
                              .watch(myPaynymAccountStateProvider.state)
                              .state!
                              .codes
                              .first
                              .code,
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref
                                .watch(myPaynymAccountStateProvider.state)
                                .state!
                                .nymName,
                            style: STextStyles.desktopH3(context),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            Format.shorten(
                                ref
                                    .watch(myPaynymAccountStateProvider.state)
                                    .state!
                                    .codes
                                    .first
                                    .code,
                                12,
                                5),
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SecondaryButton(
                        label: "Copy",
                        buttonHeight: ButtonHeight.l,
                        width: 160,
                        icon: CopyIcon(
                          width: 18,
                          height: 18,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: ref
                                  .read(myPaynymAccountStateProvider.state)
                                  .state!
                                  .codes
                                  .first
                                  .code,
                            ),
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
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      SecondaryButton(
                        label: "Address",
                        width: 160,
                        buttonHeight: ButtonHeight.l,
                        icon: QrCodeIcon(
                          width: 18,
                          height: 18,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark,
                        ),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => PaynymQrPopup(
                              paynymAccount: ref
                                  .read(myPaynymAccountStateProvider.state)
                                  .state!,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (!isDesktop)
              const SizedBox(
                height: 24,
              ),
            ConditionalParent(
              condition: isDesktop,
              builder: (child) => Padding(
                padding: const EdgeInsets.only(left: 24),
                child: child,
              ),
              child: SizedBox(
                height: isDesktop ? 56 : 40,
                width: isDesktop ? 490 : null,
                child: Toggle(
                  onColor: Theme.of(context).extension<StackColors>()!.popupBG,
                  onText:
                      "Following (${ref.watch(myPaynymAccountStateProvider.state).state?.following.length ?? 0})",
                  offColor: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  offText:
                      "Followers (${ref.watch(myPaynymAccountStateProvider.state).state?.followers.length ?? 0})",
                  isOn: showFollowers,
                  onValueChanged: (value) {
                    setState(() {
                      showFollowers = value;
                    });
                  },
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: isDesktop ? 20 : 16,
            ),
            Expanded(
              child: ConditionalParent(
                condition: isDesktop,
                builder: (child) => Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: SizedBox(
                    width: 490,
                    child: child,
                  ),
                ),
                child: ConditionalParent(
                  condition: !isDesktop,
                  builder: (child) => Container(
                    child: child,
                  ),
                  child: !showFollowers
                      ? PaynymFollowingList(
                          walletId: widget.walletId,
                        )
                      : PaynymFollowersList(
                          walletId: widget.walletId,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
