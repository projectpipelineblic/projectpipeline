import 'package:flutter/material.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Divider(color: Colors.grey, thickness: 1),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: Colors.white,
          child: PrimaryText(text: 'Or', size: 16, color: AppPallete.black),
        ),
      ],
    );
  }
}
