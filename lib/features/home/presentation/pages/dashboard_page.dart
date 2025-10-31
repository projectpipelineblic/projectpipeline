import 'package:flutter/material.dart';
import 'package:task_app/features/home/presentation/widgets/dashboard_header_widget.dart';
import 'package:task_app/features/home/presentation/widgets/todays_tasks_section_widget.dart';
import 'package:task_app/features/home/presentation/widgets/open_projects_section_widget.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardHeaderWidget(),
              const TodaysTasksSectionWidget(),
              const SizedBox(height: 32),
              const OpenProjectsSectionWidget(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}


