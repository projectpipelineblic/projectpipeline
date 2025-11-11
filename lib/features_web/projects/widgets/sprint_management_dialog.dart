import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/core/di/service_locator.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/usecases/create_sprint_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_sprints_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/start_sprint_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/complete_sprint_usecase.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';

/// Sprint Management Dialog - Jira-like sprint management
class SprintManagementDialog extends StatefulWidget {
  const SprintManagementDialog({
    super.key,
    required this.project,
  });

  final ProjectEntity project;

  @override
  State<SprintManagementDialog> createState() => _SprintManagementDialogState();
}

class _SprintManagementDialogState extends State<SprintManagementDialog> {
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

  Future<void> _startSprint(SprintEntity sprint) async {
    final result = await sl<StartSprint>()(StartSprintParams(
      projectId: widget.project.id ?? '',
      sprintId: sprint.id,
    ));

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start sprint: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sprint started successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSprints();
        }
      },
    );
  }

  Future<void> _completeSprint(SprintEntity sprint) async {
    final result = await sl<CompleteSprint>()(CompleteSprintParams(
      projectId: widget.project.id ?? '',
      sprintId: sprint.id,
    ));

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete sprint: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sprint completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSprints();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.rocket_launch,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sprint Management',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          widget.project.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateSprintDialog(context, isDark),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Sprint'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Gap(8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const Gap(16),
                              Text(
                                _error!,
                                style: GoogleFonts.inter(fontSize: 14, color: Colors.red),
                              ),
                              const Gap(16),
                              ElevatedButton(
                                onPressed: _loadSprints,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _sprints.isEmpty
                          ? _buildEmptyState(isDark)
                          : _buildSprintsList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch,
                size: 64,
                color: Color(0xFF6366F1),
              ),
            ),
            const Gap(24),
            Text(
              'No Sprints Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const Gap(8),
            Text(
              'Create your first sprint to start organizing tasks',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () => _showCreateSprintDialog(context, isDark),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create First Sprint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprintsList(bool isDark) {
    // Separate active and completed sprints
    final activeSprints = _sprints.where((s) => s.status != SprintStatus.completed).toList();
    final completedSprints = _sprints.where((s) => s.status == SprintStatus.completed).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (activeSprints.isNotEmpty) ...[
          Text(
            'Active Sprints',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Gap(16),
          ...activeSprints.map((sprint) => _buildSprintCard(sprint, isDark)),
          const Gap(24),
        ],
        if (completedSprints.isNotEmpty) ...[
          Text(
            'Completed Sprints',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Gap(16),
          ...completedSprints.map((sprint) => _buildSprintCard(sprint, isDark)),
        ],
      ],
    );
  }

  Widget _buildSprintCard(SprintEntity sprint, bool isDark) {
    final statusColor = _getStatusColor(sprint.status);
    final statusText = _getStatusText(sprint.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sprint.isActive
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: sprint.isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          sprint.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
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
                            statusText,
                            style: GoogleFonts.inter(
                              fontSize: 11,
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
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Manage Sprint button (always shown)
              OutlinedButton.icon(
                onPressed: () => _showManageSprintDialog(context, sprint, isDark),
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Manage'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const Gap(8),
              if (sprint.status == SprintStatus.planning)
                ElevatedButton.icon(
                  onPressed: () => _startSprint(sprint),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else if (sprint.status == SprintStatus.active)
                ElevatedButton.icon(
                  onPressed: () => _completeSprint(sprint),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const Gap(16),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                'Start: ${_formatDate(sprint.startDate)}',
                isDark,
              ),
              _buildInfoChip(
                Icons.event,
                'End: ${_formatDate(sprint.endDate)}',
                isDark,
              ),
              _buildInfoChip(
                Icons.timelapse,
                '${sprint.remainingDays} days left',
                isDark,
              ),
              _buildInfoChip(
                Icons.assessment,
                '${sprint.completedStoryPoints}/${sprint.totalStoryPoints} SP',
                isDark,
              ),
            ],
          ),
          if (sprint.totalStoryPoints > 0) ...[
            const Gap(12),
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
            const Gap(4),
            Text(
              '${sprint.progressPercentage.toStringAsFixed(0)}% Complete',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        const Gap(4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
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

  void _showCreateSprintDialog(BuildContext parentContext, bool isDark) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => _CreateSprintDialog(
        project: widget.project,
        onCreated: () {
          Navigator.of(dialogContext).pop();
          _loadSprints();
        },
      ),
    );
  }

  void _showManageSprintDialog(BuildContext parentContext, SprintEntity sprint, bool isDark) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => _ManageSprintDialog(
        project: widget.project,
        sprint: sprint,
        onUpdated: () {
          Navigator.of(dialogContext).pop();
          _loadSprints();
        },
      ),
    );
  }
}

/// Create Sprint Dialog
class _CreateSprintDialog extends StatefulWidget {
  const _CreateSprintDialog({
    required this.project,
    required this.onCreated,
  });

  final ProjectEntity project;
  final VoidCallback onCreated;

  @override
  State<_CreateSprintDialog> createState() => _CreateSprintDialogState();
}

class _CreateSprintDialogState extends State<_CreateSprintDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _goalCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        'Create New Sprint',
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
                const Gap(24),

                // Sprint Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Sprint Name',
                    hintText: 'e.g., Sprint 1, Phase 1, etc.',
                    prefixIcon: const Icon(Icons.label),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Sprint name is required' : null,
                  autofocus: true,
                ),
                const Gap(16),

                // Goal
                TextFormField(
                  controller: _goalCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Sprint Goal (Optional)',
                    hintText: 'What do you want to achieve in this sprint?',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 32),
                      child: Icon(Icons.flag),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Gap(16),

                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickStartDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _startDate == null
                              ? 'Start Date'
                              : _formatDate(_startDate!),
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickEndDate,
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(
                          _endDate == null
                              ? 'End Date'
                              : _formatDate(_endDate!),
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_startDate != null && _endDate != null) ...[
                  const Gap(8),
                  Text(
                    'Duration: ${_endDate!.difference(_startDate!).inDays + 1} days',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Gap(24),

                // Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          'After creating, you can assign tasks to this sprint from the Task Board or Timeline view.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const Gap(12),
                    ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createSprint,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_isCreating ? 'Creating...' : 'Create Sprint'),
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
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final start = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? start,
      firstDate: start,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _createSprint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    // Get current user ID
    String? userId;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      userId = authState.user.uid;
    } else if (authState is AuthAuthenticated) {
      userId = authState.user.uid;
    } else if (authState is AuthOffline) {
      userId = authState.user.uid;
    }

    if (userId == null) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final params = CreateSprintParams(
      projectId: widget.project.id ?? '',
      name: _nameCtrl.text.trim(),
      goal: _goalCtrl.text.trim().isEmpty ? null : _goalCtrl.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      createdBy: userId,
    );

    final result = await sl<CreateSprint>()(params);

    setState(() => _isCreating = false);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create sprint: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sprint created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onCreated();
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Manage Sprint Dialog - Edit sprint, assign tasks, toggle visibility
class _ManageSprintDialog extends StatefulWidget {
  const _ManageSprintDialog({
    required this.project,
    required this.sprint,
    required this.onUpdated,
  });

  final ProjectEntity project;
  final SprintEntity sprint;
  final VoidCallback onUpdated;

  @override
  State<_ManageSprintDialog> createState() => _ManageSprintDialogState();
}

class _ManageSprintDialogState extends State<_ManageSprintDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _goalCtrl;
  late DateTime _startDate;
  late DateTime _endDate;
  late SprintStatus _status;
  bool _showInTimeline = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.sprint.name);
    _goalCtrl = TextEditingController(text: widget.sprint.goal ?? '');
    _startDate = widget.sprint.startDate;
    _endDate = widget.sprint.endDate;
    _status = widget.sprint.status;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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
                      Icons.settings,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'Manage Sprint',
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
              const Gap(24),

              // Sprint Info
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Sprint Name',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const Gap(16),

              // Goal
              TextField(
                controller: _goalCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Sprint Goal',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: Icon(Icons.flag),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const Gap(16),

              // Sprint Status Dropdown
              DropdownButtonFormField<SprintStatus>(
                decoration: InputDecoration(
                  labelText: 'Sprint Status',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                value: _status,
                items: const [
                  DropdownMenuItem(
                    value: SprintStatus.planning,
                    child: Row(
                      children: [
                        Icon(Icons.edit_calendar, size: 16, color: Color(0xFFF59E0B)),
                        Gap(8),
                        Text('Planning'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: SprintStatus.active,
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_filled, size: 16, color: Color(0xFF6366F1)),
                        Gap(8),
                        Text('Active'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: SprintStatus.completed,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                        Gap(8),
                        Text('Completed'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: SprintStatus.cancelled,
                    child: Row(
                      children: [
                        Icon(Icons.cancel, size: 16, color: Color(0xFFEF4444)),
                        Gap(8),
                        Text('Cancelled'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const Gap(16),

              // Dates (read-only display)
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6366F1)),
                          const Gap(8),
                          Text(
                            _formatDate(_startDate),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Container(
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
                          const Icon(Icons.event, size: 16, color: Color(0xFF6366F1)),
                          const Gap(8),
                          Text(
                            _formatDate(_endDate),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(20),

              // Timeline Visibility Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, size: 20, color: Color(0xFF6366F1)),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show in Timeline',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'Toggle visibility in timeline view',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _showInTimeline,
                      onChanged: (value) => setState(() => _showInTimeline = value),
                      activeColor: const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Gap(12),
                  ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _updateSprint,
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(_isUpdating ? 'Saving...' : 'Save Changes'),
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
      ),
    );
  }

  Future<void> _updateSprint() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sprint name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      // Update sprint in Firestore
      await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.project.id)
          .collection('sprints')
          .doc(widget.sprint.id)
          .update({
        'name': _nameCtrl.text.trim(),
        'goal': _goalCtrl.text.trim().isEmpty ? null : _goalCtrl.text.trim(),
        'status': _getStatusString(_status),
        'showInTimeline': _showInTimeline,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sprint updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sprint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusString(SprintStatus status) {
    switch (status) {
      case SprintStatus.planning:
        return 'planning';
      case SprintStatus.active:
        return 'active';
      case SprintStatus.completed:
        return 'completed';
      case SprintStatus.cancelled:
        return 'cancelled';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

