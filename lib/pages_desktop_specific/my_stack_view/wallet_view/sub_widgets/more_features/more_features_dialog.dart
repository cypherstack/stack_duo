import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackduo/providers/global/prefs_provider.dart';
import 'package:stackduo/providers/global/wallets_provider.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/themes/stack_colors.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackduo/widgets/rounded_container.dart';

class MoreFeaturesDialog extends ConsumerStatefulWidget {
  const MoreFeaturesDialog({
    Key? key,
    required this.walletId,
    required this.onPaynymPressed,
    required this.onCoinControlPressed,
    required this.onWhirlpoolPressed,
  }) : super(key: key);

  final String walletId;
  final VoidCallback? onPaynymPressed;
  final VoidCallback? onCoinControlPressed;
  final VoidCallback? onWhirlpoolPressed;

  @override
  ConsumerState<MoreFeaturesDialog> createState() => _MoreFeaturesDialogState();
}

class _MoreFeaturesDialogState extends ConsumerState<MoreFeaturesDialog> {
  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManager(widget.walletId),
      ),
    );

    final coinControlPrefEnabled = ref.watch(
      prefsChangeNotifierProvider.select(
        (value) => value.enableCoinControl,
      ),
    );

    return DesktopDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                ),
                child: Text(
                  "More features",
                  style: STextStyles.desktopH3(context),
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          if (manager.hasWhirlpoolSupport)
            _MoreFeaturesItem(
              label: "Whirlpool",
              detail: "Powerful Bitcoin privacy enhancer",
              iconAsset: Assets.svg.whirlPool,
              onPressed: () => widget.onWhirlpoolPressed?.call(),
            ),
          if (manager.hasCoinControlSupport && coinControlPrefEnabled)
            _MoreFeaturesItem(
              label: "Coin control",
              detail: "Control, freeze, and utilize outputs at your discretion",
              iconAsset: Assets.svg.coinControl.gamePad,
              onPressed: () => widget.onCoinControlPressed?.call(),
            ),
          if (manager.hasPaynymSupport)
            _MoreFeaturesItem(
              label: "PayNym",
              detail: "Increased address privacy using BIP47",
              iconAsset: Assets.svg.robotHead,
              onPressed: () => widget.onPaynymPressed?.call(),
            ),
          const SizedBox(
            height: 28,
          ),
        ],
      ),
    );
  }
}

class _MoreFeaturesItem extends StatelessWidget {
  const _MoreFeaturesItem({
    Key? key,
    required this.label,
    required this.detail,
    required this.iconAsset,
    this.onPressed,
  }) : super(key: key);

  static const double iconSizeBG = 46;
  static const double iconSize = 24;

  final String label;
  final String detail;
  final String iconAsset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 32,
      ),
      child: RoundedContainer(
        color: Colors.transparent,
        borderColor:
            Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
        onPressed: onPressed,
        child: Row(
          children: [
            RoundedContainer(
              padding: const EdgeInsets.all(0),
              color:
                  Theme.of(context).extension<StackColors>()!.settingsIconBack,
              width: iconSizeBG,
              height: iconSizeBG,
              radiusMultiplier: iconSizeBG,
              child: Center(
                child: SvgPicture.asset(
                  iconAsset,
                  width: iconSize,
                  height: iconSize,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .settingsIconIcon,
                ),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: STextStyles.w600_20(context),
                ),
                Text(
                  detail,
                  style: STextStyles.desktopTextExtraExtraSmall(context),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
