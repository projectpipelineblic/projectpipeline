import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_pipeline/core/extension/themex.dart';
import 'package:project_pipeline/core/theme/app_theme.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/app-logo.svg',
          height: 70,
          width: 70,
        ),
        SizedBox(
          width: 10,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PrimaryText(
              text: 'Project',
              size: 25,
              fontWeight: FontWeight.w600,
              color: context.colors.secondary,
            ),
            PrimaryText(
              text: 'Pipeline',
              size: 25,
              color: context.colors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ],
        )
      ],
    );
  }
}
