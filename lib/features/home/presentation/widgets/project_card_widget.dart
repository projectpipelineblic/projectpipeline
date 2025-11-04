import 'package:flutter/material.dart';
import 'package:task_app/core/extension/themex.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:task_app/features/projects/domain/entities/project_entity.dart';

class ProjectCardWidget extends StatelessWidget {
  final ProjectEntity project;
  final VoidCallback? onTap;

  const ProjectCardWidget({
    super.key,
    required this.project,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF404040) 
                : AppPallete.borderGray,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppPallete.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: AppPallete.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PrimaryText(
                        text: project.name,
                        size: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.secondary,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      PrimaryText(
                        text: '${project.members.length} member${project.members.length > 1 ? 's' : ''}',
                        size: 12,
                        color: AppPallete.textGray,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppPallete.textGray,
                  size: 20,
                ),
              ],
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              PrimaryText(
                text: project.description,
                size: 13,
                color: AppPallete.textGray,
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

