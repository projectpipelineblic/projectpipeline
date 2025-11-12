import 'package:flutter/material.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({super.key, required this.project, required this.onSubmit});

  final ProjectEntity project;
  final ValueChanged<TaskEntity> onSubmit;

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _estimatedHoursCtrl = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  String? _assigneeId;
  String? _assigneeName;
  DateTime? _dueDate;
  final List<TextEditingController> _subTaskCtrls = <TextEditingController>[];
  
  // Sprint/Scrum fields
  String? _sprintId;
  int? _storyPoints;
  final List<int> _fibonacciPoints = [1, 2, 3, 5, 8, 13, 21];
  
  // Custom status field
  String? _selectedStatusName;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _estimatedHoursCtrl.dispose();
    for (final c in _subTaskCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = Divider(color: Theme.of(context).dividerColor);
    final members = widget.project.members;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Create New Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          divider,
          const SizedBox(height: 12),
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
          // Sprint/Scrum Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      size: 18,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sprint / Scrum (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Story Points',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: _storyPoints,
                        hint: const Text('None'),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('None')),
                          ..._fibonacciPoints.map(
                            (points) => DropdownMenuItem<int>(
                              value: points,
                              child: Text('$points'),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _storyPoints = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _estimatedHoursCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Est. Hours',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          suffixText: 'hrs',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Story points help estimate task complexity. Sprints can be managed from the Task Board.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
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
              color: AppPallete.secondary,
            ),
          ),
          const SizedBox(height: 12),
          const PrimaryText(
            text: 'Sub tasks',
            size: 14,
            fontWeight: FontWeight.w700,
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
                        border: const OutlineInputBorder(),
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
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _subTaskCtrls.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add sub task'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primary),
              onPressed: _submit,
              child: const PrimaryText(
                text: 'Create Task',
                color: AppPallete.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
    final subTasks = _subTaskCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    
    // Determine status name - use selected, or default to first custom status
    String? statusName = _selectedStatusName;
    if (statusName == null && widget.project.customStatuses != null && widget.project.customStatuses!.isNotEmpty) {
      statusName = widget.project.customStatuses!.first.name;
    }
    
    // Determine status enum based on selected status position
    TaskStatus status = TaskStatus.todo;
    if (statusName != null && widget.project.customStatuses != null && widget.project.customStatuses!.isNotEmpty) {
      final statusIndex = widget.project.customStatuses!.indexWhere((s) => s.name == statusName);
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
    
    // Parse estimated hours
    double? estimatedHours;
    final hoursText = _estimatedHoursCtrl.text.trim();
    if (hoursText.isNotEmpty) {
      estimatedHours = double.tryParse(hoursText);
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
      // Sprint/Scrum fields
      sprintId: _sprintId,
      storyPoints: _storyPoints,
      estimatedHours: estimatedHours,
      sprintStatus: 'backlog',
    );
    widget.onSubmit(entity);
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}


