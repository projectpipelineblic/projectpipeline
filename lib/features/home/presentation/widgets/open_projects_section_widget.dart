import 'package:flutter/material.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/core/extension/themex.dart';
import 'package:task_app/core/theme/app_pallete.dart';

class OpenProjectsSectionWidget extends StatelessWidget {
  const OpenProjectsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryText(
            text: 'Open projects',
            size: 24,
            fontWeight: FontWeight.bold,
            color: context.colors.secondary,
          ),
        ),
        const SizedBox(height: 16),
        _EmptyProjectState(),
      ],
    );
  }
}

class _EmptyProjectState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppPallete.lightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 48,
                color: AppPallete.textGray,
              ),
              const SizedBox(height: 12),
              PrimaryText(
                text: 'There is no active open project at the moment',
                size: 16,
                color: AppPallete.textGray,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

