enum TaskPriority { low, medium, high }
enum TaskStatus { todo, inProgress, done }

class TaskItem {
  TaskItem({
    this.id = '',
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.priority,
    required this.subTasks,
    required this.dueDate,
    this.status = TaskStatus.todo,
    this.statusName,
  });

  final String id;
  final String title;
  final String description;
  final String assigneeId;
  final String assigneeName;
  final TaskPriority priority;
  final List<String> subTasks;
  final DateTime? dueDate;
  final TaskStatus status;
  final String? statusName; // Custom status name (e.g., "Review", "Pre-review")

  String get dueDateLabel {
    if (dueDate == null) return '';
    final d = dueDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

