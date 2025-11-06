import 'package:flutter/material.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';

class TaskList extends StatelessWidget {
  const TaskList({
    super.key, 
    required this.tasks,
    this.project,
  });

  final List<TaskEntity> tasks;
  final ProjectEntity? project;

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
                  color: _statusColor(t).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.checklist,
                  color: _statusColor(t),
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
                    const SizedBox(height: 6),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(t).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _statusColor(t).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _statusColor(t),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          PrimaryText(
                            text: t.statusName ?? _statusLabel(t.status),
                            size: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(t),
                          ),
                        ],
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

  // Get color based on task status (custom statuses or default)
  Color _statusColor(TaskEntity task) {
    // If task has a custom statusName and project has custom statuses, find the matching color
    if (task.statusName != null && project?.customStatuses != null) {
      final matchingStatus = project!.customStatuses!.firstWhere(
        (status) => status.name == task.statusName,
        orElse: () => project!.customStatuses!.first,
      );
      
      // Parse hex color
      final hexColor = matchingStatus.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    
    // Fall back to default status colors
    switch (task.status) {
      case TaskStatus.todo:
        return const Color(0xFFF59E0B); // Amber
      case TaskStatus.inProgress:
        return const Color(0xFF8B5CF6); // Purple
      case TaskStatus.done:
        return const Color(0xFF10B981); // Green
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}


