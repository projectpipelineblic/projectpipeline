import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/core/services/local_storage_service.dart';
import 'package:project_pipeline/core/di/service_locator.dart';

/// Sprint Details Dialog - Shows sprint info and allows task assignment
class SprintDetailsDialog extends StatefulWidget {
  const SprintDetailsDialog({
    super.key,
    required this.project,
    required this.sprint,
    required this.onUpdated,
  });

  final ProjectEntity project;
  final SprintEntity sprint;
  final VoidCallback onUpdated;

  @override
  State<SprintDetailsDialog> createState() => _SprintDetailsDialogState();
}

class _SprintDetailsDialogState extends State<SprintDetailsDialog> {
  List<TaskEntity> _sprintTasks = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      // Load all tasks for the project
      final snapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.project.id)
          .collection('tasks')
          .get();

      final allTasks = snapshot.docs
          .map((doc) => TaskEntity(
                id: doc.id,
                projectId: widget.project.id ?? '',
                title: doc.data()['title'] ?? '',
                description: doc.data()['description'] ?? '',
                assigneeId: doc.data()['assigneeId'] ?? '',
                assigneeName: doc.data()['assigneeName'] ?? '',
                priority: _parsePriority(doc.data()['priority']),
                subTasks: List<String>.from(doc.data()['subTasks'] ?? []),
                dueDate: doc.data()['dueDate'] != null
                    ? (doc.data()['dueDate'] as Timestamp).toDate()
                    : null,
                status: _parseStatus(doc.data()['status']),
                statusName: doc.data()['statusName'],
                createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                updatedAt: (doc.data()['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                sprintId: doc.data()['sprintId'],
                storyPoints: doc.data()['storyPoints'],
                estimatedHours: doc.data()['estimatedHours']?.toDouble(),
                sprintStatus: doc.data()['sprintStatus'] ?? 'backlog',
              ))
          .toList();

      setState(() {
        _sprintTasks = allTasks.where((t) => t.sprintId == widget.sprint.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  TaskPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  TaskStatus _parseStatus(String? status) {
    switch (status) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(widget.sprint.status);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, minHeight: 400, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getSprintStatusIcon(widget.sprint.status),
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.sprint.name,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const Gap(4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusText(widget.sprint.status),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  '${_formatDate(widget.sprint.startDate)} - ${_formatDate(widget.sprint.endDate)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                  if (widget.sprint.goal != null && widget.sprint.goal!.isNotEmpty) ...[
                    const Gap(12),
                    Text(
                      widget.sprint.goal!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    icon: Icons.assessment,
                    label: 'Story Points',
                    value: '${widget.sprint.completedStoryPoints}/${widget.sprint.totalStoryPoints}',
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                  _buildStat(
                    icon: Icons.task_alt,
                    label: 'Tasks',
                    value: '${_sprintTasks.length}',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  _buildStat(
                    icon: Icons.timelapse,
                    label: 'Days Left',
                    value: '${widget.sprint.remainingDays}',
                    color: widget.sprint.isOverdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Tasks Section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Search and Add Task
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search tasks...',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    setState(() => _searchQuery = value.toLowerCase());
                                  },
                                ),
                              ),
                              const Gap(12),
                              ElevatedButton.icon(
                                onPressed: () => _showTaskPicker(context, isDark),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Task'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tasks List with Header
                        Expanded(
                          child: _sprintTasks.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                      ),
                                      const Gap(16),
                                      Text(
                                        'No tasks assigned',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const Gap(8),
                                      Text(
                                        'Click "Add Task" to assign tasks to this sprint',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Tasks count header
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Text(
                                        '${_getFilteredTasks().length} Task(s) in Sprint',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    // Task list
                                    Expanded(
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        itemCount: _getFilteredTasks().length,
                                        itemBuilder: (context, index) {
                                          final task = _getFilteredTasks()[index];
                                          return _buildTaskItem(task, isDark);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<TaskEntity> _getFilteredTasks() {
    if (_searchQuery.isEmpty) return _sprintTasks;
    return _sprintTasks
        .where((task) =>
            task.title.toLowerCase().contains(_searchQuery) ||
            task.description.toLowerCase().contains(_searchQuery) ||
            (task.assigneeName?.toLowerCase().contains(_searchQuery) ?? false))
        .toList();
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const Gap(6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(TaskEntity task, bool isDark) {
    final isOnTrack = _isTaskOnTrack(task);
    final statusColor = _getStatusDisplayColor(task.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title Row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority),
                  shape: BoxShape.circle,
                ),
              ),
              const Gap(10),
              Expanded(
                child: Text(
                  task.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => _removeTaskFromSprint(task),
                color: Colors.red,
                tooltip: 'Remove from sprint',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          // Task Description (if exists)
          if (task.description.isNotEmpty) ...[
            const Gap(6),
            Text(
              task.description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          const Gap(12),
          
          // Task Details Grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              // Assignee
              if (task.assigneeName != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 14, color: Color(0xFF6366F1)),
                    const Gap(4),
                    Text(
                      task.assigneeName!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(task.status), size: 12, color: statusColor),
                    const Gap(4),
                    Text(
                      _getStatusDisplayText(task.status),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Story Points
              if (task.storyPoints != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assessment, size: 12, color: Color(0xFF6366F1)),
                      const Gap(4),
                      Text(
                        '${task.storyPoints} SP',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Due Date
              if (task.dueDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isDueSoon(task.dueDate!) 
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: _isDueSoon(task.dueDate!) 
                            ? const Color(0xFFEF4444)
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                      const Gap(4),
                      Text(
                        _formatDueDate(task.dueDate!),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: _isDueSoon(task.dueDate!) ? FontWeight.w600 : FontWeight.w500,
                          color: _isDueSoon(task.dueDate!) 
                              ? const Color(0xFFEF4444)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // On Track Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOnTrack 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isOnTrack 
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnTrack ? Icons.check_circle : Icons.warning,
                      size: 12,
                      color: isOnTrack ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    const Gap(4),
                    Text(
                      isOnTrack ? 'On Track' : 'At Risk',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOnTrack ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Priority Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getPriorityText(task.priority),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(task.priority),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isTaskOnTrack(TaskEntity task) {
    // Task is on track if:
    // 1. Done tasks are always on track
    if (task.status == TaskStatus.done) return true;
    
    // 2. No due date = assume on track
    if (task.dueDate == null) return true;
    
    // 3. Due date is in the future and status is not todo (making progress)
    final now = DateTime.now();
    if (task.dueDate!.isAfter(now) && task.status != TaskStatus.todo) return true;
    
    // 4. Due date is more than 2 days away
    final daysUntilDue = task.dueDate!.difference(now).inDays;
    if (daysUntilDue > 2) return true;
    
    // Otherwise, at risk
    return false;
  }

  bool _isDueSoon(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays <= 3 && difference.inDays >= 0;
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < 0) return 'Overdue';
    
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color _getStatusDisplayColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return const Color(0xFF94A3B8);
      case TaskStatus.inProgress:
        return const Color(0xFF6366F1);
      case TaskStatus.done:
        return const Color(0xFF10B981);
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.timelapse;
      case TaskStatus.done:
        return Icons.check_circle;
    }
  }

  String _getStatusDisplayText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  void _showTaskPicker(BuildContext parentContext, bool isDark) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => _TaskPickerDialog(
        project: widget.project,
        sprint: widget.sprint,
        assignedTaskIds: _sprintTasks.map((t) => t.id).toSet(),
        onTasksAssigned: () {
          Navigator.of(dialogContext).pop();
          _loadTasks();
          widget.onUpdated();
        },
      ),
    );
  }

  Future<void> _removeTaskFromSprint(TaskEntity task) async {
    // Check if current user is admin
    final currentUser = await sl<LocalStorageService>().getCachedUser();
    if (currentUser == null || currentUser.uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Unable to verify user'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if user is admin in this project
    final isAdmin = widget.project.members.any(
      (member) => member.uid == currentUser.uid && member.role == 'admin',
    );

    if (!isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Only admins can remove tasks from sprints'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const Gap(12),
            Text(
              'Remove Task?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove this task from the sprint?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
              ),
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF334155) 
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark 
                      ? const Color(0xFF475569) 
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange,
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          task.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const Gap(6),
                    Text(
                      task.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'The task will be moved back to the backlog.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            label: Text(
              'Remove',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    // If user cancelled, return
    if (confirmed != true) return;

    // Proceed with removal
    try {
      await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.project.id)
          .collection('tasks')
          .doc(task.id)
          .update({
        'sprintId': null,
        'sprintStatus': 'backlog',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update sprint's total story points
      if (task.storyPoints != null) {
        await FirebaseFirestore.instance
            .collection('Projects')
            .doc(widget.project.id)
            .collection('sprints')
            .doc(widget.sprint.id)
            .update({
          'totalStoryPoints': FieldValue.increment(-task.storyPoints!),
        });
      }

      // Wait for next frame before updating UI to avoid disposed widget errors
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          _loadTasks();
          widget.onUpdated();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Task removed from sprint'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFEF4444);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  Color _getStatusColor(SprintStatus status) {
    switch (status) {
      case SprintStatus.planning:
        return const Color(0xFF3B82F6);
      case SprintStatus.active:
        return const Color(0xFFEC4899);
      case SprintStatus.completed:
        return const Color(0xFF10B981);
      case SprintStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getSprintStatusIcon(SprintStatus status) {
    switch (status) {
      case SprintStatus.planning:
        return Icons.edit_calendar;
      case SprintStatus.active:
        return Icons.play_circle_filled;
      case SprintStatus.completed:
        return Icons.check_circle;
      case SprintStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(SprintStatus status) {
    switch (status) {
      case SprintStatus.planning:
        return 'PLANNING';
      case SprintStatus.active:
        return 'ACTIVE';
      case SprintStatus.completed:
        return 'COMPLETED';
      case SprintStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Task Picker Dialog with Search
class _TaskPickerDialog extends StatefulWidget {
  const _TaskPickerDialog({
    required this.project,
    required this.sprint,
    required this.assignedTaskIds,
    required this.onTasksAssigned,
  });

  final ProjectEntity project;
  final SprintEntity sprint;
  final Set<String> assignedTaskIds;
  final VoidCallback onTasksAssigned;

  @override
  State<_TaskPickerDialog> createState() => _TaskPickerDialogState();
}

class _TaskPickerDialogState extends State<_TaskPickerDialog> {
  List<TaskEntity> _availableTasks = [];
  Set<String> _selectedTaskIds = {};
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableTasks();
  }

  Future<void> _loadAvailableTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load all tasks from the project
      final snapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.project.id)
          .collection('tasks')
          .get();

      final tasks = snapshot.docs
          .map((doc) => TaskEntity(
                id: doc.id,
                projectId: widget.project.id ?? '',
                title: doc.data()['title'] ?? '',
                description: doc.data()['description'] ?? '',
                assigneeId: doc.data()['assigneeId'] ?? '',
                assigneeName: doc.data()['assigneeName'] ?? '',
                priority: _parsePriority(doc.data()['priority']),
                subTasks: List<String>.from(doc.data()['subTasks'] ?? []),
                dueDate: doc.data()['dueDate'] != null
                    ? (doc.data()['dueDate'] as Timestamp).toDate()
                    : null,
                status: _parseStatus(doc.data()['status']),
                statusName: doc.data()['statusName'],
                createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                updatedAt: (doc.data()['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                storyPoints: doc.data()['storyPoints'],
                sprintId: doc.data()['sprintId'],
              ))
          .where((t) => 
              !widget.assignedTaskIds.contains(t.id) && // Not already in this sprint
              (t.sprintId == null || t.sprintId!.isEmpty) // Not assigned to any sprint
          )
          .toList();

      if (mounted) {
        setState(() {
          _availableTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  TaskPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  TaskStatus _parseStatus(String? status) {
    switch (status) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredTasks = _getFilteredTasks();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, minHeight: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.task_alt,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Add Tasks to Sprint',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ],
            ),
            const Gap(16),

            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks by name, assignee, or description...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              autofocus: true,
            ),
            const Gap(16),

            // Selected count
            if (_selectedTaskIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_selectedTaskIds.length} task(s) selected',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
            const Gap(12),

            // Tasks List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
                                size: 64,
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              ),
                              const Gap(16),
                              Text(
                                _searchQuery.isNotEmpty ? 'No tasks found' : 'No available tasks',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final isSelected = _selectedTaskIds.contains(task.id);

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedTaskIds.add(task.id);
                                  } else {
                                    _selectedTaskIds.remove(task.id);
                                  }
                                });
                              },
                              title: Text(
                                task.title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: task.assigneeName != null
                                  ? Text(
                                      task.assigneeName!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    )
                                  : null,
                              secondary: task.storyPoints != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${task.storyPoints}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6366F1),
                                        ),
                                      ),
                                    )
                                  : null,
                              activeColor: const Color(0xFF6366F1),
                            );
                          },
                        ),
            ),

            // Actions
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isAssigning ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Gap(12),
                ElevatedButton.icon(
                  onPressed: _isAssigning || _selectedTaskIds.isEmpty ? null : _assignTasks,
                  icon: _isAssigning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(_isAssigning ? 'Assigning...' : 'Assign ${_selectedTaskIds.length} Task(s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TaskEntity> _getFilteredTasks() {
    if (_searchQuery.isEmpty) return _availableTasks;
    return _availableTasks
        .where((task) =>
            task.title.toLowerCase().contains(_searchQuery) ||
            task.description.toLowerCase().contains(_searchQuery) ||
            (task.assigneeName?.toLowerCase().contains(_searchQuery) ?? false))
        .toList();
  }

  Future<void> _assignTasks() async {
    if (!mounted) return;
    setState(() => _isAssigning = true);

    try {
      int totalStoryPoints = 0;

      for (final taskId in _selectedTaskIds) {
        final task = _availableTasks.firstWhere((t) => t.id == taskId);

        await FirebaseFirestore.instance
            .collection('Projects')
            .doc(widget.project.id)
            .collection('tasks')
            .doc(taskId)
            .update({
          'sprintId': widget.sprint.id,
          'sprintStatus': 'committed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (task.storyPoints != null) {
          totalStoryPoints += task.storyPoints!;
        }
      }

      // Update sprint's total story points
      if (totalStoryPoints > 0) {
        await FirebaseFirestore.instance
            .collection('Projects')
            .doc(widget.project.id)
            .collection('sprints')
            .doc(widget.sprint.id)
            .update({
          'totalStoryPoints': FieldValue.increment(totalStoryPoints),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_selectedTaskIds.length} task(s) assigned to sprint'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onTasksAssigned();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

