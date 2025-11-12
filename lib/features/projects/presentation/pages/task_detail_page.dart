import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/shared/task_types.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/presentation/widgets/edit_task_dialog.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.task,
    required this.projectId,
    this.project,
  });

  final TaskItem task;
  final String projectId;
  final ProjectEntity? project;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TaskItem _task;
  bool _isLoading = false;
  String? _currentUserUid;
  String _currentUserName = '';
  List<_SubTaskItem> _subTasks = <_SubTaskItem>[];
  bool _isAdmin = false;
  String? _sprintName;
  String? _sprintStatus;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _subscribeToTask();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserUid = authState.user.uid;
      _fetchCurrentUserName();
    } else if (authState is AuthSuccess) {
      _currentUserUid = authState.user.uid;
      _fetchCurrentUserName();
    } else if (authState is AuthOffline) {
      _currentUserUid = authState.user.uid;
      _fetchCurrentUserName();
    }
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    if (widget.project == null || _currentUserUid == null) {
      _isAdmin = false;
      return;
    }
    final matches = widget.project!.members.where((m) => m.uid == _currentUserUid);
    final ProjectMember? member = matches.isNotEmpty ? matches.first : null;
    _isAdmin = (member?.role == 'admin') || widget.project!.creatorUid == _currentUserUid;
  }

  Future<void> _fetchCurrentUserName() async {
    try {
      if (_currentUserUid == null) return;
      final doc = await FirebaseFirestore.instance.collection('Users').doc(_currentUserUid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _currentUserName = (data?['userName'] as String?) ?? (data?['email'] as String? ?? '');
        });
      }
    } catch (_) {
      // ignore and keep default
    }
  }

  void _subscribeToTask() {
    if (widget.projectId.isEmpty || widget.task.id.isEmpty) return;
    
    FirebaseFirestore.instance
        .collection('Projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.task.id)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data()!;
      print('🔍 [_subscribeToTask] Task data updated - statusName: ${data['statusName']}');
      
      // Fetch sprint information if task is assigned to a sprint
      final sprintId = data['sprintId'] as String?;
      String? sprintName;
      String? sprintStatus;
      
      if (sprintId != null && sprintId.isNotEmpty) {
        try {
          final sprintDoc = await FirebaseFirestore.instance
              .collection('Projects')
              .doc(widget.projectId)
              .collection('sprints')
              .doc(sprintId)
              .get();
          
          if (sprintDoc.exists) {
            final sprintData = sprintDoc.data();
            sprintName = sprintData?['name'] as String?;
            sprintStatus = sprintData?['status'] as String?;
          }
        } catch (e) {
          print('Error fetching sprint: $e');
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        _sprintName = sprintName;
        _sprintStatus = sprintStatus;
        
        _task = TaskItem(
          id: widget.task.id,
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          assigneeId: data['assigneeId'] as String? ?? '',
          assigneeName: data['assigneeName'] as String? ?? '',
          priority: _priorityFromString(data['priority'] as String? ?? 'medium'),
          subTasks: const <String>[],
          dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
          status: _statusFromString(data['status'] as String? ?? 'todo'),
          statusName: data['statusName'] as String?,
          timeSpentMinutes: data['timeSpentMinutes'] as int? ?? 0,
          startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
          sprintId: sprintId,
          sprintName: sprintName,
        );

        // Parse subtasks (supports legacy list<String> or new list<Map>)
        final raw = data['subTasks'];
        _subTasks = <_SubTaskItem>[];
        if (raw is List) {
          for (final entry in raw) {
            if (entry is String) {
              _subTasks.add(_SubTaskItem(
                title: entry,
                completed: false,
                createdByUid: '',
                createdByName: '',
              ));
            } else if (entry is Map) {
              final m = Map<String, dynamic>.from(entry);
              _subTasks.add(_SubTaskItem(
                title: m['title'] as String? ?? '',
                completed: m['completed'] as bool? ?? false,
                createdByUid: m['createdByUid'] as String? ?? '',
                createdByName: m['createdByName'] as String? ?? '',
                updatedByUid: m['updatedByUid'] as String? ?? '',
                updatedByName: m['updatedByName'] as String? ?? '',
              ));
            }
          }
        }
      });
    });
  }

  TaskPriority _priorityFromString(String v) {
    switch (v) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }

  TaskStatus _statusFromString(String v) {
    switch (v) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  String _statusLabel(TaskStatus s) {
    // If task has a custom statusName, use it
    if (_task.statusName != null && _task.statusName!.isNotEmpty) {
      return _task.statusName!;
    }
    
    // Default labels
    switch (s) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  Future<void> _updateStatus(TaskStatus newStatus) async {
    if (widget.projectId.isEmpty || widget.task.id.isEmpty) return;
    if (!mounted) return;
    
    // Add small delay to avoid Flutter web debug errors
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) return;
    
    // Defer state update to avoid Flutter web debug errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      setState(() {
        int newTimeSpent = _task.timeSpentMinutes;
        DateTime? newStartedAt = _task.startedAt;
        
        // Update time tracking
        if (newStatus == TaskStatus.inProgress && _task.status != TaskStatus.inProgress) {
          newStartedAt = DateTime.now();
        } else if (_task.status == TaskStatus.inProgress && newStatus != TaskStatus.inProgress) {
          if (_task.startedAt != null) {
            final elapsed = DateTime.now().difference(_task.startedAt!);
            newTimeSpent = _task.timeSpentMinutes + elapsed.inMinutes;
          }
          newStartedAt = null;
        }
        
        _task = TaskItem(
        id: _task.id,
        title: _task.title,
        description: _task.description,
        assigneeId: _task.assigneeId,
        assigneeName: _task.assigneeName,
        priority: _task.priority,
        subTasks: _task.subTasks,
        dueDate: _task.dueDate,
        status: newStatus,
          timeSpentMinutes: newTimeSpent,
          startedAt: newStartedAt,
          sprintId: _task.sprintId,
          sprintName: _task.sprintName,
        );
      });
    });
    
    // Update Firebase in the background
    try {
      // Prepare update data
      final updateData = <String, dynamic>{
        'status': _statusToString(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Track time when moving to/from inProgress
      if (newStatus == TaskStatus.inProgress && _task.status != TaskStatus.inProgress) {
        // Starting work - set startedAt
        updateData['startedAt'] = FieldValue.serverTimestamp();
        print('⏱️ [TaskDetail] Starting timer for task');
      } else if (_task.status == TaskStatus.inProgress && newStatus != TaskStatus.inProgress) {
        // Stopping work - calculate and save time spent
        if (_task.startedAt != null) {
          final elapsed = DateTime.now().difference(_task.startedAt!);
          final totalTime = _task.timeSpentMinutes + elapsed.inMinutes;
          updateData['timeSpentMinutes'] = totalTime;
          updateData['startedAt'] = null; // Clear startedAt
          print('⏱️ [TaskDetail] Stopping timer. Total time: ${totalTime} minutes');
        }
      }
      
      await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.projectId)
          .collection('tasks')
          .doc(widget.task.id)
          .update(updateData);
      // Success - the snapshot listener will update the UI if needed
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
      // Note: The snapshot listener will revert the UI to the actual state from Firebase
    }
  }

  String _statusToString(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'inProgress';
      case TaskStatus.done:
        return 'done';
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _buildStatusButtons() {
    // Use custom statuses if available
    if (widget.project?.customStatuses != null && widget.project!.customStatuses!.isNotEmpty) {
      final customStatuses = widget.project!.customStatuses!;
      print('🔍 [TaskDetail] Rendering ${customStatuses.length} custom status buttons');
      
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: customStatuses.map((status) {
          // Parse hex color
          Color statusColor;
          try {
            final hexColor = status.colorHex.replaceAll('#', '');
            statusColor = Color(int.parse('FF$hexColor', radix: 16));
          } catch (e) {
            statusColor = const Color(0xFF6366F1);
          }
          
          // Check if this is the current status based on enum mapping
          TaskStatus mappedStatus;
          if (status.name.toLowerCase().contains('progress')) {
            mappedStatus = TaskStatus.inProgress;
          } else if (status.name.toLowerCase().contains('done') || 
                     status.name.toLowerCase().contains('complete')) {
            mappedStatus = TaskStatus.done;
          } else {
            mappedStatus = TaskStatus.todo;
          }
          
          final isCurrentStatus = _task.statusName == status.name;
          
          return InkWell(
            onTap: () async {
              print('🔘 [TaskDetail] Status button clicked: ${status.name}');
              
              // Update directly without triggering subtask logic
              if (widget.projectId.isEmpty || widget.task.id.isEmpty) return;
              if (!mounted) return;
              
              // Defer UI update to avoid Flutter web debug errors
              await Future.delayed(const Duration(milliseconds: 50));
              
              if (!mounted) return;
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                
                setState(() {
                  int newTimeSpent = _task.timeSpentMinutes;
                  DateTime? newStartedAt = _task.startedAt;
                  
                  // Update time tracking
                  if (mappedStatus == TaskStatus.inProgress && _task.status != TaskStatus.inProgress) {
                    newStartedAt = DateTime.now();
                  } else if (_task.status == TaskStatus.inProgress && mappedStatus != TaskStatus.inProgress) {
                    if (_task.startedAt != null) {
                      final elapsed = DateTime.now().difference(_task.startedAt!);
                      newTimeSpent = _task.timeSpentMinutes + elapsed.inMinutes;
                    }
                    newStartedAt = null;
                  }
                  
                  _task = TaskItem(
                    id: _task.id,
                    title: _task.title,
                    description: _task.description,
                    assigneeId: _task.assigneeId,
                    assigneeName: _task.assigneeName,
                    priority: _task.priority,
                    subTasks: _task.subTasks,
                    dueDate: _task.dueDate,
                    status: mappedStatus,
                    statusName: status.name, // Save custom status name
                    timeSpentMinutes: newTimeSpent,
                    startedAt: newStartedAt,
                    sprintId: _task.sprintId,
                    sprintName: _task.sprintName,
                  );
                });
              });
              
              // Update Firebase with BOTH enum and name
              try {
                // Prepare update data
                final updateData = <String, dynamic>{
                  'status': _statusToString(mappedStatus), // For backward compatibility
                  'statusName': status.name, // Custom status name
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                
                // Track time when moving to/from inProgress
                if (mappedStatus == TaskStatus.inProgress && _task.status != TaskStatus.inProgress) {
                  // Starting work - set startedAt
                  updateData['startedAt'] = FieldValue.serverTimestamp();
                  print('⏱️ [TaskDetail] Starting timer for task');
                } else if (_task.status == TaskStatus.inProgress && mappedStatus != TaskStatus.inProgress) {
                  // Stopping work - calculate and save time spent
                  if (_task.startedAt != null) {
                    final elapsed = DateTime.now().difference(_task.startedAt!);
                    final totalTime = _task.timeSpentMinutes + elapsed.inMinutes;
                    updateData['timeSpentMinutes'] = totalTime;
                    updateData['startedAt'] = null; // Clear startedAt
                    print('⏱️ [TaskDetail] Stopping timer. Total time: ${totalTime} minutes');
                  }
                }
                
                await FirebaseFirestore.instance
                    .collection('Projects')
                    .doc(widget.projectId)
                    .collection('tasks')
                    .doc(widget.task.id)
                    .update(updateData);
                print('✅ [TaskDetail] Status updated to: ${status.name} (enum: ${_statusToString(mappedStatus)})');
              } catch (e) {
                print('❌ [TaskDetail] Failed to update status: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update status: $e')),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentStatus 
                  ? statusColor
                  : statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusColor,
                  width: 2,
                ),
              ),
              child: Text(
                status.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrentStatus ? Colors.white : statusColor,
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
    
    // Default status buttons
    print('⚠️ [TaskDetail] Rendering DEFAULT status buttons');
    return Row(
      children: [
        Expanded(
          child: _StatusButton(
            label: 'To Do',
            status: TaskStatus.todo,
            currentStatus: _task.status,
            color: AppPallete.orange,
            onTap: () => _updateStatus(TaskStatus.todo),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusButton(
            label: 'In Progress',
            status: TaskStatus.inProgress,
            currentStatus: _task.status,
            color: Colors.amber,
            onTap: () => _updateStatus(TaskStatus.inProgress),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusButton(
            label: 'Done',
            status: TaskStatus.done,
            currentStatus: _task.status,
            color: Colors.green,
            onTap: () => _updateStatus(TaskStatus.done),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (_subTasks.isEmpty) {
      return LinearProgressIndicator(
        value: 0,
        minHeight: 8,
        color: Colors.green,
        backgroundColor: Theme.of(context).dividerColor.withOpacity(0.4),
      );
    }
    final total = _subTasks.length;
    final completed = _subTasks.where((s) => s.completed).length;
    final progress = completed / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          color: Colors.green,
          backgroundColor: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
        const SizedBox(height: 6),
        PrimaryText(
          text: 'Progress: ${completed}/${total}',
          size: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Future<void> _openAddSubTaskSheet() async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      builder: (context) {
        final insets = MediaQuery.of(context).viewInsets;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + insets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrimaryText(
                text: 'Add sub task',
                size: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFE5E7EB)
                    : AppPallete.secondary,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Sub task title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primary),
                  onPressed: () async {
                    final title = ctrl.text.trim();
                    if (title.isEmpty) return;
                    await _addSubTask(title);
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const PrimaryText(
                    text: 'Add',
                    color: AppPallete.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addSubTask(String title) async {
    if (widget.projectId.isEmpty || widget.task.id.isEmpty) return;
    final newItem = _SubTaskItem(
      title: title,
      completed: false,
      createdByUid: _currentUserUid ?? '',
      createdByName: _currentUserName,
    );
    final ref = FirebaseFirestore.instance
        .collection('Projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.task.id);

    final snap = await ref.get();
    final data = snap.data() ?? {};
    final List<dynamic> raw = (data['subTasks'] as List?) ?? <dynamic>[];
    final updated = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is String) {
        updated.add({
          'title': entry,
          'completed': false,
          'createdByUid': '',
          'createdByName': '',
          'updatedByUid': '',
          'updatedByName': '',
        });
      } else if (entry is Map) {
        updated.add(Map<String, dynamic>.from(entry));
      }
    }
    updated.add(newItem.toJson());
    await ref.update({'subTasks': updated, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _task.dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      await _updateDueDate(picked);
    }
  }

  Future<void> _updateDueDate(DateTime dueDate) async {
    if (widget.projectId.isEmpty || widget.task.id.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.projectId)
          .collection('tasks')
          .doc(widget.task.id)
          .update({
        'dueDate': Timestamp.fromDate(dueDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _task = TaskItem(
          id: _task.id,
          title: _task.title,
          description: _task.description,
          assigneeId: _task.assigneeId,
          assigneeName: _task.assigneeName,
          priority: _task.priority,
          subTasks: _task.subTasks,
          dueDate: dueDate,
          status: _task.status,
          timeSpentMinutes: _task.timeSpentMinutes,
          startedAt: _task.startedAt,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update due date: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSubTask(int index, bool value) async {
    if (widget.projectId.isEmpty || widget.task.id.isEmpty) return;
    setState(() {
      final old = _subTasks[index];
      _subTasks[index] = _SubTaskItem(
        title: old.title,
        completed: value,
        createdByUid: old.createdByUid,
        createdByName: old.createdByName,
        updatedByUid: _currentUserUid ?? '',
        updatedByName: _currentUserName,
      );
    });

    // Only auto-derive status if NOT using custom statuses
    TaskStatus? derivedStatus;
    if (widget.project?.customStatuses == null || widget.project!.customStatuses!.isEmpty) {
      // Derive task status from subtasks for default workflow
      final bool allDone = _subTasks.isNotEmpty && _subTasks.every((s) => s.completed);
      final bool anyDone = _subTasks.any((s) => s.completed);
      derivedStatus = allDone
          ? TaskStatus.done
          : (anyDone ? TaskStatus.inProgress : TaskStatus.todo);
      print('🔄 [_toggleSubTask] Auto-derived status: ${_statusToString(derivedStatus)}');
    } else {
      print('⚠️ [_toggleSubTask] Custom statuses present - NOT auto-deriving status');
    }

    final ref = FirebaseFirestore.instance
        .collection('Projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.task.id);
    
    final updateData = <String, dynamic>{
      'subTasks': _subTasks.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // Only update status if we derived one (default workflow)
    if (derivedStatus != null) {
      updateData['status'] = _statusToString(derivedStatus);
    }
    
    await ref.update(updateData);

    if (!mounted) return;
    setState(() {
      _task = TaskItem(
        id: _task.id,
        title: _task.title,
        description: _task.description,
        assigneeId: _task.assigneeId,
        assigneeName: _task.assigneeName,
        priority: _task.priority,
        subTasks: _task.subTasks,
        dueDate: _task.dueDate,
        status: derivedStatus ?? _task.status, // Keep current status if not auto-derived
        timeSpentMinutes: _task.timeSpentMinutes,
        startedAt: _task.startedAt,
      );
    });
  }

  Future<void> _showSprintPicker() async {
    if (widget.project == null || widget.projectId.isEmpty) return;
    
    // Fetch available sprints
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
          'startDate': (data['startDate'] as Timestamp).toDate(),
          'endDate': (data['endDate'] as Timestamp).toDate(),
        };
      }).toList();
      
      if (!mounted) return;
      
      if (sprints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No sprints available. Create a sprint first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Show sprint picker
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _SprintPickerSheet(
          sprints: sprints,
          currentSprintId: _task.sprintId,
          onSprintSelected: (sprintId, sprintName) async {
            await _assignToSprint(sprintId, sprintName);
          },
          onRemoveSprint: _task.sprintId != null 
              ? () async {
                  await _removeFromSprint();
                }
              : null,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sprints: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _assignToSprint(String? sprintId, String? sprintName) async {
    if (widget.projectId.isEmpty || widget.task.id.isEmpty) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.projectId)
          .collection('tasks')
          .doc(widget.task.id)
          .update({
        'sprintId': sprintId,
        'sprintStatus': sprintId != null ? 'committed' : 'backlog',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sprintId != null 
                ? '✅ Task assigned to sprint: $sprintName'
                : '✅ Task removed from sprint'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sprint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _removeFromSprint() async {
    await _assignToSprint(null, null);
  }

  Future<void> _openEditTaskSheet() async {
    if (widget.project == null) return;
    
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: EditTaskDialog(
          project: widget.project!,
          projectId: widget.projectId,
          task: _task,
          onSubmit: ({
            required String title,
            required String description,
            required String assigneeId,
            required String assigneeName,
            required TaskPriority priority,
            required DateTime? dueDate,
            String? statusName,
            TaskStatus? status,
            String? sprintId,
          }) {
            _updateTaskDetails(
              title: title,
              description: description,
              assigneeId: assigneeId,
              assigneeName: assigneeName,
              priority: priority,
              dueDate: dueDate,
              statusName: statusName,
              status: status,
              sprintId: sprintId,
            );
          },
          ),
        );
      },
    );
  }

  String _priorityToString(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }

  Future<void> _updateTaskDetails({
    required String title,
    required String description,
    required String assigneeId,
    required String assigneeName,
    required TaskPriority priority,
    required DateTime? dueDate,
    String? statusName,
    TaskStatus? status,
    String? sprintId,
  }) async {
    if (widget.projectId.isEmpty || widget.task.id.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final updateData = <String, dynamic>{
        'title': title,
        'description': description,
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'priority': _priorityToString(priority),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (dueDate != null) {
        updateData['dueDate'] = Timestamp.fromDate(dueDate);
      } else {
        updateData['dueDate'] = FieldValue.delete();
      }
      
      // Update status if provided
      if (status != null) {
        updateData['status'] = _statusToString(status);
      }
      if (statusName != null) {
        updateData['statusName'] = statusName;
      }
      
      // Update sprint assignment
      updateData['sprintId'] = sprintId;
      updateData['sprintStatus'] = sprintId != null ? 'committed' : 'backlog';

      await FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.projectId)
          .collection('tasks')
          .doc(widget.task.id)
          .update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Task updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Update local state optimistically
      setState(() {
        _task = TaskItem(
          id: _task.id,
          title: title,
          description: description,
          assigneeId: assigneeId,
          assigneeName: assigneeName,
          priority: priority,
          subTasks: _task.subTasks,
          dueDate: dueDate,
          status: status ?? _task.status,
          statusName: statusName ?? _task.statusName,
          timeSpentMinutes: _task.timeSpentMinutes,
          startedAt: _task.startedAt,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = kIsWeb;
    final webBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA);
    final mobileBg = Theme.of(context).scaffoldBackgroundColor;
    final backgroundColor = isWeb ? webBg : mobileBg;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFE5E7EB)
                : AppPallete.secondary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: PrimaryText(
          text: _task.title,
          size: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE5E7EB)
              : AppPallete.secondary,
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFE5E7EB)
                    : AppPallete.secondary,
              ),
              onPressed: _openEditTaskSheet,
              tooltip: 'Edit Task',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header summary with priority, status and progress
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryText(
                                text: 'Priority: ${_priorityLabel(_task.priority)}',
                                size: 14,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE5E7EB)
                                    : AppPallete.secondary,
                              ),
                            ),
                            PrimaryText(
                              text: 'Current state: ${_statusLabel(_task.status)}',
                              size: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFFE5E7EB)
                                  : AppPallete.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildProgressBar(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Update Status Section (moved above Sub Tasks)
                  PrimaryText(
                    text: 'Update Status',
                    size: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE5E7EB)
                        : AppPallete.secondary,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusButtons(),
                  const SizedBox(height: 24),

                  // Description
                  if (_task.description.isNotEmpty) ...[
                    PrimaryText(
                      text: 'Description',
                      size: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE5E7EB)
                          : AppPallete.secondary,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                      ),
                      child: PrimaryText(
                        text: _task.description,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Details Section
                  PrimaryText(
                    text: 'Details',
                    size: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE5E7EB)
                        : AppPallete.secondary,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Assignee',
                    value: _task.assigneeName,
                  ),
                  const SizedBox(height: 12),
                  
                  // Sprint information (always show, with option to assign)
                  InkWell(
                    onTap: _isAdmin ? () => _showSprintPicker() : null,
                    borderRadius: BorderRadius.circular(12),
                    child: _sprintName != null && _sprintName!.isNotEmpty
                        ? _SprintDetailRow(
                            sprintName: _sprintName!,
                            sprintStatus: _sprintStatus,
                            isDark: Theme.of(context).brightness == Brightness.dark,
                            isEditable: _isAdmin,
                          )
                        : _NotAssignedSprintRow(
                            isDark: Theme.of(context).brightness == Brightness.dark,
                            canAssign: _isAdmin,
                          ),
                  ),
                  const SizedBox(height: 12),
                  
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Due Date',
                    value: _task.dueDate != null ? _formatDate(_task.dueDate!) : 'Not set',
                    onEdit: _isAdmin ? () => _pickDueDate() : null,
                    showAdd: _task.dueDate == null && _isAdmin,
                  ),
                  const SizedBox(height: 24),
                  
                  // Sub Tasks
                  PrimaryText(
                    text: 'Sub Tasks',
                    size: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE5E7EB)
                        : AppPallete.secondary,
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < _subTasks.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                        ),
                        child: CheckboxListTile(
                          value: _subTasks[i].completed,
                          onChanged: (val) => _toggleSubTask(i, val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: PrimaryText(
                            text: _subTasks[i].title,
                            size: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFE5E7EB)
                                : AppPallete.secondary,
                            decoration: _subTasks[i].completed ? TextDecoration.lineThrough : null,
                          ),
                          subtitle: (_subTasks[i].createdByName.isNotEmpty)
                              ? PrimaryText(
                                  text: 'Added by ${_subTasks[i].createdByName}',
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _openAddSubTaskSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add sub task'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
    this.showAdd = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final bool showAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimaryText(
                  text: label,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                PrimaryText(
                  text: value,
                  size: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE5E7EB)
                      : AppPallete.secondary,
                ),
              ],
            ),
          ),
          if (showAdd && onEdit != null)
            OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Set'),
            )
          else if (onEdit != null && !showAdd)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
              color: AppPallete.primary,
            ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.status,
    required this.currentStatus,
    required this.color,
    required this.onTap,
  });

  final String label;
  final TaskStatus status;
  final TaskStatus currentStatus;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = status == currentStatus;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Center(
          child: PrimaryText(
            text: label,
            size: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : AppPallete.secondary,
          ),
        ),
      ),
    );
  }
}

class _SprintDetailRow extends StatelessWidget {
  const _SprintDetailRow({
    required this.sprintName,
    required this.sprintStatus,
    required this.isDark,
    this.isEditable = false,
  });

  final String sprintName;
  final String? sprintStatus;
  final bool isDark;
  final bool isEditable;

  Color _getSprintStatusColor() {
    switch (sprintStatus) {
      case 'active':
        return const Color(0xFFEC4899); // Pink
      case 'completed':
        return const Color(0xFF10B981); // Green
      case 'planning':
        return const Color(0xFF3B82F6); // Blue
      default:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  String _getSprintStatusLabel() {
    switch (sprintStatus) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'planning':
        return 'Planning';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Sprint';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getSprintStatusColor();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.rocket_launch,
              size: 20,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimaryText(
                  text: 'Assigned Sprint',
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryText(
                        text: sprintName,
                        size: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE5E7EB)
                            : AppPallete.secondary,
                      ),
                    ),
                    if (sprintStatus != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getSprintStatusLabel(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isEditable) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
            ),
          ],
        ],
      ),
    );
  }
}

/// Not Assigned Sprint Row - Shows when task is not in a sprint
class _NotAssignedSprintRow extends StatelessWidget {
  const _NotAssignedSprintRow({
    required this.isDark,
    required this.canAssign,
  });

  final bool isDark;
  final bool canAssign;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E1E1E).withOpacity(0.5) 
            : AppPallete.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF2D2D2D) 
              : AppPallete.borderGray,
          width: 1,
          style: canAssign ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPallete.textGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.rocket_launch_outlined,
              size: 20,
              color: isDark ? const Color(0xFF6B7280) : AppPallete.textGray,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimaryText(
                  text: 'Sprint',
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                PrimaryText(
                  text: 'Not assigned',
                  size: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF6B7280) : AppPallete.textGray,
                ),
              ],
            ),
          ),
          if (canAssign) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppPallete.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add,
                    size: 14,
                    color: AppPallete.primary,
                  ),
                  const SizedBox(width: 4),
                  PrimaryText(
                    text: 'Assign',
                    size: 12,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.primary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sprint Picker Bottom Sheet
class _SprintPickerSheet extends StatelessWidget {
  const _SprintPickerSheet({
    required this.sprints,
    required this.currentSprintId,
    required this.onSprintSelected,
    this.onRemoveSprint,
  });

  final List<Map<String, dynamic>> sprints;
  final String? currentSprintId;
  final Function(String sprintId, String sprintName) onSprintSelected;
  final VoidCallback? onRemoveSprint;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppPallete.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4B5563) : AppPallete.borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: AppPallete.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryText(
                    text: 'Assign to Sprint',
                    size: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE5E7EB) : AppPallete.secondary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray,
          ),
          // Sprints list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: sprints.length + (onRemoveSprint != null ? 1 : 0),
              itemBuilder: (context, index) {
                // Remove from sprint option
                if (index == sprints.length && onRemoveSprint != null) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onRemoveSprint?.call();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: PrimaryText(
                              text: 'Remove from Sprint',
                              size: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final sprint = sprints[index];
                final sprintId = sprint['id'] as String;
                final sprintName = sprint['name'] as String;
                final status = sprint['status'] as String;
                final isSelected = sprintId == currentSprintId;
                final statusColor = _getSprintStatusColor(status);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => onSprintSelected(sprintId, sprintName),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPallete.primary.withOpacity(0.1)
                            : (isDark ? const Color(0xFF0F0F0F) : AppPallete.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppPallete.primary
                              : (isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PrimaryText(
                                  text: sprintName,
                                  size: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFE5E7EB) : AppPallete.secondary,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getSprintStatusLabel(status).toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.calendar_today,
                                      size: 10,
                                      color: isDark ? const Color(0xFF6B7280) : AppPallete.textGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(sprint['startDate'] as DateTime).day}/${(sprint['startDate'] as DateTime).month} - ${(sprint['endDate'] as DateTime).day}/${(sprint['endDate'] as DateTime).month}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF6B7280) : AppPallete.textGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppPallete.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubTaskItem {
  _SubTaskItem({
    required this.title,
    required this.completed,
    required this.createdByUid,
    required this.createdByName,
    this.updatedByUid = '',
    this.updatedByName = '',
  });

  final String title;
  final bool completed;
  final String createdByUid;
  final String createdByName;
  final String updatedByUid;
  final String updatedByName;

  Map<String, dynamic> toJson() => {
        'title': title,
        'completed': completed,
        'createdByUid': createdByUid,
        'createdByName': createdByName,
        'updatedByUid': updatedByUid,
        'updatedByName': updatedByName,
      };
}


// Using TaskItem, TaskPriority, and TaskStatus from shared/task_types.dart

