import 'package:flutter/material.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackduo/widgets/stack_dialog.dart';

class BasicDialog extends StatelessWidget {
  const BasicDialog({
    Key? key,
    this.leftButton,
    this.rightButton,
    this.icon,
    required this.title,
    this.message,
    this.desktopHeight = 474,
    this.desktopWidth = 641,
    this.canPopWithBackButton = false,
  }) : super(key: key);

  final Widget? leftButton;
  final Widget? rightButton;

  final Widget? icon;

  final String title;
  final String? message;

  final double? desktopHeight;
  final double desktopWidth;

  final bool canPopWithBackButton;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    if (isDesktop) {
      return DesktopDialog(
        maxHeight: desktopHeight,
        maxWidth: desktopWidth,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: STextStyles.desktopH3(context),
                  ),
                  const DesktopDialogCloseButton(),
                ],
              ),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message!,
                  style: STextStyles.desktopTextSmall(context),
                ),
              ),
            if (leftButton != null || rightButton != null)
              const SizedBox(
                height: 32,
              ),
            if (leftButton != null || rightButton != null)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    leftButton != null
                        ? Expanded(child: leftButton!)
                        : const Spacer(),
                    const SizedBox(
                      width: 16,
                    ),
                    rightButton != null
                        ? Expanded(child: rightButton!)
                        : const Spacer(),
                  ],
                ),
              )
          ],
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: () async {
          return canPopWithBackButton;
        },
        child: StackDialog(
          title: title,
          leftButton: leftButton,
          rightButton: rightButton,
          icon: icon,
          message: message,
        ),
      );
    }
  }
}
