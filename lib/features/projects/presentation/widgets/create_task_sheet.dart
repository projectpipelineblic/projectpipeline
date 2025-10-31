import 'package:flutter/material.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/features/projects/domain/entities/project_entity.dart';
import 'package:task_app/features/projects/domain/entities/task_entity.dart';

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
  TaskPriority _priority = TaskPriority.medium;
  String? _assigneeId;
  String? _assigneeName;
  DateTime? _dueDate;
  final List<TextEditingController> _subTaskCtrls = <TextEditingController>[];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _subTaskCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: PrimaryText(
                  text: 'Create Task',
                  size: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.secondary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
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
      status: TaskStatus.todo,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    widget.onSubmit(entity);
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}


