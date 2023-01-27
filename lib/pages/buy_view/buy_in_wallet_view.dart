import 'package:flutter/material.dart';
import 'package:stackwallet/pages/buy_view/buy_view.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class BuyInWalletView extends StatefulWidget {
  const BuyInWalletView({Key? key}) : super(key: key);

  static const String routeName = "/stackBuyInWalletView";

  @override
  State<BuyInWalletView> createState() => _BuyInWalletViewState();
}

class _BuyInWalletViewState extends State<BuyInWalletView> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Buy ",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: const BuyView(),
      ),
    );
  }
}
