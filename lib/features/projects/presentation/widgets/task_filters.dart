import 'package:flutter/material.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:task_app/core/widgets/primart_text.dart';

enum TaskStatusFilter { all, todo, inProgress, done }

class TaskFilters extends StatelessWidget {
  const TaskFilters({super.key, required this.selected, required this.onChanged});

  final TaskStatusFilter selected;
  final ValueChanged<TaskStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.all),
            child: _FilterChip(
              label: 'All',
              selected: selected == TaskStatusFilter.all,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.todo),
            child: const _FilterChip(
              label: 'To Do',
              selected: false,
              color: AppPallete.orange,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.inProgress),
            child: const _FilterChip(
              label: 'In Progress',
              selected: false,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.done),
            child: const _FilterChip(
              label: 'Done',
              selected: false,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.color});

  final String label;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? color.withOpacity(0.5) : Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: PrimaryText(
        text: label,
        size: 12,
        fontWeight: FontWeight.w600,
        color: selected ? color : AppPallete.secondary,
      ),
    );
  }
}


