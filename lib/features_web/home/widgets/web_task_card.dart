import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart' as domain;
import 'package:project_pipeline/features/projects/presentation/pages/task_detail_page.dart';
import 'package:project_pipeline/features/projects/presentation/shared/task_types.dart';

class WebTaskCard extends StatelessWidget {
  final domain.TaskEntity task;
  final bool isDark;

  const WebTaskCard({
    super.key,
    required this.task,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to task detail page
        // Convert domain enums to presentation enums
        final taskItem = TaskItem(
          id: task.id,
          title: task.title,
          description: task.description,
          assigneeId: task.assigneeId,
          assigneeName: task.assigneeName,
          priority: _convertPriority(task.priority),
          subTasks: task.subTasks,
          dueDate: task.dueDate,
          status: _convertStatus(task.status),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(
              task: taskItem,
              projectId: task.projectId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      child: Row(
        children: [
          Checkbox(
            value: task.status == domain.TaskStatus.done,
            onChanged: (value) {
              // TODO: Update task status
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            activeColor: const Color(0xFF10B981),
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    decoration: task.status == domain.TaskStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getPriorityText(task.priority),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getPriorityColor(task.priority),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _getPriorityText(domain.TaskPriority priority) {
    switch (priority) {
      case domain.TaskPriority.high:
        return 'High';
      case domain.TaskPriority.medium:
        return 'Medium';
      case domain.TaskPriority.low:
        return 'Low';
    }
  }

  Color _getPriorityColor(domain.TaskPriority priority) {
    switch (priority) {
      case domain.TaskPriority.high:
        return const Color(0xFFEF4444);
      case domain.TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case domain.TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  // Convert domain enums to presentation enums
  TaskPriority _convertPriority(domain.TaskPriority priority) {
    switch (priority) {
      case domain.TaskPriority.high:
        return TaskPriority.high;
      case domain.TaskPriority.medium:
        return TaskPriority.medium;
      case domain.TaskPriority.low:
        return TaskPriority.low;
    }
  }

  TaskStatus _convertStatus(domain.TaskStatus status) {
    switch (status) {
      case domain.TaskStatus.todo:
        return TaskStatus.todo;
      case domain.TaskStatus.inProgress:
        return TaskStatus.inProgress;
      case domain.TaskStatus.done:
        return TaskStatus.done;
    }
  }
}

