import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class RecoveryPhraseExplanationDialog extends StatelessWidget {
  const RecoveryPhraseExplanationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height -
                16 -
                16 -
                24 -
                24 -
                24 -
                76,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recovery phrase explained",
                    style: STextStyles.titleBold12(context),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    "The car analogy.",
                    style: STextStyles.titleBold12(context).copyWith(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "You can drive your car when your have your car keys. If you lose your car keys, you can’t drive you car. If someone steals your car keys, they can steal your car. If someone copies your car keys, they can also steal your car.",
                    style: STextStyles.baseXS(context),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Cryptocurrency works the same way. These recovery phrase words we’re about to show you are like the car keys in the metaphor above.",
                    style: STextStyles.baseXS(context),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "If you lose these words, you can’t access your money. If someone steals these words, they can access and steal your money. If someone copies these words, they can access and steal your money.",
                    style: STextStyles.baseXS(context),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "If your funds are lost or stolen because of you don’t write down your recovery phrase or keep it safe, then NOBODY, NOT EVEN US, can help you recover your money.",
                    style: STextStyles.baseXS(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              const Spacer(),
              Expanded(
                child: SecondaryButton(
                  label: "Close",
                  onPressed: Navigator.of(context).pop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}