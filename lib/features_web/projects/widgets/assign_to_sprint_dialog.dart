import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/core/di/service_locator.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_sprints_usecase.dart' show GetSprints, GetSprintsParams;

/// Dialog to assign a task to a sprint
class AssignToSprintDialog extends StatefulWidget {
  const AssignToSprintDialog({
    super.key,
    required this.task,
    required this.projectId,
  });

  final TaskEntity task;
  final String projectId;

  @override
  State<AssignToSprintDialog> createState() => _AssignToSprintDialogState();
}

class _AssignToSprintDialogState extends State<AssignToSprintDialog> {
  List<SprintEntity> _sprints = [];
  String? _selectedSprintId;
  int? _storyPoints;
  double? _estimatedHours;
  bool _isLoading = true;
  bool _isAssigning = false;
  String? _error;

  final TextEditingController _hoursCtrl = TextEditingController();
  final List<int> _fibonacciPoints = [1, 2, 3, 5, 8, 13, 21];

  @override
  void initState() {
    super.initState();
    _loadSprints();
    _selectedSprintId = widget.task.sprintId;
    _storyPoints = widget.task.storyPoints;
    _estimatedHours = widget.task.estimatedHours;
    if (_estimatedHours != null) {
      _hoursCtrl.text = _estimatedHours.toString();
    }
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSprints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await sl<GetSprints>()(GetSprintsParams(projectId: widget.projectId));
    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
      (sprints) {
        // Only show planning and active sprints
        final availableSprints = sprints
            .where((s) => s.status == SprintStatus.planning || s.status == SprintStatus.active)
            .toList();
        setState(() {
          _sprints = availableSprints;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _assignToSprint() async {
    setState(() => _isAssigning = true);

    try {
      // Parse estimated hours
      final hoursText = _hoursCtrl.text.trim();
      if (hoursText.isNotEmpty) {
        _estimatedHours = double.tryParse(hoursText);
      }

      // Update task with sprint information
      await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.projectId)
          .collection('tasks')
          .doc(widget.task.id)
          .update({
        'sprintId': _selectedSprintId,
        'storyPoints': _storyPoints,
        'estimatedHours': _estimatedHours,
        'sprintStatus': _selectedSprintId != null ? 'committed' : 'backlog',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If assigning to a sprint, update sprint's total story points
      if (_selectedSprintId != null && _storyPoints != null) {
        final sprintRef = FirebaseFirestore.instance
            .collection('Projects')
            .doc(widget.projectId)
            .collection('sprints')
            .doc(_selectedSprintId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final sprintDoc = await transaction.get(sprintRef);
          if (sprintDoc.exists) {
            final currentTotal = sprintDoc.data()?['totalStoryPoints'] ?? 0;
            final oldTaskPoints = widget.task.storyPoints ?? 0;
            final newTotal = currentTotal - oldTaskPoints + _storyPoints!;
            transaction.update(sprintRef, {'totalStoryPoints': newTotal});
          }
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedSprintId != null
                  ? '✅ Task assigned to sprint'
                  : '✅ Task moved to backlog',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? SizedBox(
                    height: 200,
                    child: Center(
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
                    ),
                  )
                : SingleChildScrollView(
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
                                Icons.rocket_launch,
                                color: Color(0xFF6366F1),
                                size: 24,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                'Assign to Sprint',
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

                        // Task Info
                        Container(
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
                              const Icon(Icons.task_alt, size: 20, color: Color(0xFF6366F1)),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  widget.task.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(20),

                        // Sprint Selection
                        if (_sprints.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 32,
                                ),
                                const Gap(8),
                                Text(
                                  'No active sprints available',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  'Create a sprint first from Sprint Management',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Select Sprint',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const Gap(8),
                          DropdownButtonFormField<String?>(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.speed),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            value: _selectedSprintId,
                            hint: const Text('Select a sprint or backlog'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Backlog (No Sprint)'),
                              ),
                              ..._sprints.map(
                                (sprint) => DropdownMenuItem<String?>(
                                  value: sprint.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: sprint.status == SprintStatus.active
                                              ? const Color(0xFF6366F1)
                                              : const Color(0xFFF59E0B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const Gap(8),
                                      Expanded(
                                        child: Text(
                                          sprint.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedSprintId = v);
                            },
                          ),
                          const Gap(20),

                          // Story Points & Estimated Hours
                          Text(
                            'Estimation (Optional)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const Gap(8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  decoration: InputDecoration(
                                    labelText: 'Story Points',
                                    prefixIcon: const Icon(Icons.assessment, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  value: _storyPoints,
                                  hint: const Text('None'),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('None'),
                                    ),
                                    ..._fibonacciPoints.map(
                                      (points) => DropdownMenuItem<int?>(
                                        value: points,
                                        child: Text('$points'),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) => setState(() => _storyPoints = v),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: TextFormField(
                                  controller: _hoursCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Est. Hours',
                                    prefixIcon: const Icon(Icons.schedule, size: 20),
                                    suffixText: 'hrs',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          const Gap(16),

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
                                  size: 18,
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    'Story points help track sprint velocity and capacity planning',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Gap(24),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isAssigning ? null : () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const Gap(12),
                            ElevatedButton.icon(
                              onPressed: _isAssigning ? null : _assignToSprint,
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
                              label: Text(_isAssigning ? 'Assigning...' : 'Assign'),
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
}

