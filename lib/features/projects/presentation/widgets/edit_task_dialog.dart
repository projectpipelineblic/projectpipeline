import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/presentation/shared/task_types.dart';

class EditTaskDialog extends StatefulWidget {
  const EditTaskDialog({
    super.key,
    required this.project,
    required this.projectId,
    required this.task,
    required this.onSubmit,
  });

  final ProjectEntity project;
  final String projectId;
  final TaskItem task;
  final void Function({
    required String title,
    required String description,
    required String assigneeId,
    required String assigneeName,
    required TaskPriority priority,
    required DateTime? dueDate,
    String? statusName,
    TaskStatus? status,
    String? sprintId,
  }) onSubmit;

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late TaskPriority _priority;
  late String? _assigneeId;
  late String? _assigneeName;
  late DateTime? _dueDate;
  late String? _selectedStatusName;
  late TaskStatus _selectedStatus;
  late String? _selectedSprintId;
  
  List<Map<String, dynamic>> _sprints = [];
  bool _loadingSprints = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _priority = widget.task.priority;
    _assigneeId = widget.task.assigneeId;
    _assigneeName = widget.task.assigneeName;
    _dueDate = widget.task.dueDate;
    _selectedStatusName = widget.task.statusName;
    _selectedStatus = widget.task.status;
    _selectedSprintId = widget.task.sprintId;
    _loadSprints();
  }
  
  Future<void> _loadSprints() async {
    setState(() => _loadingSprints = true);
    
    try {
      final sprintsSnapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.projectId)
          .collection('sprints')
          .orderBy('startDate', descending: false)
          .get();
      
      final sprints = sprintsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String,
          'status': data['status'] as String,
        };
      }).toList();
      
      if (mounted) {
        setState(() {
          _sprints = sprints;
          _loadingSprints = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSprints = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider = Divider(color: Theme.of(context).dividerColor);
    final members = widget.project.members;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: screenHeight * 0.85,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPallete.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: AppPallete.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryText(
                      text: 'Edit Task',
                      size: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE5E7EB)
                          : AppPallete.secondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF9CA3AF)
                        : AppPallete.textGray,
                  ),
                ],
              ),
            ),
            divider,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Task name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Task description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Assignee',
              border: OutlineInputBorder(),
            ),
            value: _assigneeId,
            items: [
              for (final m in members)
                DropdownMenuItem<String>(
                  value: m.uid,
                  child: Text(m.name.isNotEmpty ? m.name : m.email),
                  onTap: () {
                    _assigneeName = m.name.isNotEmpty ? m.name : m.email;
                  },
                ),
            ],
            onChanged: (v) {
              setState(() {
                _assigneeId = v;
              });
            },
            validator: (v) => (v == null || v.isEmpty) ? 'Select assignee' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskPriority>(
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            value: _priority,
            items: const [
              DropdownMenuItem(value: TaskPriority.low, child: Text('Low')),
              DropdownMenuItem(value: TaskPriority.medium, child: Text('Medium')),
              DropdownMenuItem(value: TaskPriority.high, child: Text('High')),
            ],
            onChanged: (v) => setState(() => _priority = v ?? TaskPriority.medium),
          ),
          const SizedBox(height: 12),
          // Custom Status Dropdown
          if (widget.project.customStatuses != null && widget.project.customStatuses!.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              value: _selectedStatusName,
              items: widget.project.customStatuses!.map((status) {
                final hexColor = status.colorHex.replaceAll('#', '');
                final color = Color(int.parse('FF$hexColor', radix: 16));
                return DropdownMenuItem<String>(
                  value: status.name,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          status.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedStatusName = v;
                    // Update status enum based on position
                    final statusIndex = widget.project.customStatuses!.indexWhere((s) => s.name == v);
                    if (statusIndex == 0) {
                      _selectedStatus = TaskStatus.todo;
                    } else if (statusIndex == widget.project.customStatuses!.length - 1) {
                      _selectedStatus = TaskStatus.done;
                    } else {
                      _selectedStatus = TaskStatus.inProgress;
                    }
                  });
                }
              },
            ),
          const SizedBox(height: 12),
          // Sprint Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Sprint',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.rocket_launch),
              suffixIcon: _selectedSprintId != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedSprintId = null;
                        });
                      },
                      tooltip: 'Remove from sprint',
                    )
                  : null,
            ),
            value: _selectedSprintId,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Not assigned'),
              ),
              ..._sprints.map((sprint) {
                final statusColor = _getSprintStatusColor(sprint['status'] as String);
                return DropdownMenuItem<String>(
                  value: sprint['id'] as String,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          sprint['name'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          _getSprintStatusLabel(sprint['status'] as String).toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            onChanged: _loadingSprints ? null : (v) {
              setState(() {
                _selectedSprintId = v;
              });
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDueDate,
            icon: const Icon(Icons.event),
            label: PrimaryText(
              text: _dueDate == null
                  ? 'Due date: Pick due date'
                  : 'Due date: ${_formatShortDate(_dueDate!)}',
              size: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFE5E7EB)
                  : AppPallete.secondary,
            ),
          ),
          if (_dueDate != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() => _dueDate = null);
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear due date'),
            ),
          ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
            // Submit button at bottom (outside scroll)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _submit,
                    child: const PrimaryText(
                      text: 'Save Changes',
                      color: AppPallete.white,
                      fontWeight: FontWeight.w600,
                      size: 15,
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

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      title: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      assigneeId: _assigneeId!,
      assigneeName: _assigneeName ?? 'User',
      priority: _priority,
      dueDate: _dueDate,
      statusName: _selectedStatusName,
      status: _selectedStatus,
      sprintId: _selectedSprintId,
    );
    Navigator.of(context).pop();
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
  
  Color _getSprintStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFFEC4899);
      case 'planning':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF8B5CF6);
    }
  }
  
  String _getSprintStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'planning':
        return 'Planning';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Sprint';
    }
  }
}

