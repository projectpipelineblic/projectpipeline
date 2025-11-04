import 'package:flutter/material.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/core/extension/themex.dart';

class DashboardHeaderWidget extends StatelessWidget {
  const DashboardHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimaryText(
            text: 'Dashboard',
            size: 32,
            fontWeight: FontWeight.bold,
            color: context.colors.secondary,
          ),
        ],
      ),
    );
  }
}

