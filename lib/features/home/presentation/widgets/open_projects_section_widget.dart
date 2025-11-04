import 'package:flutter/material.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/core/extension/themex.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:task_app/features/projects/domain/entities/project_entity.dart';
import 'package:task_app/features/home/presentation/widgets/project_card_widget.dart';
import 'package:task_app/features/projects/presentation/pages/project_detail_page.dart';

class OpenProjectsSectionWidget extends StatelessWidget {
  final List<ProjectEntity> projects;

  const OpenProjectsSectionWidget({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    final hasProjects = projects.isNotEmpty;

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
        if (hasProjects)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: projects.map((project) {
                return ProjectCardWidget(
                  project: project,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailPage(project: project),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          )
        else
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
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : AppPallete.lightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 48,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9CA3AF)
                    : AppPallete.textGray,
              ),
              const SizedBox(height: 12),
              PrimaryText(
                text: 'There is no active open project at the moment',
                size: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9CA3AF)
                    : AppPallete.textGray,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

