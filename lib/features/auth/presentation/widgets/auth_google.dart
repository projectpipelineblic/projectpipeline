import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:project_pipeline/core/extension/themex.dart';
import 'package:project_pipeline/core/widgets/secondary_text.dart';

class GoogleButton extends StatelessWidget {
  final void Function()? onTap;
  const GoogleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.95;
    final height = MediaQuery.of(context).size.height * 0.06;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.secondary),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/google.svg', height: 30, width: 30 ),
            SizedBox(width: 10),
            SecondaryText(
              text: 'Login with Google',
              size: 16,
              fontWeight: FontWeight.w500,
              color: context.colors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
