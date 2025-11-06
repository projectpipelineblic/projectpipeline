import 'package:flutter/material.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/presentation/shared/task_types.dart';

class EditTaskSheet extends StatefulWidget {
  const EditTaskSheet({
    super.key,
    required this.project,
    required this.task,
    required this.onSubmit,
  });

  final ProjectEntity project;
  final TaskItem task;
  final void Function({
    required String title,
    required String description,
    required String assigneeId,
    required String assigneeName,
    required TaskPriority priority,
    required DateTime? dueDate,
  }) onSubmit;

  @override
  State<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<EditTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late TaskPriority _priority;
  late String? _assigneeId;
  late String? _assigneeName;
  late DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _priority = widget.task.priority;
    _assigneeId = widget.task.assigneeId;
    _assigneeName = widget.task.assigneeName;
    _dueDate = widget.task.dueDate;
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

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PrimaryText(
                  text: 'Edit Task',
                  size: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE5E7EB)
                      : AppPallete.secondary,
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
            items: [
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primary),
              onPressed: _submit,
              child: const PrimaryText(
                text: 'Save Changes',
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
    );
    Navigator.of(context).pop();
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

