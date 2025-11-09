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
    this.timeSpentMinutes = 0,
    this.startedAt,
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
  final int timeSpentMinutes; // Total time spent on task in minutes
  final DateTime? startedAt; // When the task was moved to in-progress

  String get dueDateLabel {
    if (dueDate == null) return '';
    final d = dueDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
  
  String get timeSpentLabel {
    if (timeSpentMinutes < 60) {
      return '${timeSpentMinutes}m';
    } else if (timeSpentMinutes < 1440) {
      final hours = (timeSpentMinutes / 60).floor();
      final minutes = timeSpentMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      final days = (timeSpentMinutes / 1440).floor();
      final hours = ((timeSpentMinutes % 1440) / 60).floor();
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
  }
}

