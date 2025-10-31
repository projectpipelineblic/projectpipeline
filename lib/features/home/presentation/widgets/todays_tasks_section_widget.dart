import 'package:flutter/material.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/core/extension/themex.dart';
import 'package:task_app/core/theme/app_pallete.dart';

class TodaysTasksSectionWidget extends StatelessWidget {
  const TodaysTasksSectionWidget({super.key});

  // TODO: Replace with actual tasks count when data is available
  static const int _taskCount = 0;

  @override
  Widget build(BuildContext context) {
    final bool hasTasks = _taskCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryText(
            text: "Today's tasks",
            size: 24,
            fontWeight: FontWeight.bold,
            color: context.colors.secondary,
          ),
        ),
        const SizedBox(height: 16),
        if (hasTasks) ...[
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: _taskCount,
              controller: PageController(
                viewportFraction: 0.85,
              ),
              padEnds: false,
              itemBuilder: (context, index) {
                // TODO: Return actual task card when tasks are available
                return const SizedBox();
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _taskCount,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _DotIndicator(isActive: index == 0),
                ),
              ),
            ),
          ),
        ] else
          _EmptyTaskCard(),
      ],
    );
  }
}

class _EmptyTaskCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
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
                Icons.task_outlined,
                size: 48,
                color: AppPallete.textGray,
              ),
              const SizedBox(height: 12),
              PrimaryText(
                text: 'No task for today',
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

class _DotIndicator extends StatelessWidget {
  final bool isActive;

  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppPallete.primary : AppPallete.borderGray,
      ),
    );
  }
}

