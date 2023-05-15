import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/themes/stack_colors.dart';

class WhirlpoolNavIcon extends StatelessWidget {
  const WhirlpoolNavIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.whirlPool,
      height: 20,
      width: 20,
      color: Theme.of(context).extension<StackColors>()!.bottomNavIconIcon,
    );
  }
}
