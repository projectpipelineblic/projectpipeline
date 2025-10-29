import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthRichText extends StatelessWidget {
  final String firstWord;
  final String secondWord;
  final String thirdWord;
  final double fontSize;
  final Color? primaryColor;
  final Color? secondaryColor;

  const AuthRichText({
    super.key,
    required this.firstWord,
    required this.secondWord,
    required this.thirdWord,
    this.fontSize = 16,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Theme.of(context).colorScheme.secondary;
    final secondary = secondaryColor ?? Theme.of(context).colorScheme.primary;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize.sp,
          color: primary,
        ),
        children: [
          TextSpan(text: '$firstWord. '),
          TextSpan(
            text: '$secondWord. ',
            style: TextStyle(
              color: secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: thirdWord),
        ],
      ),
    );
  }
}
