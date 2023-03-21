import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/pages/stack_privacy_calls.dart';
import 'package:stackduo/pages_desktop_specific/password/create_password_view.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/prefs.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/desktop/secondary_button.dart';
import 'package:url_launcher/url_launcher.dart';

class IntroView extends StatefulWidget {
  const IntroView({Key? key}) : super(key: key);

  static const String routeName = "/introView";

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  late final bool isDesktop;

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        body: Center(
          child: !isDesktop
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(
                      flex: 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 300,
                        ),
                        child: SvgPicture.asset(
                          Assets.svg.stack(context),
                          width: isDesktop ? 324 : 266,
                          height: isDesktop ? 324 : 266,
                        ),
                      ),
                    ),
                    const Spacer(
                      flex: 1,
                    ),
                    AppNameText(
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                      ),
                      child: IntroAboutText(
                        isDesktop: isDesktop,
                      ),
                    ),
                    const Spacer(
                      flex: 4,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                      ),
                      child: PrivacyAndTOSText(
                        isDesktop: isDesktop,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GetStartedButton(
                              isDesktop: isDesktop,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: 350,
                  height: 540,
                  child: Column(
                    children: [
                      const Spacer(
                        flex: 2,
                      ),
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: SvgPicture.asset(
                          Assets.svg.stackDuoIcon(context),
                        ),
                      ),
                      const Spacer(
                        flex: 42,
                      ),
                      AppNameText(
                        isDesktop: isDesktop,
                      ),
                      const Spacer(
                        flex: 24,
                      ),
                      IntroAboutText(
                        isDesktop: isDesktop,
                      ),
                      const Spacer(
                        flex: 42,
                      ),
                      GetStartedButton(
                        isDesktop: isDesktop,
                      ),
                      if (isDesktop)
                        const SizedBox(
                          height: 20,
                        ),
                      if (isDesktop)
                        SecondaryButton(
                          label: "Restore from Stack backup",
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              CreatePasswordView.routeName,
                              arguments: true,
                            );
                          },
                        ),
                      const Spacer(
                        flex: 65,
                      ),
                      PrivacyAndTOSText(
                        isDesktop: isDesktop,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class AppNameText extends StatelessWidget {
  const AppNameText({Key? key, required this.isDesktop}) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Text(
      "Stack Wallet",
      textAlign: TextAlign.center,
      style: !isDesktop
          ? STextStyles.pageTitleH1(context)
          : STextStyles.pageTitleH1(context).copyWith(
              fontSize: 40,
            ),
    );
  }
}

class IntroAboutText extends StatelessWidget {
  const IntroAboutText({Key? key, required this.isDesktop}) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Text(
      "An open-source, multicoin wallet for everyone",
      textAlign: TextAlign.center,
      style: !isDesktop
          ? STextStyles.subtitle(context)
          : STextStyles.subtitle(context).copyWith(
              fontSize: 24,
            ),
    );
  }
}

class PrivacyAndTOSText extends StatelessWidget {
  const PrivacyAndTOSText({Key? key, required this.isDesktop})
      : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final fontSize = isDesktop ? 18.0 : 12.0;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: STextStyles.label(context).copyWith(fontSize: fontSize),
        children: [
          const TextSpan(text: "By using Stack Wallet, you agree to the "),
          TextSpan(
            text: "Terms of service",
            style: STextStyles.richLink(context).copyWith(fontSize: fontSize),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://stackwallet.com/terms-of-service.html"),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
          const TextSpan(text: " and "),
          TextSpan(
            text: "Privacy policy",
            style: STextStyles.richLink(context).copyWith(fontSize: fontSize),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://stackwallet.com/privacy-policy.html"),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
        ],
      ),
    );
  }
}

class GetStartedButton extends StatelessWidget {
  const GetStartedButton({Key? key, required this.isDesktop}) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return !isDesktop
        ? TextButton(
            style: Theme.of(context)
                .extension<StackColors>()!
                .getPrimaryEnabledButtonStyle(context),
            onPressed: () {
              Prefs.instance.externalCalls = true;
              Navigator.of(context).pushNamed(
                StackPrivacyCalls.routeName,
                arguments: false,
              );
            },
            child: Text(
              "Get started",
              style: STextStyles.button(context),
            ),
          )
        : SizedBox(
            width: double.infinity,
            height: 70,
            child: TextButton(
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getPrimaryEnabledButtonStyle(context),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  StackPrivacyCalls.routeName,
                  arguments: false,
                );
              },
              child: Text(
                "Create new Stack",
                style: STextStyles.button(context).copyWith(fontSize: 20),
              ),
            ),
          );
  }
}
