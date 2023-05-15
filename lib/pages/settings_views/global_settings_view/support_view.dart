import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/themes/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/conditional_parent.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportView extends StatelessWidget {
  const SupportView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/support";

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Support",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedWhiteContainer(
            child: Text(
              "If you need support or want to report a bug, reach out to us on any of our socials!",
              style: STextStyles.smallMed12(context),
            ),
          ),
          isDesktop
              ? const SizedBox(
                  height: 24,
                )
              : const SizedBox(
                  height: 12,
                ),
          AboutItem(
            linkUrl: "https://t.me/stackwallet",
            label: "Telegram",
            buttonText: "@stackwallet",
            iconAsset: Assets.socials.telegram,
            isDesktop: isDesktop,
          ),
          const SizedBox(
            height: 8,
          ),
          AboutItem(
            linkUrl: "https://discord.com/invite/mRPZuXx3At",
            label: "Discord",
            buttonText: "Stack Duo",
            iconAsset: Assets.socials.discord,
            isDesktop: isDesktop,
          ),
          const SizedBox(
            height: 8,
          ),
          AboutItem(
            linkUrl: "https://www.reddit.com/r/stackwallet/",
            label: "Reddit",
            buttonText: "r/stackwallet",
            iconAsset: Assets.socials.reddit,
            isDesktop: isDesktop,
          ),
          const SizedBox(
            height: 8,
          ),
          AboutItem(
            linkUrl: "https://twitter.com/stack_wallet",
            label: "Twitter",
            buttonText: "@stack_wallet",
            iconAsset: Assets.socials.twitter,
            isDesktop: isDesktop,
          ),
          const SizedBox(
            height: 8,
          ),
          AboutItem(
            linkUrl: "mailto:support@stackwallet.com",
            label: "Email",
            buttonText: "support@stackwallet.com",
            iconAsset: Assets.svg.envelope,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }
}

class AboutItem extends StatelessWidget {
  const AboutItem({
    Key? key,
    required this.linkUrl,
    required this.label,
    required this.buttonText,
    required this.iconAsset,
    required this.isDesktop,
  }) : super(key: key);

  final String linkUrl;
  final String label;
  final String buttonText;
  final String iconAsset;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final double iconSize = isDesktop ? 20 : 28;

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: RawMaterialButton(
        // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () {
          launchUrl(
            Uri.parse(linkUrl),
            mode: LaunchMode.externalApplication,
          );
        },
        child: Padding(
          padding: isDesktop
              ? const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                )
              : const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ConditionalParent(
                    condition: isDesktop,
                    builder: (child) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10000),
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .buttonBackSecondary,
                      ),
                      child: Center(
                        child: child,
                      ),
                    ),
                    child: SvgPicture.asset(
                      iconAsset,
                      width: iconSize,
                      height: iconSize,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .bottomNavIconIcon,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    label,
                    style: STextStyles.titleBold12(context),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
              if (isDesktop)
                Text(
                  buttonText,
                  style: STextStyles.desktopTextExtraExtraSmall(context),
                )
              // BlueTextButton(
              //   text: buttonText,
              //   onTap: () {
              //     launchUrl(
              //       Uri.parse(linkUrl),
              //       mode: LaunchMode.externalApplication,
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
