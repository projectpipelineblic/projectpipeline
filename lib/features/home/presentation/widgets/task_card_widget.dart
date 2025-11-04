import 'package:flutter/material.dart';
import 'package:task_app/core/extension/themex.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart' as task_entity;
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

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != task_entity.TaskStatus.done;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 8),
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            PrimaryText(
              text: task.title,
              size: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.secondary,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            PrimaryText(
              text: task.description,
              size: 14,
              color: AppPallete.textGray,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppPallete.textGray,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: PrimaryText(
                    text: task.assigneeName,
                    size: 12,
                    color: AppPallete.textGray,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            if (task.subTasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.checklist_outlined,
                    size: 16,
                    color: AppPallete.textGray,
                  ),
                  const SizedBox(width: 6),
                  PrimaryText(
                    text: '${task.subTasks.length} subtask${task.subTasks.length > 1 ? 's' : ''}',
                    size: 12,
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

