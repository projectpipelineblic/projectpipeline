import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_app/core/theme/app_pallete.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_app/core/widgets/primart_text.dart';
import 'package:task_app/features/projects/domain/entities/project_entity.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key, required this.project});

  final ProjectEntity project;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final List<_TaskItem> _tasks = <_TaskItem>[];
  TaskStatusFilter _selectedFilter = TaskStatusFilter.all;
  String? _filterAssigneeId;
  TaskPriority? _filterPriority;
  DateTime? _filterDueBefore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tasksSub;
  bool _showMembers = false;
  String? _currentUserUid;
  late ProjectEntity _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _subscribeTasks();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // derive current user id from AuthBloc if available
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserUid = authState.user.uid;
    } else if (authState is AuthSuccess) {
      _currentUserUid = authState.user.uid;
    } else if (authState is AuthOffline) {
      _currentUserUid = authState.user.uid;
    }
  }

  void _subscribeTasks() {
    final projectId = widget.project.id;
    if (projectId == null) return;
    _tasksSub?.cancel();
    _tasksSub = FirebaseFirestore.instance
        .collection('Projects')
        .doc(projectId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final list = snapshot.docs.map((d) {
        final data = d.data();
        return _TaskItem(
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          assigneeId: data['assigneeId'] as String? ?? '',
          assigneeName: data['assigneeName'] as String? ?? '',
          priority: _priorityFromString(data['priority'] as String? ?? 'medium'),
          subTasks: (data['subTasks'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
          dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
          status: _statusFromString(data['status'] as String? ?? 'todo'),
        );
      }).toList();
      setState(() => _tasks
        ..clear()
        ..addAll(list));
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

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: PrimaryText(
          text: _project.name,
          size: 20,
          fontWeight: FontWeight.bold,
          color: AppPallete.secondary,
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Project',
            onPressed: _openEditProjectSheet,
            icon: const Icon(Icons.edit_outlined),
            color: AppPallete.primary,
          ),
          IconButton(
            tooltip: 'Assign Task',
            onPressed: _openCreateTaskSheet,
            icon: const Icon(Icons.add),
            color: AppPallete.primary,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProjectHeader(
              project: _project,
              onMembersTap: () => setState(() => _showMembers = !_showMembers),
            ),
            if (_showMembers) ...[
              const SizedBox(height: 12),
              _MembersList(
                project: _project,
                currentUserUid: _currentUserUid,
                onToggleRole: _updateMemberRole,
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  tooltip: 'Filter',
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.filter_list),
                  color: AppPallete.secondary,
                ),
                const SizedBox(width: 4),
                const _SectionTitle(title: 'Tasks'),
              ],
            ),
            const SizedBox(height: 12),
            _TaskFilters(
              selected: _selectedFilter,
              onChanged: (f) => setState(() => _selectedFilter = f),
            ),
            const SizedBox(height: 12),
            _TaskList(tasks: _filteredTasks()),
          ],
        ),
      ),
    );
  }

  List<_TaskItem> _filteredTasks() {
    Iterable<_TaskItem> it = _tasks;
    switch (_selectedFilter) {
      case TaskStatusFilter.all:
        break;
      case TaskStatusFilter.todo:
        it = it.where((t) => t.status == TaskStatus.todo);
        break;
      case TaskStatusFilter.inProgress:
        it = it.where((t) => t.status == TaskStatus.inProgress);
        break;
      case TaskStatusFilter.done:
        it = it.where((t) => t.status == TaskStatus.done);
        break;
    }
    if (_filterAssigneeId != null && _filterAssigneeId!.isNotEmpty) {
      it = it.where((t) => t.assigneeId == _filterAssigneeId);
    }
    if (_filterPriority != null) {
      it = it.where((t) => t.priority == _filterPriority);
    }
    if (_filterDueBefore != null) {
      it = it.where((t) => t.dueDate != null && !t.dueDate!.isAfter(_filterDueBefore!));
    }
    return it.toList();
  }

  void _openCreateTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        final insets = MediaQuery.of(context).viewInsets;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + insets.bottom,
            ),
            child: _CreateTaskForm(
              project: _project,
              onSubmit: (task) async {
                await _createTaskInFirestore(task);
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task created')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _createTaskInFirestore(_TaskItem task) async {
    final projectId = _project.id;
    if (projectId == null) return;
    final col = FirebaseFirestore.instance
        .collection('Projects')
        .doc(projectId)
        .collection('tasks');
    final doc = col.doc();
    await doc.set({
      'id': doc.id,
      'title': task.title,
      'description': task.description,
      'assigneeId': task.assigneeId,
      'assigneeName': task.assigneeName,
      'priority': _priorityToString(task.priority),
      'subTasks': task.subTasks,
      'dueDate': task.dueDate == null ? null : Timestamp.fromDate(task.dueDate!),
      'status': _statusToString(task.status),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  Future<void> _updateMemberRole({
    required String memberUid,
    required bool makeAdmin,
  }) async {
    final projectId = _project.id;
    if (projectId == null) return;
    final ref = FirebaseFirestore.instance.collection('Projects').doc(projectId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final List<dynamic> membersRaw = data['members'] as List<dynamic>? ?? <dynamic>[];
    final members = membersRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    for (final m in members) {
      if (m['uid'] == memberUid) {
        m['role'] = makeAdmin ? 'admin' : 'member';
        break;
      }
    }
    await ref.update({'members': members});
    if (!mounted) return;
    setState(() {}); // refresh local widgets using widget.project members next build if passed anew
  }

  Future<void> _openEditProjectSheet() async {
    final nameCtrl = TextEditingController(text: _project.name);
    final descCtrl = TextEditingController(text: _project.description);
    final List<_InviteRow> inviteRows = <_InviteRow>[];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      builder: (context) {
        final insets = MediaQuery.of(context).viewInsets;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + insets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PrimaryText(
                    text: 'Edit Project',
                    size: 18,
                    fontWeight: FontWeight.w700,
                    color: AppPallete.secondary,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Project name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Project description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: PrimaryText(
                          text: 'Add members (optional)',
                          size: 14,
                          fontWeight: FontWeight.w700,
                          color: AppPallete.secondary,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setSheetState(() => inviteRows.add(_InviteRow())),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add row'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < inviteRows.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: inviteRows[i].emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'User email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Admin'),
                                  Switch.adaptive(
                                    value: inviteRows[i].makeAdmin,
                                    onChanged: (v) => setSheetState(() => inviteRows[i].makeAdmin = v),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('Access'),
                                  Switch.adaptive(
                                    value: inviteRows[i].hasAccess,
                                    onChanged: (v) => setSheetState(() => inviteRows[i].hasAccess = v),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => setSheetState(() => inviteRows.removeAt(i)),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primary),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        await _updateProjectDetails(name: name, description: descCtrl.text.trim());
                        for (final r in inviteRows) {
                          final email = r.emailCtrl.text.trim();
                          if (email.isEmpty) continue;
                          await _sendInvite(email: email, makeAdmin: r.makeAdmin, hasAccess: r.hasAccess);
                        }
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Project updated')),
                        );
                      },
                      child: const PrimaryText(
                        text: 'Save changes',
                        color: AppPallete.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateProjectDetails({required String name, required String description}) async {
    final projectId = _project.id;
    if (projectId == null) return;
    await FirebaseFirestore.instance.collection('Projects').doc(projectId).update({
      'name': name,
      'description': description,
    });
    if (!mounted) return;
    setState(() {
      _project = ProjectEntity(
        id: _project.id,
        name: name,
        description: description,
        creatorUid: _project.creatorUid,
        creatorName: _project.creatorName,
        createdAt: _project.createdAt,
        members: _project.members,
        pendingInvites: _project.pendingInvites,
      );
    });
  }

  

  Future<void> _sendInvite({required String email, required bool makeAdmin, required bool hasAccess}) async {
    try {
      final projectId = _project.id;
      if (projectId == null) return;

      // find user by email
      final users = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (users.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }
      final invitedUserUid = users.docs.first.id;

      // current user (inviter)
      String inviterName = '';
      if (_currentUserUid != null) {
        final inviterDoc = await FirebaseFirestore.instance.collection('Users').doc(_currentUserUid).get();
        inviterName = inviterDoc.data()?['userName'] as String? ?? (inviterDoc.data()?['email'] as String? ?? '');
      }

      final inviteRef = FirebaseFirestore.instance.collection('TeamInvites').doc();
      await inviteRef.set({
        'inviteId': inviteRef.id,
        'projectId': projectId,
        'projectName': _project.name,
        'invitedUserUid': invitedUserUid,
        'invitedUserEmail': email,
        'creatorUid': _currentUserUid ?? _project.creatorUid,
        'creatorName': inviterName.isNotEmpty ? inviterName : _project.creatorName,
        'createdAt': FieldValue.serverTimestamp(),
        'role': makeAdmin ? 'admin' : 'member',
        'hasAccess': hasAccess,
        'status': 'pending',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invite: $e')),
      );
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        String? assignee = _filterAssigneeId;
        TaskPriority? priority = _filterPriority;
        DateTime? dueBefore = _filterDueBefore;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PrimaryText(
                  text: 'Filter tasks',
                  size: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.secondary,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: assignee,
                  decoration: const InputDecoration(
                    labelText: 'Assignee',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Any'),
                    ),
                    for (final m in widget.project.members)
                      DropdownMenuItem<String>(
                        value: m.uid,
                        child: Text(m.name.isNotEmpty ? m.name : m.email),
                      ),
                  ],
                  onChanged: (v) => assignee = v == null || v.isEmpty ? null : v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem<TaskPriority>(value: null, child: Text('Any')),
                    DropdownMenuItem(value: TaskPriority.low, child: Text('Low')),
                    DropdownMenuItem(value: TaskPriority.medium, child: Text('Medium')),
                    DropdownMenuItem(value: TaskPriority.high, child: Text('High')),
                  ],
                  onChanged: (v) => priority = v,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueBefore ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setState(() => dueBefore = picked);
                          }
                        },
                        icon: const Icon(Icons.event),
                        label: PrimaryText(
                          text: dueBefore == null
                              ? 'Due before: Any'
                              : 'Due before: ${_formatShortDate(dueBefore)}',
                          size: 14,
                          color: AppPallete.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          assignee = null;
                          priority = null;
                          dueBefore = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primary),
                    onPressed: () {
                      setState(() {
                        _filterAssigneeId = assignee;
                        _filterPriority = priority;
                        _filterDueBefore = dueBefore;
                      });
                      Navigator.of(context).pop();
                    },
                    child: const PrimaryText(
                      text: 'Apply Filters',
                      color: AppPallete.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project, this.onMembersTap});

  final ProjectEntity project;
  final VoidCallback? onMembersTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: PrimaryText(
                  text: _projectInitials(project.name),
                  size: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrimaryText(
                      text: project.name,
                      size: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(height: 6),
                    PrimaryText(
                      text: project.description,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onMembersTap,
                child: _InfoPill(
                icon: Icons.people_outline,
                label: '${project.members.length} member${project.members.length == 1 ? '' : 's'}',
                ),
              ),
              const SizedBox(width: 8),
              if (project.pendingInvites.isNotEmpty)
                _InfoPill(
                  icon: Icons.mail_outline,
                  label: '${project.pendingInvites.length} invite${project.pendingInvites.length == 1 ? '' : 's'}',
                  color: AppPallete.orange,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _projectInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final words = trimmed.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w.substring(0, 1)).toUpperCase();
    }
    final first = words[0][0];
    final second = words[1][0];
    return (first + second).toUpperCase();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return PrimaryText(
      text: title,
      size: 16,
      fontWeight: FontWeight.w700,
      color: AppPallete.secondary,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? colorScheme.onSurfaceVariant).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          PrimaryText(
            text: label,
            size: 12,
            color: color ?? colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({
    required this.project,
    required this.currentUserUid,
    required this.onToggleRole,
  });

  final ProjectEntity project;
  final String? currentUserUid;
  final Future<void> Function({required String memberUid, required bool makeAdmin}) onToggleRole;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final matches = project.members.where((m) => m.uid == currentUserUid);
    final ProjectMember? currentMember = matches.isNotEmpty ? matches.first : null;
    final isCurrentAdmin = (currentMember?.role ?? 'member') == 'admin';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PrimaryText(
            text: 'Members',
            size: 14,
            fontWeight: FontWeight.w700,
            color: AppPallete.secondary,
          ),
          const SizedBox(height: 8),
          for (final m in project.members) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: PrimaryText(
                      text: _memberInitials(m.name.isNotEmpty ? m.name : m.email),
                      size: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PrimaryText(
                          text: m.name.isNotEmpty ? m.name : m.email,
                          size: 14,
                          fontWeight: FontWeight.w600,
                          color: AppPallete.secondary,
                        ),
                        const SizedBox(height: 2),
                        PrimaryText(
                          text: m.uid == project.creatorUid
                              ? 'Owner'
                              : (m.role == 'admin' ? 'Admin' : 'Member'),
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: m.role == 'admin',
                    onChanged: (!isCurrentAdmin || m.uid == project.creatorUid)
                        ? null
                        : (val) {
                            onToggleRole(memberUid: m.uid, makeAdmin: val);
                          },
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _TaskFilters extends StatelessWidget {
  const _TaskFilters({required this.selected, required this.onChanged});

  final TaskStatusFilter selected;
  final ValueChanged<TaskStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.all),
            child: _FilterChip(
              label: 'All',
              selected: selected == TaskStatusFilter.all,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.todo),
            child: _FilterChip(
              label: 'To Do',
              selected: selected == TaskStatusFilter.todo,
              color: AppPallete.orange,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.inProgress),
            child: _FilterChip(
              label: 'In Progress',
              selected: selected == TaskStatusFilter.inProgress,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.done),
            child: _FilterChip(
              label: 'Done',
              selected: selected == TaskStatusFilter.done,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.color});

  final String label;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? color.withOpacity(0.5) : Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: PrimaryText(
        text: label,
        size: 12,
        fontWeight: FontWeight.w600,
        color: selected ? color : AppPallete.secondary,
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks});

  final List<_TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Center(
          child: PrimaryText(
            text: 'No tasks yet',
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final t in tasks) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: _priorityColor(t.priority).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.checklist,
                  color: _priorityColor(t.priority),
                  size: 25,
                ),
              ),
              title: PrimaryText(
                text: t.title,
                size: 16,
                fontWeight: FontWeight.w700,
                color: AppPallete.secondary,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrimaryText(
                      text: 'Assignee: ${t.assigneeName}',
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    if (t.dueDateLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: PrimaryText(
                          text: 'Due date: ${t.dueDateLabel}',
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              onTap: () {},
            ),
          ),
        ]
      ],
    );
  }

  // Status color kept for potential future use; currently priority drives the icon UI.

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.amber;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}

class _TaskItem {
  _TaskItem({
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.priority,
    required this.subTasks,
    required this.dueDate,
    this.status = TaskStatus.todo,
  });

  final String title;
  final String description;
  final String assigneeId;
  final String assigneeName;
  final TaskPriority priority;
  final List<String> subTasks;
  final DateTime? dueDate;
  final TaskStatus status;

  String get dueDateLabel {
    if (dueDate == null) return '';
    final d = dueDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

enum TaskPriority { low, medium, high }

enum TaskStatus { todo, inProgress, done }

enum TaskStatusFilter { all, todo, inProgress, done }

class _CreateTaskForm extends StatefulWidget {
  const _CreateTaskForm({required this.project, required this.onSubmit});

  final ProjectEntity project;
  final ValueChanged<_TaskItem> onSubmit;

  @override
  State<_CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends State<_CreateTaskForm> {
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
                  : 'Due date: ${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}',
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
    final task = _TaskItem(
      title: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      assigneeId: _assigneeId!,
      assigneeName: _assigneeName ?? 'User',
      priority: _priority,
      subTasks: subTasks,
      dueDate: _dueDate,
      status: TaskStatus.todo,
    );
    widget.onSubmit(task);
  }

}


String _memberInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  final first = parts.first.substring(0, 1);
  final last = parts.last.substring(0, 1);
  return (first + last).toUpperCase();
}

class _InviteRow {
  final TextEditingController emailCtrl = TextEditingController();
  bool makeAdmin = false;
  bool hasAccess = true;
}

