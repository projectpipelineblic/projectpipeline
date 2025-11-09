import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/presentation/pages/task_detail_page.dart';
import 'package:project_pipeline/features/projects/presentation/shared/task_types.dart';
import 'package:project_pipeline/features/projects/presentation/widgets/task_filters.dart' as filters;
import 'package:project_pipeline/features_web/projects/widgets/edit_project_dialog.dart';
import 'package:project_pipeline/features_web/projects/widgets/project_logs_dialog.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key, required this.project});

  final ProjectEntity project;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final List<TaskItem> _tasks = <TaskItem>[];
  filters.TaskStatusFilter _selectedFilter = filters.TaskStatusFilter.all;
  String? _selectedCustomStatusName; // For custom status filtering
  String? _filterAssigneeId;
  TaskPriority? _filterPriority;
  DateTime? _filterDueBefore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tasksSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projectSub;
  bool _showMembers = false;
  String? _currentUserUid;
  late ProjectEntity _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    
    print('🔍 [ProjectDetailPage] Initialized with project: ${_project.name}');
    print('🔍 [ProjectDetailPage] Project ID: ${_project.id}');
    print('🔍 [ProjectDetailPage] Custom statuses: ${_project.customStatuses?.length ?? 0}');
    if (_project.customStatuses != null) {
      for (var status in _project.customStatuses!) {
        print('  - ${status.name} (${status.colorHex})');
      }
    }
    
    _subscribeTasks();
    _subscribeToProject();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _projectSub?.cancel();
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

  void _subscribeToProject() {
    final projectId = widget.project.id;
    if (projectId == null) return;
    _projectSub?.cancel();
    _projectSub = FirebaseFirestore.instance
        .collection('Projects')
        .doc(projectId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        if (data != null) {
          print('🔍 [_subscribeToProject] Project data updated from Firestore');
          print('🔍 [_subscribeToProject] customStatuses in data: ${data['customStatuses']}');
          
          // Parse custom statuses
          List<CustomStatus>? parsedStatuses;
          if (data.containsKey('customStatuses') && data['customStatuses'] != null) {
            try {
              final statusesData = data['customStatuses'] as List<dynamic>;
              print('🔍 [_subscribeToProject] Parsing ${statusesData.length} custom statuses...');
              
              parsedStatuses = statusesData.map((s) {
                final statusMap = s as Map<String, dynamic>;
                return CustomStatus(
                  name: statusMap['name'] as String,
                  colorHex: statusMap['colorHex'] as String,
                );
              }).toList();
              
              print('✅ [_subscribeToProject] Parsed ${parsedStatuses.length} custom statuses');
            } catch (e) {
              print('❌ [_subscribeToProject] Error parsing custom statuses: $e');
              parsedStatuses = null;
            }
          } else {
            print('⚠️ [_subscribeToProject] No customStatuses in Firestore data');
          }
          
          setState(() {
            _project = ProjectEntity(
              id: snapshot.id,
              name: data['name'] as String? ?? '',
              description: data['description'] as String? ?? '',
              creatorUid: data['creatorUid'] as String? ?? '',
              creatorName: data['creatorName'] as String? ?? '',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              members: (data['members'] as List?)
                      ?.map((m) => ProjectMember(
                            uid: m['uid'] as String? ?? '',
                            email: m['email'] as String? ?? '',
                            name: m['name'] as String? ?? '',
                            role: m['role'] as String? ?? 'member',
                            hasAccess: m['hasAccess'] as bool? ?? true,
                          ))
                      .toList() ??
                  [],
              pendingInvites: (data['pendingInvites'] as List?)
                      ?.map((i) => ProjectInvite(
                            inviteId: i['inviteId'] as String? ?? '',
                            projectId: i['projectId'] as String? ?? '',
                            projectName: i['projectName'] as String? ?? '',
                            invitedUserUid: i['invitedUserUid'] as String? ?? '',
                            invitedUserEmail: i['invitedUserEmail'] as String? ?? '',
                            creatorUid: i['creatorUid'] as String? ?? '',
                            creatorName: i['creatorName'] as String? ?? '',
                            createdAt: (i['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                            role: i['role'] as String? ?? 'member',
                            hasAccess: i['hasAccess'] as bool? ?? true,
                            status: i['status'] as String? ?? 'pending',
                          ))
                      .toList() ??
                  [],
              customStatuses: parsedStatuses,
            );
            
            print('✅ [_subscribeToProject] Project updated with ${parsedStatuses?.length ?? 0} custom statuses');
          });
        }
      }
    });
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
        return TaskItem(
          id: data['id'] as String? ?? d.id,
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          assigneeId: data['assigneeId'] as String? ?? '',
          assigneeName: data['assigneeName'] as String? ?? '',
          priority: _priorityFromString(data['priority'] as String? ?? 'medium'),
          subTasks: (data['subTasks'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
          dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
          status: _statusFromString(data['status'] as String? ?? 'todo'),
          statusName: data['statusName'] as String?,
          timeSpentMinutes: data['timeSpentMinutes'] as int? ?? 0,
          startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
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
        title: PrimaryText(
          text: _project.name,
          size: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE5E7EB)
              : AppPallete.secondary,
        ),
        actions: [
          if (isWeb)
            IconButton(
              tooltip: 'View Logs',
              onPressed: _showLogsDialog,
              icon: const Icon(Icons.history_outlined),
              color: AppPallete.primary,
            ),
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
              isWeb: isWeb,
              isDark: isDark,
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
            
            // Analytics Section (Web Only)
            if (isWeb) ...[
              _ProjectAnalytics(
                projectId: _project.id ?? '',
                project: _project,
                tasks: _tasks,
                members: _project.members,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ],
            
            Row(
              children: [
                IconButton(
                  tooltip: 'Filter',
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.filter_list),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE5E7EB)
                      : AppPallete.secondary,
                ),
                const SizedBox(width: 4),
                const _SectionTitle(title: 'Tasks'),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                print('🔍 [ProjectDetail] Rendering filters for project: ${_project.name}');
                print('🔍 [ProjectDetail] Custom statuses count: ${_project.customStatuses?.length ?? 0}');
                if (_project.customStatuses != null) {
                  for (var status in _project.customStatuses!) {
                    print('  - ${status.name} (${status.colorHex})');
                  }
                }
                
                return filters.TaskFilters(
                  selected: _selectedFilter,
                  onChanged: (f) => setState(() => _selectedFilter = f),
                  customStatuses: _project.customStatuses,
                  selectedStatusName: _selectedCustomStatusName,
                  onStatusNameChanged: (name) {
                    setState(() {
                      _selectedCustomStatusName = name;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            _TaskList(
              tasks: _filteredTasks(),
              projectId: _project.id,
              project: _project,
              isWeb: isWeb,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  List<TaskItem> _filteredTasks() {
    Iterable<TaskItem> it = _tasks;
    
    // Handle custom status filtering
    if (_selectedFilter == filters.TaskStatusFilter.custom && _selectedCustomStatusName != null) {
      print('🔍 [_filteredTasks] Filtering by custom statusName: $_selectedCustomStatusName');
      
      // Filter by exact statusName match
      it = it.where((t) => t.statusName == _selectedCustomStatusName);
      
      print('  -> Found ${it.length} tasks with statusName: $_selectedCustomStatusName');
    } else {
      // Handle standard enum filtering
      switch (_selectedFilter) {
        case filters.TaskStatusFilter.all:
          break;
        case filters.TaskStatusFilter.todo:
          it = it.where((t) => t.status == TaskStatus.todo && t.statusName == null);
          break;
        case filters.TaskStatusFilter.inProgress:
          it = it.where((t) => t.status == TaskStatus.inProgress && t.statusName == null);
          break;
        case filters.TaskStatusFilter.done:
          it = it.where((t) => t.status == TaskStatus.done && t.statusName == null);
          break;
        case filters.TaskStatusFilter.custom:
          // Custom filter without name - show all
          break;
      }
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
      backgroundColor: Theme.of(context).dialogBackgroundColor,
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

  Future<void> _createTaskInFirestore(TaskItem task) async {
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
      'statusName': task.statusName, // Save custom status name
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
    try {
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
      
      // Update local state immediately
      if (!mounted) return;
      final updatedMembers = _project.members.map((member) {
        if (member.uid == memberUid) {
          return ProjectMember(
            uid: member.uid,
            email: member.email,
            name: member.name,
            role: makeAdmin ? 'admin' : 'member',
            hasAccess: member.hasAccess,
          );
        }
        return member;
      }).toList();
      
      setState(() {
        _project = ProjectEntity(
          id: _project.id,
          name: _project.name,
          description: _project.description,
          creatorUid: _project.creatorUid,
          creatorName: _project.creatorName,
          createdAt: _project.createdAt,
          members: updatedMembers,
          pendingInvites: _project.pendingInvites,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role: $e')),
      );
    }
  }

  Future<void> _openEditProjectSheet() async {
    // Use dialog on web, bottom sheet on mobile
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => EditProjectDialog(project: _project),
      );
      return;
    }
    
    // Mobile bottom sheet
    final nameCtrl = TextEditingController(text: _project.name);
    final descCtrl = TextEditingController(text: _project.description);
    final List<_InviteRow> inviteRows = <_InviteRow>[];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
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
                  PrimaryText(
                    text: 'Edit Project',
                    size: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE5E7EB)
                        : AppPallete.secondary,
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
                      Expanded(
                        child: PrimaryText(
                          text: 'Add members (optional)',
                          size: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE5E7EB)
                              : AppPallete.secondary,
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

  void _showLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => ProjectLogsDialog(project: _project),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
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
                PrimaryText(
                  text: 'Filter tasks',
                  size: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE5E7EB)
                      : AppPallete.secondary,
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE5E7EB)
                              : AppPallete.secondary,
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
  const _ProjectHeader({
    required this.project,
    this.onMembersTap,
    this.isWeb = false,
    this.isDark = false,
  });

  final ProjectEntity project;
  final VoidCallback? onMembersTap;
  final bool isWeb;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Web-optimized card colors
    final cardColor = isWeb
      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
      : Theme.of(context).cardTheme.color;
    
    final borderColor = isWeb
      ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
      : Theme.of(context).dividerColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        color: cardColor,
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
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFE5E7EB)
          : AppPallete.secondary,
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
    final isCurrentUserOwner = currentUserUid == project.creatorUid;
    final canEditRoles = isCurrentAdmin || isCurrentUserOwner;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimaryText(
            text: 'Members',
            size: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFE5E7EB)
                : AppPallete.secondary,
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE5E7EB)
                              : AppPallete.secondary,
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
                    onChanged: (!canEditRoles || m.uid == project.creatorUid)
                        ? null
                        : (val) async {
                            await onToggleRole(memberUid: m.uid, makeAdmin: val);
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


class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.tasks,
    this.projectId,
    this.project,
    this.isWeb = false,
    this.isDark = false,
  });

  final List<TaskItem> tasks;
  final String? projectId;
  final ProjectEntity? project;
  final bool isWeb;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Web-optimized colors
    final cardColor = isWeb
      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
      : Theme.of(context).cardTheme.color;
    
    final borderColor = isWeb
      ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
      : Theme.of(context).dividerColor;
    
    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
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
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: isWeb ? [
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ] : [
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
                  color: _statusColor(t).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.checklist,
                  color: _statusColor(t),
                  size: 25,
                ),
              ),
              title: PrimaryText(
                text: t.title,
                size: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFE5E7EB)
                    : AppPallete.secondary,
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
                    const SizedBox(height: 6),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(t).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _statusColor(t).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _statusColor(t),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          PrimaryText(
                            text: t.statusName ?? _statusLabel(t.status),
                            size: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(t),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskDetailPage(
                      task: t,
                      projectId: projectId ?? '',
                      project: project,
                    ),
                  ),
                );
              },
            ),
          ),
        ]
      ],
    );
  }

  // Get color based on task status (custom statuses or default)
  Color _statusColor(TaskItem task) {
    // If task has a custom statusName and project has custom statuses, find the matching color
    if (task.statusName != null && project?.customStatuses != null) {
      final matchingStatus = project!.customStatuses!.firstWhere(
        (status) => status.name == task.statusName,
        orElse: () => project!.customStatuses!.first,
      );
      
      // Parse hex color
      final hexColor = matchingStatus.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    
    // Fall back to default status colors
    switch (task.status) {
      case TaskStatus.todo:
        return const Color(0xFFF59E0B); // Amber
      case TaskStatus.inProgress:
        return const Color(0xFF8B5CF6); // Purple
      case TaskStatus.done:
        return const Color(0xFF10B981); // Green
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}

// TaskItem and enums are now in shared/task_types.dart


class _CreateTaskForm extends StatefulWidget {
  const _CreateTaskForm({required this.project, required this.onSubmit});

  final ProjectEntity project;
  final ValueChanged<TaskItem> onSubmit;

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
              Expanded(
                child: PrimaryText(
                  text: 'Create Task',
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFE5E7EB)
                  : AppPallete.secondary,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryText(
            text: 'Sub tasks',
            size: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFE5E7EB)
                : AppPallete.secondary,
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
    final task = TaskItem(
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


// Analytics Widget for Project Detail Page
class _ProjectAnalytics extends StatelessWidget {
  final String projectId;
  final ProjectEntity project;
  final List<TaskItem> tasks;
  final List<ProjectMember> members;
  final bool isDark;

  const _ProjectAnalytics({
    required this.projectId,
    required this.project,
    required this.tasks,
    required this.members,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final totalTasks = tasks.length;
    
    // Use custom statuses if available
    final customStatuses = project.customStatuses;
    final hasCustomStatuses = customStatuses != null && customStatuses.isNotEmpty;
    
    // Count tasks by status
    Map<String, int> statusCounts = {};
    Map<String, Color> statusColors = {};
    Map<String, IconData> statusIcons = {};
    
    if (hasCustomStatuses) {
      // Use custom statuses
      for (var status in customStatuses) {
        final count = tasks.where((t) => t.statusName == status.name).length;
        statusCounts[status.name] = count;
        
        // Parse color
        try {
          final hexColor = status.colorHex.replaceAll('#', '');
          statusColors[status.name] = Color(int.parse('FF$hexColor', radix: 16));
        } catch (e) {
          statusColors[status.name] = const Color(0xFF6366F1);
        }
        
        // Assign icon based on status name
        if (status.name.toLowerCase().contains('done') || 
            status.name.toLowerCase().contains('complete')) {
          statusIcons[status.name] = Icons.check_circle;
        } else if (status.name.toLowerCase().contains('progress')) {
          statusIcons[status.name] = Icons.pending;
        } else if (status.name.toLowerCase().contains('review')) {
          statusIcons[status.name] = Icons.rate_review;
        } else {
          statusIcons[status.name] = Icons.radio_button_unchecked;
        }
      }
    } else {
      // Use default statuses
      final completedTasks = tasks.where((t) => t.status == TaskStatus.done).length;
      final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress).length;
      final todoTasks = tasks.where((t) => t.status == TaskStatus.todo).length;
      
      statusCounts = {
        'To Do': todoTasks,
        'In Progress': inProgressTasks,
        'Done': completedTasks,
      };
      statusColors = {
        'To Do': const Color(0xFFF59E0B),
        'In Progress': const Color(0xFF8B5CF6),
        'Done': const Color(0xFF10B981),
      };
      statusIcons = {
        'To Do': Icons.radio_button_unchecked,
        'In Progress': Icons.pending,
        'Done': Icons.check_circle,
      };
    }
    
    final highPriority = tasks.where((t) => t.priority == TaskPriority.high).length;
    final mediumPriority = tasks.where((t) => t.priority == TaskPriority.medium).length;
    final lowPriority = tasks.where((t) => t.priority == TaskPriority.low).length;
    
    // Calculate completion (last status or 'done' status)
    final lastStatusName = hasCustomStatuses ? customStatuses.last.name : 'Done';
    final completedCount = hasCustomStatuses
        ? tasks.where((t) => t.statusName == lastStatusName).length
        : tasks.where((t) => t.status == TaskStatus.done).length;
    final progress = totalTasks > 0 ? (completedCount / totalTasks) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF6366F1),
                size: 24,
              ),
              const Gap(12),
              Text(
                'Project Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Gap(24),
          
          // Stats Row - Dynamic based on custom statuses
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Total Tasks (always shown)
              SizedBox(
                width: (MediaQuery.of(context).size.width - 120) / (statusCounts.length + 1),
                child: _AnalyticCard(
                  label: 'Total Tasks',
                  value: totalTasks.toString(),
                  icon: Icons.task_alt,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              // Custom or default statuses
              ...statusCounts.entries.map((entry) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 120) / (statusCounts.length + 1),
                  child: _AnalyticCard(
                    label: entry.key,
                    value: entry.value.toString(),
                    icon: statusIcons[entry.key] ?? Icons.circle,
                    color: statusColors[entry.key] ?? const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                );
              }),
            ],
          ),
          const Gap(24),
          
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          const Gap(24),
          
          // Priority Breakdown
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'By Priority',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const Gap(12),
                    _PriorityBar(
                      label: 'High',
                      count: highPriority,
                      total: totalTasks,
                      color: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                    const Gap(8),
                    _PriorityBar(
                      label: 'Medium',
                      count: mediumPriority,
                      total: totalTasks,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                    const Gap(8),
                    _PriorityBar(
                      label: 'Low',
                      count: lowPriority,
                      total: totalTasks,
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const Gap(24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Activity',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const Gap(12),
                    ...members.map((member) {
                      final memberTasks = tasks.where((t) => t.assigneeId == member.uid).toList();
                      
                      return _MemberActivityCard(
                        member: member,
                        memberTasks: memberTasks,
                        isDark: isDark,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _AnalyticCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const Gap(8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberActivityCard extends StatefulWidget {
  final ProjectMember member;
  final List<TaskItem> memberTasks;
  final bool isDark;

  const _MemberActivityCard({
    required this.member,
    required this.memberTasks,
    required this.isDark,
  });

  @override
  State<_MemberActivityCard> createState() => _MemberActivityCardState();
}

class _MemberActivityCardState extends State<_MemberActivityCard> {
  bool _isExpanded = false;
  Map<String, int> _currentTimeMinutes = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Initialize time for in-progress tasks
    for (var task in widget.memberTasks) {
      if (task.status == TaskStatus.inProgress) {
        _currentTimeMinutes[task.id] = task.timeSpentMinutes;
      }
    }
    
    // Start timer for in-progress tasks
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          for (var task in widget.memberTasks) {
            if (task.status == TaskStatus.inProgress && task.startedAt != null) {
              final elapsed = DateTime.now().difference(task.startedAt!);
              _currentTimeMinutes[task.id] = task.timeSpentMinutes + elapsed.inMinutes;
            }
          }
        });
      }
    });
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else if (minutes < 1440) {
      final hours = (minutes / 60).floor();
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    } else {
      final days = (minutes / 1440).floor();
      final hours = ((minutes % 1440) / 60).floor();
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.done:
        return const Color(0xFF10B981);
      case TaskStatus.inProgress:
        return const Color(0xFF8B5CF6);
      case TaskStatus.todo:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = widget.memberTasks.where((t) => t.status == TaskStatus.done).length;
    final totalTasks = widget.memberTasks.length;
    final currentTask = widget.memberTasks.where((t) => t.status == TaskStatus.inProgress).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark 
          ? const Color(0xFF0F172A) 
          : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDark 
            ? const Color(0xFF334155) 
            : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Header (Clickable)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                    child: Text(
                      _memberInitials(widget.member.name),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.member.role == 'admin'
                                  ? const Color(0xFF8B5CF6).withOpacity(0.1)
                                  : const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.member.role == 'admin' ? 'Admin' : 'Member',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: widget.member.role == 'admin'
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF6366F1),
                                ),
                              ),
                            ),
                            const Gap(8),
                            Text(
                              '$completedTasks/$totalTasks tasks',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: widget.isDark 
                                  ? const Color(0xFF94A3B8) 
                                  : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.isDark 
                      ? const Color(0xFF94A3B8) 
                      : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          
          // Current Task (Always visible if exists)
          if (currentTask != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    size: 16,
                    color: Color(0xFF8B5CF6),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Currently Working On',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                        const Gap(2),
                        Text(
                          currentTask.title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  // Time tracking display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                        const Gap(4),
                        Text(
                          _formatTime(_currentTimeMinutes[currentTask.id] ?? currentTask.timeSpentMinutes),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
          ],
          
          // Expanded Task List
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Assigned Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark 
                        ? const Color(0xFF94A3B8) 
                        : const Color(0xFF64748B),
                    ),
                  ),
                  const Gap(12),
                  // Filter out the current task from the list if shown above
                  ...(() {
                    final tasksToShow = currentTask != null
                        ? widget.memberTasks.where((t) => t.id != currentTask.id).toList()
                        : widget.memberTasks;
                    
                    if (tasksToShow.isEmpty && widget.memberTasks.isNotEmpty) {
                      // Only has the current task
                      return [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Only working on the task above',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: widget.isDark 
                                ? const Color(0xFF64748B) 
                                : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ];
                    }
                    
                    if (tasksToShow.isEmpty) {
                      // No tasks at all
                      return [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'No tasks assigned',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: widget.isDark 
                                ? const Color(0xFF64748B) 
                                : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ];
                    }
                    
                    return tasksToShow.map((task) {
                      final statusColor = _getStatusColor(task.status);
                      
                      return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.isDark 
                          ? const Color(0xFF334155).withOpacity(0.3)
                          : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                                    decoration: task.status == TaskStatus.done 
                                      ? TextDecoration.lineThrough 
                                      : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    task.statusName ?? task.status.toString().split('.').last,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    }).toList();
                  })(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final bool isDark;

  const _PriorityBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        const Gap(8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const Gap(8),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
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

