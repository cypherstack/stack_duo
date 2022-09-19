import 'package:flutter/material.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_table.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

class MyWallets extends StatefulWidget {
  const MyWallets({Key? key}) : super(key: key);

  @override
  State<MyWallets> createState() => _MyWalletsState();
}

class _MyWalletsState extends State<MyWallets> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.greenAccent,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Favorite wallets",
              style: STextStyles.desktopTextExtraSmall.copyWith(
                color: CFColors.textFieldActiveSearchIconRight,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            // TODO favorites grid
            Container(
              color: Colors.deepPurpleAccent,
              height: 210,
            ),

            const SizedBox(
              height: 40,
            ),

            Row(
              children: [
                Text(
                  "All wallets",
                  style: STextStyles.desktopTextExtraSmall.copyWith(
                    color: CFColors.textFieldActiveSearchIconRight,
                  ),
                ),
                const Spacer(),
                BlueTextButton(
                  text: "Add new wallet",
                  onTap: () {
                    // TODO add wallet
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),
            const WalletTable(),
          ],
        ),
      ),
    );
  }
}
