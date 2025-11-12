import 'package:flutter/material.dart';
import 'package:project_pipeline/core/extension/themex.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart' as task_entity;
import 'package:intl/intl.dart';

class TaskCardWidget extends StatelessWidget {
  final task_entity.TaskEntity task;
  final VoidCallback? onTap;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.onTap,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case task_entity.TaskPriority.high:
        return Colors.red;
      case task_entity.TaskPriority.medium:
        return Colors.orange;
      case task_entity.TaskPriority.low:
        return Colors.green;
    }
  }

  String _getPriorityText() {
    switch (task.priority) {
      case task_entity.TaskPriority.high:
        return 'High';
      case task_entity.TaskPriority.medium:
        return 'Medium';
      case task_entity.TaskPriority.low:
        return 'Low';
    }
  }

  String _formatDueDate() {
    if (task.dueDate == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    if (dueDate.isBefore(today)) {
      final diff = today.difference(dueDate).inDays;
      return 'Overdue by $diff day${diff > 1 ? 's' : ''}';
    } else if (dueDate == today) {
      return 'Due today';
    } else {
      return 'Due ${DateFormat('MMM dd').format(task.dueDate!)}';
    }
  }

  String _getStatusLabel() {
    // If task has a custom statusName, use it
    if (task.statusName != null && task.statusName!.isNotEmpty) {
      return task.statusName!;
    }
    
    // Fall back to default status labels
    switch (task.status) {
      case task_entity.TaskStatus.todo:
        return 'To Do';
      case task_entity.TaskStatus.inProgress:
        return 'In Progress';
      case task_entity.TaskStatus.done:
        return 'Done';
    }
  }

  Color _getStatusColor() {
    // Use default status colors (project context not available here)
    switch (task.status) {
      case task_entity.TaskStatus.todo:
        return const Color(0xFFF59E0B); // Amber
      case task_entity.TaskStatus.inProgress:
        return const Color(0xFF8B5CF6); // Purple
      case task_entity.TaskStatus.done:
        return const Color(0xFF10B981); // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != task_entity.TaskStatus.done;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue 
                ? Colors.red.shade200 
                : (Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF404040) 
                    : AppPallete.borderGray),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PrimaryText(
                    text: _getPriorityText(),
                    size: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(),
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: PrimaryText(
                      text: 'OVERDUE',
                      size: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryText(
              text: task.title,
              size: 17,
              fontWeight: FontWeight.bold,
              color: context.colors.secondary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            PrimaryText(
              text: task.description,
              size: 13,
              color: AppPallete.textGray,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: isOverdue ? Colors.red : AppPallete.textGray,
                ),
                const SizedBox(width: 6),
                PrimaryText(
                  text: _formatDueDate(),
                  size: 12,
                  color: isOverdue ? Colors.red : AppPallete.textGray,
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Status chip and Sprint badge
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      PrimaryText(
                        text: _getStatusLabel(),
                        size: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Sprint badge
                if (task.sprintId != null && task.sprintId!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.rocket_launch,
                          size: 11,
                          color: Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 4),
                        PrimaryText(
                          text: task.storyPoints != null 
                              ? 'Sprint • ${task.storyPoints} SP'
                              : 'Sprint',
                          size: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Assignee info
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppPallete.textGray,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: PrimaryText(
                    text: task.assigneeName,
                    size: 11,
                    color: AppPallete.textGray,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (task.subTasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.checklist_outlined,
                    size: 14,
                    color: AppPallete.textGray,
                  ),
                  const SizedBox(width: 4),
                  PrimaryText(
                    text: '${task.subTasks.length} subtask${task.subTasks.length > 1 ? 's' : ''}',
                    size: 11,
                    color: AppPallete.textGray,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

