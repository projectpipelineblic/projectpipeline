import 'package:flutter/material.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key, required this.tasks});

  final List<TaskEntity> tasks;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Center(
          child: PrimaryText(
            text: 'No tasks yet',
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final t in tasks) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: _priorityColor(t.priority).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.checklist,
                  color: _priorityColor(t.priority),
                  size: 25,
                ),
              ),
              title: PrimaryText(
                text: t.title,
                size: 16,
                fontWeight: FontWeight.w700,
                color: AppPallete.secondary,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrimaryText(
                      text: 'Assignee: ${t.assigneeName}',
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    if (t.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: PrimaryText(
                          text: 'Due date: ${_formatShortDate(t.dueDate!)}',
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              onTap: () {},
            ),
          ),
        ]
      ],
    );
  }

  // Status color kept for potential future use; currently priority drives the icon UI.

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.amber;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}


