import 'package:flutter/material.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';
import 'package:task_app/features/tasks_board/presentation/widgets/kanban_task_card_widget.dart';

class KanbanColumnWidget extends StatelessWidget {
  final String title;
  final List<TaskEntity> tasks;
  final TaskStatus columnStatus;
  final Color headerColor;
  final Function(TaskEntity)? onTaskTap;
  final Function(TaskEntity)? onTaskDrop;

  const KanbanColumnWidget({
    super.key,
    required this.title,
    required this.tasks,
    required this.columnStatus,
    required this.headerColor,
    this.onTaskTap,
    this.onTaskDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E).withOpacity(0.5)
              : AppPallete.lightGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: headerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PrimaryText(
                    text: title,
                    size: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.secondary,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: headerColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PrimaryText(
                      text: '${tasks.length}',
                      size: 12,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DragTarget<TaskEntity>(
                onAcceptWithDetails: (details) {
                  final task = details.data;
                  if (onTaskDrop != null && task.status != columnStatus) {
                    onTaskDrop!(task);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  final isTargeted = candidateData.isNotEmpty;
                  return Container(
                    decoration: BoxDecoration(
                      color: isTargeted
                          ? headerColor.withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: tasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: AppPallete.textGray.withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                PrimaryText(
                                  text: 'No tasks',
                                  size: 14,
                                  color: AppPallete.textGray.withOpacity(0.7),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return Draggable<TaskEntity>(
                                key: ValueKey(task.id),
                                data: task,
                                feedback: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Opacity(
                                    opacity: 0.9,
                                    child: Container(
                                      width: 280,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardTheme.color,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFF404040)
                                              : AppPallete.borderGray,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: PrimaryText(
                                        text: task.title,
                                        size: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: KanbanTaskCardWidget(
                                    task: task,
                                    onTap: onTaskTap != null
                                        ? () => onTaskTap!(task)
                                        : null,
                                  ),
                                ),
                                child: KanbanTaskCardWidget(
                                  task: task,
                                  onTap: onTaskTap != null
                                      ? () => onTaskTap!(task)
                                      : null,
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

