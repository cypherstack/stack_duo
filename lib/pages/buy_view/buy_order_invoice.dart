import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/buy/response_objects/order.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class BuyOrderInvoiceView extends StatefulWidget {
  const BuyOrderInvoiceView({
    Key? key,
    required this.order,
  }) : super(key: key);

  final SimplexOrder order;

  static const String routeName = "/buyOrderInvoice";

  @override
  State<BuyOrderInvoiceView> createState() => _BuyOrderInvoiceViewState();
}

class _BuyOrderInvoiceViewState extends State<BuyOrderInvoiceView> {
  final isDesktop = Util.isDesktop;

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.backgroundAppBar,
              leading: const AppBarBackButton(),
              title: Text(
                "Order invoice",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: LayoutBuilder(
              builder: (builderContext, constraints) {
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    top: 12,
                    right: 12,
                  ),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 24,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Simplex Order",
            style: STextStyles.pageTitleH1(context),
          ),
          const SizedBox(
            height: 16,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quoted cost",
                  style: STextStyles.label(context),
                ),
                Text(
                  "${widget.order.quote.youPayFiatPrice.toStringAsFixed(2)} ${widget.order.quote.fiat.ticker.toUpperCase()}",
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          // RoundedWhiteContainer(
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Text(
          //         "You pay with",
          //         style: STextStyles.label(context),
          //       ),
          //       Text(
          //         widget.quote.fiat.name,
          //         style: STextStyles.label(context).copyWith(
          //           color: Theme.of(context).extension<StackColors>()!.textDark,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(
          //   height: 8,
          // ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quoted amount",
                  style: STextStyles.label(context),
                ),
                Text(
                  "${widget.order.quote.youReceiveCryptoAmount} ${widget.order.quote.crypto.ticker.toUpperCase()}",
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Receiving ${widget.order.quote.crypto.ticker.toUpperCase()} address",
                  style: STextStyles.label(context),
                ),
                Text(
                  "${widget.order.quote.receivingAddress} ",
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quote ID",
                  style: STextStyles.label(context),
                ),
                Text(
                  widget.order.quote.id,
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Purchase ID",
                  style: STextStyles.label(context),
                ),
                Text(
                  widget.order.paymentId,
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "User ID",
                  style: STextStyles.label(context),
                ),
                Text(
                  widget.order.userId,
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Provider",
                  style: STextStyles.label(context),
                ),
                SizedBox(
                  width: 64,
                  height: 32,
                  child: SvgPicture.asset(
                    Assets.buy.simplexLogo(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              "This information is not saved,\nscreenshot it now for your records",
              style: STextStyles.label(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ]),
          const Spacer(),
          PrimaryButton(
            label: "Dismiss",
            onPressed: () {
              Navigator.of(context, rootNavigator: isDesktop).pop();
            },
          )
        ],
      ),
    );
  }
}
