import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/data/models/sprint_model.dart';

/// Web-specific task creation dialog with sprint assignment
class WebCreateTaskDialog extends StatefulWidget {
  const WebCreateTaskDialog({
    super.key,
    required this.project,
    required this.onSubmit,
    this.initialStatus,
  });

  final ProjectEntity project;
  final ValueChanged<TaskEntity> onSubmit;
  final String? initialStatus;

  @override
  State<WebCreateTaskDialog> createState() => _WebCreateTaskDialogState();
}

class _WebCreateTaskDialogState extends State<WebCreateTaskDialog> {
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
      print('❌ Cannot load sprints: project ID is null or empty');
      return;
    }
    
    setState(() => _loadingSprints = true);
    
    try {
      print('🔍 Loading sprints for project: ${widget.project.id}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.project.id)
          .collection('sprints')
          .orderBy('createdAt', descending: true)
          .get();
      
      print('📦 Found ${snapshot.docs.length} total sprints');
      
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
                  print('📋 Sprint: ${data['name']} - Status: ${data['status']}');
                  
                  return SprintModel.fromJson({
                    ...data,
                    'id': doc.id,
                    'projectId': widget.project.id!,
                  });
                } catch (e) {
                  print('⚠️ Error parsing sprint ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<SprintEntity>()
              .toList();
          
          _loadingSprints = false;
          print('✅ Loaded ${_sprints.length} active/planning sprints');
        });
      }
    } catch (e) {
      print('❌ Error loading sprints: $e');
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
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                        Icons.add_task,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create New Task',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
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
                const SizedBox(height: 24),

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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Task name is required' : null,
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

                // Assignee & Priority Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
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
                        validator: (v) => (v == null || v.isEmpty) ? 'Select assignee' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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
                      prefixIcon: const Icon(Icons.rocket_launch, color: Color(0xFF6366F1)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: _sprintId,
                    hint: Text(
                      _loadingSprints ? 'Loading sprints...' : 'Select a sprint (Optional)',
                      style: GoogleFonts.inter(fontSize: 14),
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
                            mainAxisSize: MainAxisSize.min,
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
                              Flexible(
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

                // Due Date - Highly Visible
                Text(
                  'Due Date',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _dueDate == null
                          ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                          : const Color(0xFF6366F1),
                      width: _dueDate == null ? 1 : 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _dueDate == null
                        ? Colors.transparent
                        : const Color(0xFF6366F1).withOpacity(0.05),
                  ),
                  child: InkWell(
                    onTap: _pickDueDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 22,
                            color: _dueDate == null
                                ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                : const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dueDate == null
                                  ? 'Pick due date'
                                  : _formatShortDate(_dueDate!),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: _dueDate == null ? FontWeight.normal : FontWeight.w600,
                                color: _dueDate == null
                                    ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
                              ),
                            ),
                          ),
                          if (_dueDate != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setState(() => _dueDate = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: const Color(0xFF6366F1),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sub Tasks
                Text(
                  'Sub Tasks',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
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
                              hintText: 'Sub task ${i + 1}',
                              prefixIcon: const Icon(Icons.subdirectory_arrow_right, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                          color: Colors.red,
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
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Sub Task'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Create Task'),
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

    // If project has custom statuses, use the provided initialStatus or first one as default
    String? defaultStatusName;
    if (widget.project.customStatuses != null && widget.project.customStatuses!.isNotEmpty) {
      defaultStatusName = widget.initialStatus ?? widget.project.customStatuses!.first.name;
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
      status: TaskStatus.todo,
      statusName: defaultStatusName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // Sprint assignment
      sprintId: _sprintId,
      storyPoints: null,
      estimatedHours: null,
      sprintStatus: _sprintId == null ? 'backlog' : 'assigned',
    );
    widget.onSubmit(entity);
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

