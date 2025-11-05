import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:project_pipeline/core/extension/themex.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';

class KanbanTaskCardWidget extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback? onTap;

  const KanbanTaskCardWidget({
    super.key,
    required this.task,
    this.onTap,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  String _getPriorityText() {
    switch (task.priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String _formatDueDate() {
    if (task.dueDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    if (dueDate.isBefore(today)) {
      final diff = today.difference(dueDate).inDays;
      return 'Overdue $diff d';
    } else if (dueDate == today) {
      return 'Today';
    } else {
      return DateFormat('MMM dd').format(task.dueDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != TaskStatus.done;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
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
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getPriorityColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: PrimaryText(
                    text: _getPriorityText(),
                    size: 11,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(),
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: PrimaryText(
                      text: 'OVERDUE',
                      size: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryText(
              text: task.title,
              size: 16,
              fontWeight: FontWeight.bold,
              color: context.colors.secondary,
              maxLines: 2,
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              PrimaryText(
                text: task.description,
                size: 13,
                color: AppPallete.textGray,
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 12),
            if (task.dueDate != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isOverdue ? Colors.red : AppPallete.textGray,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: PrimaryText(
                      text: _formatDueDate(),
                      size: 11,
                      color: isOverdue ? Colors.red : AppPallete.textGray,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            if (task.dueDate != null) const SizedBox(height: 8),
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

