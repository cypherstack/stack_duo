import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

class DesktopAddressCard extends StatelessWidget {
  const DesktopAddressCard({
    Key? key,
    required this.entry,
    required this.contactId,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final ContactAddressEntry entry;
  final String contactId;
  final ClipboardInterface clipboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          Assets.svg.iconFor(
            coin: entry.coin,
          ),
          height: 32,
          width: 32,
        ),
        const SizedBox(
          width: 16,
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                "${entry.label} (${entry.coin.ticker})",
                style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              SelectableText(
                entry.address,
                style: STextStyles.desktopTextExtraExtraSmall(context),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  BlueTextButton(
                    text: "Copy",
                    onTap: () {
                      clipboard.setData(
                        ClipboardData(text: entry.address),
                      );
                      showFloatingFlushBar(
                        type: FlushBarType.info,
                        message: "Copied to clipboard",
                        iconAsset: Assets.svg.copy,
                        context: context,
                      );
                    },
                  ),
                  if (contactId != "default")
                    const SizedBox(
                      width: 16,
                    ),
                  if (contactId != "default")
                    BlueTextButton(
                      text: "Edit",
                      onTap: () {},
                    ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
