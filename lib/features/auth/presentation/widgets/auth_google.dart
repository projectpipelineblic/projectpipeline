import 'package:flutter/material.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
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
          border: Border.all(color: AppPallete.black),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('assets/google.png'),
              height: 60,
              width: 60,
            ),
            SecondaryText(
              text: 'Login with Google',
              size: 16,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}
