import 'package:flutter/material.dart';
import 'package:project_pipeline/core/extension/themex.dart';
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
          child: Divider(color: context.colors.secondary, thickness: 1),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: context.colors.surface,
          child: PrimaryText(text: 'Or', size: 16, color: context.colors.secondary),
        ),
      ],
    );
  }
}
