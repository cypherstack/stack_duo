import 'package:flutter/cupertino.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    Key? key,
    required this.width,
    required this.height,
    required this.fillColor,
    required this.backgroundColor,
    required this.percent,
  }) : super(key: key);

  final double width;
  final double height;
  final Color fillColor;
  final Color backgroundColor;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final double fillLength = width * percent;
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: height,
              width: fillLength,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            )
          ],
        ),
      ),
    );
  }
}
