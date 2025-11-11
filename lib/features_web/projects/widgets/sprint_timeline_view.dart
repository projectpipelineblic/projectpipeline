import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pipeline/core/di/service_locator.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_sprints_usecase.dart' show GetSprints, GetSprintsParams;

/// Sprint-based Timeline View - shows sprints and their tasks
class SprintTimelineView extends StatefulWidget {
  const SprintTimelineView({
    super.key,
    required this.project,
    required this.tasks,
    required this.onTaskTap,
  });

  final ProjectEntity project;
  final List<TaskEntity> tasks;
  final void Function(TaskEntity task) onTaskTap;

  @override
  State<SprintTimelineView> createState() => _SprintTimelineViewState();
}

class _SprintTimelineViewState extends State<SprintTimelineView> {
  List<SprintEntity> _sprints = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await sl<GetSprints>()(GetSprintsParams(projectId: widget.project.id ?? ''));
    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
      (sprints) {
        setState(() {
          _sprints = sprints;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const Gap(16),
            Text(_error!, style: GoogleFonts.inter(color: Colors.red)),
            const Gap(16),
            ElevatedButton(
              onPressed: _loadSprints,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Separate active/planning and completed sprints
    final activeSprints = _sprints
        .where((s) => s.status == SprintStatus.planning || s.status == SprintStatus.active)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final completedSprints = _sprints.where((s) => s.status == SprintStatus.completed).toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));

    // Group tasks by sprint
    final backlogTasks = widget.tasks.where((t) => t.sprintId == null || t.sprintId!.isEmpty).toList();

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Active/Planning Sprints
          if (activeSprints.isNotEmpty) ...[
            _buildSectionHeader('Active Sprints', Icons.play_circle_filled, isDark),
            const Gap(16),
            ...activeSprints.map((sprint) => _buildSprintCard(sprint, isDark)),
            const Gap(32),
          ],

          // Backlog
          _buildSectionHeader(
            'Backlog (${backlogTasks.length} tasks)',
            Icons.inbox,
            isDark,
          ),
          const Gap(16),
          _buildBacklogSection(backlogTasks, isDark),
          const Gap(32),

          // Completed Sprints
          if (completedSprints.isNotEmpty) ...[
            ExpansionTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              title: Text(
                'Completed Sprints (${completedSprints.length})',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              children: [
                ...completedSprints.map((sprint) => _buildSprintCard(sprint, isDark)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF6366F1),
        ),
        const Gap(12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSprintCard(SprintEntity sprint, bool isDark) {
    final sprintTasks = widget.tasks.where((t) => t.sprintId == sprint.id).toList();
    final statusColor = _getStatusColor(sprint.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sprint.status == SprintStatus.active
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: sprint.status == SprintStatus.active ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sprint Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getSprintIcon(sprint.status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            sprint.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusText(sprint.status),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (sprint.goal != null && sprint.goal!.isNotEmpty) ...[
                        const Gap(4),
                        Text(
                          sprint.goal!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatDate(sprint.startDate)} - ${_formatDate(sprint.endDate)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '${sprint.remainingDays} days left',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: sprint.isOverdue ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress Bar
          if (sprint.totalStoryPoints > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${sprint.completedStoryPoints}/${sprint.totalStoryPoints} SP (${sprint.progressPercentage.toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: sprint.progressPercentage / 100,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        sprint.progressPercentage >= 100
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

          // Tasks
          if (sprintTasks.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tasks (${sprintTasks.length})',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  ...sprintTasks.take(5).map((task) => _buildTaskItem(task, isDark)),
                  if (sprintTasks.length > 5) ...[
                    const Gap(8),
                    Text(
                      '+ ${sprintTasks.length - 5} more tasks',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No tasks assigned to this sprint',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBacklogSection(List<TaskEntity> backlogTasks, bool isDark) {
    if (backlogTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: 48,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              ),
              const Gap(12),
              Text(
                'Backlog is empty',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: backlogTasks.map((task) => _buildTaskItem(task, isDark)).toList(),
      ),
    );
  }

  Widget _buildTaskItem(TaskEntity task, bool isDark) {
    return InkWell(
      onTap: () => widget.onTaskTap(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority),
                shape: BoxShape.circle,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.assigneeName != null) ...[
                    const Gap(4),
                    Text(
                      task.assigneeName!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (task.storyPoints != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${task.storyPoints} SP',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
            if (task.dueDate != null) ...[
              const Gap(8),
              Icon(
                Icons.calendar_today,
                size: 14,
                color: _isDueSoon(task.dueDate!)
                    ? const Color(0xFFEF4444)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ],
          ],
        ),
      ),
    );
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
        return const Color(0xFFF59E0B);
      case SprintStatus.active:
        return const Color(0xFF6366F1);
      case SprintStatus.completed:
        return const Color(0xFF10B981);
      case SprintStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getSprintIcon(SprintStatus status) {
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

  bool _isDueSoon(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays <= 3 && difference.inDays >= 0;
  }
}

