import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/data/models/sprint_model.dart';

/// Mobile-specific task creation dialog with column-based form layout
class MobileCreateTaskDialog extends StatefulWidget {
  const MobileCreateTaskDialog({
    super.key,
    required this.project,
    required this.onSubmit,
    this.initialStatus,
  });

  final ProjectEntity project;
  final ValueChanged<TaskEntity> onSubmit;
  final String? initialStatus;

  @override
  State<MobileCreateTaskDialog> createState() => _MobileCreateTaskDialogState();
}

class _MobileCreateTaskDialogState extends State<MobileCreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  String? _assigneeId;
  String? _assigneeName;
  DateTime? _dueDate;
  final List<TextEditingController> _subTaskCtrls = <TextEditingController>[];
  
  // Sprint assignment
  String? _sprintId;
  List<SprintEntity> _sprints = [];
  bool _loadingSprints = false;
  
  // Custom status field
  String? _selectedStatusName;

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _subTaskCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSprints() async {
    if (widget.project.id == null || widget.project.id!.isEmpty) {
      return;
    }
    
    setState(() => _loadingSprints = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.project.id)
          .collection('sprints')
          .orderBy('createdAt', descending: true)
          .get();
      
      if (mounted) {
        setState(() {
          _sprints = snapshot.docs
              .where((doc) {
                final status = doc.data()['status'] as String?;
                return status == 'planning' || status == 'active';
              })
              .map((doc) {
                try {
                  final data = doc.data();
                  return SprintModel.fromJson({
                    ...data,
                    'id': doc.id,
                    'projectId': widget.project.id!,
                  });
                } catch (e) {
                  return null;
                }
              })
              .whereType<SprintEntity>()
              .toList();
          
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = widget.project.members;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : AppPallete.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPallete.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_task,
                      color: AppPallete.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryText(
                      text: 'Create New Task',
                      size: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFE5E7EB) : AppPallete.secondary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Task Name',
                          hintText: 'Enter task name',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) 
                            ? 'Task name is required' 
                            : null,
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter task description',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 48),
                            child: Icon(Icons.description),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assignee
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Assignee',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _assigneeId,
                        items: [
                          for (final m in members)
                            DropdownMenuItem<String>(
                              value: m.uid,
                              child: Text(
                                m.name.isNotEmpty ? m.name : m.email,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                        validator: (v) => (v == null || v.isEmpty) 
                            ? 'Select assignee' 
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Priority
                      DropdownButtonFormField<TaskPriority>(
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _priority,
                        items: const [
                          DropdownMenuItem(
                            value: TaskPriority.low,
                            child: Text('Low'),
                          ),
                          DropdownMenuItem(
                            value: TaskPriority.medium,
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(
                            value: TaskPriority.high,
                            child: Text('High'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _priority = v ?? TaskPriority.medium),
                      ),
                      const SizedBox(height: 16),

                      // Custom Status Dropdown
                      if (widget.project.customStatuses != null && 
                          widget.project.customStatuses!.isNotEmpty)
                        Column(
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Status',
                                prefixIcon: const Icon(Icons.label_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: _selectedStatusName,
                              hint: Text(widget.project.customStatuses!.first.name),
                              items: widget.project.customStatuses!.map((status) {
                                final hexColor = status.colorHex.replaceAll('#', '');
                                final color = Color(int.parse('FF$hexColor', radix: 16));
                                return DropdownMenuItem<String>(
                                  value: status.name,
                                  child: Row(
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
                                      Expanded(
                                        child: Text(
                                          status.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedStatusName = v),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Sprint Assignment
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Sprint / Scrum (Optional)',
                            prefixIcon: const Icon(
                              Icons.rocket_launch, 
                              color: Color(0xFF6366F1),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, 
                              vertical: 12,
                            ),
                          ),
                          value: _sprintId,
                          hint: Text(
                            _loadingSprints 
                                ? 'Loading sprints...' 
                                : 'Select a sprint (Optional)',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('No Sprint (Backlog)'),
                            ),
                            for (final sprint in _sprints)
                              DropdownMenuItem<String>(
                                value: sprint.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: sprint.status == SprintStatus.active
                                            ? Colors.pink
                                            : Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sprint.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _sprintId = v;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Due Date
                      InkWell(
                        onTap: _pickDueDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, 
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark 
                                  ? const Color(0xFF404040) 
                                  : AppPallete.borderGray,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: _dueDate == null
                                    ? (isDark 
                                        ? const Color(0xFF9CA3AF) 
                                        : AppPallete.textGray)
                                    : AppPallete.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _dueDate == null
                                      ? 'Pick due date'
                                      : _formatShortDate(_dueDate!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _dueDate == null
                                        ? (isDark 
                                            ? const Color(0xFF9CA3AF) 
                                            : AppPallete.textGray)
                                        : (isDark 
                                            ? Colors.white 
                                            : AppPallete.secondary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sub Tasks Section
                      const PrimaryText(
                        text: 'Sub Tasks',
                        size: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPallete.secondary,
                      ),
                      const SizedBox(height: 8),
                      
                      for (int i = 0; i < _subTaskCtrls.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _subTaskCtrls[i],
                                  decoration: InputDecoration(
                                    labelText: 'Sub task ${i + 1}',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _subTaskCtrls.removeAt(i).dispose();
                                  });
                                },
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                      
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _subTaskCtrls.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Sub Task'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPallete.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPallete.primary,
                                foregroundColor: AppPallete.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, size: 18),
                                  SizedBox(width: 8),
                                  Text('Create Task'),
                                ],
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
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    final subTasks = _subTaskCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    
    // Determine status name - use selected, or default to first custom status
    String? statusName = _selectedStatusName;
    if (statusName == null && 
        widget.project.customStatuses != null && 
        widget.project.customStatuses!.isNotEmpty) {
      statusName = widget.initialStatus ?? widget.project.customStatuses!.first.name;
    }
    
    // Determine status enum based on selected status position
    TaskStatus status = TaskStatus.todo;
    if (statusName != null && 
        widget.project.customStatuses != null && 
        widget.project.customStatuses!.isNotEmpty) {
      final statusIndex = widget.project.customStatuses!
          .indexWhere((s) => s.name == statusName);
      if (statusIndex != -1) {
        if (statusIndex == 0) {
          status = TaskStatus.todo;
        } else if (statusIndex == widget.project.customStatuses!.length - 1) {
          status = TaskStatus.done;
        } else {
          status = TaskStatus.inProgress;
        }
      }
    }
    
    final entity = TaskEntity(
      id: '',
      projectId: widget.project.id ?? '',
      title: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      assigneeId: _assigneeId!,
      assigneeName: _assigneeName ?? 'User',
      priority: _priority,
      subTasks: subTasks,
      dueDate: _dueDate,
      status: status,
      statusName: statusName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // Sprint assignment
      sprintId: _sprintId,
      storyPoints: null,
      estimatedHours: null,
      sprintStatus: _sprintId == null ? 'backlog' : 'assigned',
    );
    
    widget.onSubmit(entity);
    Navigator.of(context).pop();
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

