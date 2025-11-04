import 'package:flutter/material.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';
import 'package:task_app/features/tasks_board/presentation/widgets/kanban_task_card_widget.dart';

class VerticalTaskSectionWidget extends StatelessWidget {
  final String title;
  final List<TaskEntity> tasks;
  final TaskStatus columnStatus;
  final Color headerColor;
  final Function(TaskEntity)? onTaskTap;
  final Function(TaskEntity)? onTaskDrop;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final Function(double)? onDragUpdate;

  const VerticalTaskSectionWidget({
    super.key,
    required this.title,
    required this.tasks,
    required this.columnStatus,
    required this.headerColor,
    this.onTaskTap,
    this.onTaskDrop,
    this.onDragStart,
    this.onDragEnd,
    this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E).withOpacity(0.5)
            : AppPallete.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
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
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryText(
                    text: title,
                    size: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE5E7EB)
                        : AppPallete.secondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: headerColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PrimaryText(
                    text: '${tasks.length}',
                    size: 14,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
              ],
            ),
          ),
          // Task drop zone
          DragTarget<TaskEntity>(
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
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                constraints: BoxConstraints(
                  minHeight: tasks.isEmpty ? 120 : 0,
                ),
                child: tasks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
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
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: tasks.map((task) {
                            return Draggable<TaskEntity>(
                              key: ValueKey(task.id),
                              data: task,
                              onDragStarted: () {
                                onDragStart?.call();
                              },
                              onDragEnd: (_) {
                                onDragEnd?.call();
                              },
                              onDragUpdate: (details) {
                                onDragUpdate?.call(details.globalPosition.dy);
                              },
                              feedback: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                child: Opacity(
                                  opacity: 0.9,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width - 64,
                                    child: KanbanTaskCardWidget(
                                      task: task,
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
                          }).toList(),
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

