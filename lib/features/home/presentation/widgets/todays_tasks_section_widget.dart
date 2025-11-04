import 'package:flutter/material.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/core/extension/themex.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart' as task_entity;
import 'package:task_app/features/home/presentation/widgets/task_card_widget.dart';
import 'package:task_app/features/projects/presentation/pages/task_detail_page.dart';
import 'package:task_app/features/projects/presentation/shared/task_types.dart';

class TodaysTasksSectionWidget extends StatefulWidget {
  final List<task_entity.TaskEntity> tasks;

  const TodaysTasksSectionWidget({
    super.key,
    required this.tasks,
  });

  @override
  State<TodaysTasksSectionWidget> createState() => _TodaysTasksSectionWidgetState();
}

class _TodaysTasksSectionWidgetState extends State<TodaysTasksSectionWidget> {
  int _currentPage = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  TaskPriority _convertPriority(task_entity.TaskPriority priority) {
    switch (priority) {
      case task_entity.TaskPriority.low:
        return TaskPriority.low;
      case task_entity.TaskPriority.medium:
        return TaskPriority.medium;
      case task_entity.TaskPriority.high:
        return TaskPriority.high;
    }
  }

  TaskStatus _convertStatus(task_entity.TaskStatus status) {
    switch (status) {
      case task_entity.TaskStatus.todo:
        return TaskStatus.todo;
      case task_entity.TaskStatus.inProgress:
        return TaskStatus.inProgress;
      case task_entity.TaskStatus.done:
        return TaskStatus.done;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasTasks = widget.tasks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryText(
            text: "Open tasks",
            size: 24,
            fontWeight: FontWeight.bold,
            color: context.colors.secondary,
          ),
        ),
        const SizedBox(height: 16),
        if (hasTasks) ...[
          SizedBox(
            height: 240,
            child: PageView.builder(
              itemCount: widget.tasks.length,
              controller: _pageController,
              padEnds: false,
              itemBuilder: (context, index) {
                final taskEntity = widget.tasks[index];
                return TaskCardWidget(
                  task: taskEntity,
                  onTap: () {
                    // Convert TaskEntity to TaskItem for TaskDetailPage
                    final taskItem = TaskItem(
                      id: taskEntity.id,
                      title: taskEntity.title,
                      description: taskEntity.description,
                      assigneeId: taskEntity.assigneeId,
                      assigneeName: taskEntity.assigneeName,
                      priority: _convertPriority(taskEntity.priority),
                      subTasks: taskEntity.subTasks,
                      dueDate: taskEntity.dueDate,
                      status: _convertStatus(taskEntity.status),
                    );
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailPage(
                          task: taskItem,
                          projectId: taskEntity.projectId,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.tasks.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _DotIndicator(isActive: index == _currentPage),
                ),
              ),
            ),
          ),
        ] else
          _EmptyTaskCard(),
      ],
    );
  }
}

class _EmptyTaskCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
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
                Icons.task_outlined,
                size: 48,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9CA3AF)
                    : AppPallete.textGray,
              ),
              const SizedBox(height: 12),
              PrimaryText(
                text: 'No open tasks',
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

class _DotIndicator extends StatelessWidget {
  final bool isActive;

  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppPallete.primary : AppPallete.borderGray,
      ),
    );
  }
}

