import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/features/projects/domain/entities/task_entity.dart';

abstract class TaskRemoteDataSource {
  Stream<List<TaskEntity>> streamTasks({required String projectId});
  Future<List<TaskEntity>> getUserTasks({required String userId});
  Future<void> createTask({required TaskEntity task});
  Future<void> updateTaskStatus({required String projectId, required String taskId, required TaskStatus status});
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FirebaseFirestore _firestore;
  TaskRemoteDataSourceImpl({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<TaskEntity>> streamTasks({required String projectId}) {
    return _firestore
        .collection('Projects')
        .doc(projectId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Future<List<TaskEntity>> getUserTasks({required String userId}) async {
    final projectsSnapshot = await _firestore.collection('Projects').get();
    final List<TaskEntity> allUserTasks = [];

    for (var projectDoc in projectsSnapshot.docs) {
      final tasksSnapshot = await _firestore
          .collection('Projects')
          .doc(projectDoc.id)
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .get();
      
      allUserTasks.addAll(tasksSnapshot.docs.map(_fromDoc));
    }

    // Sort by due date and created date
    allUserTasks.sort((a, b) {
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    return allUserTasks;
  }

  @override
  Future<void> createTask({required TaskEntity task}) async {
    final col = _firestore.collection('Projects').doc(task.projectId).collection('tasks');
    final doc = col.doc(task.id.isEmpty ? null : task.id);
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

  @override
  Future<void> updateTaskStatus({required String projectId, required String taskId, required TaskStatus status}) async {
    await _firestore
        .collection('Projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({'status': _statusToString(status), 'updatedAt': FieldValue.serverTimestamp()});
  }

  TaskEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    return TaskEntity(
      id: data['id'] as String? ?? d.id,
      projectId: d.reference.parent.parent!.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      assigneeId: data['assigneeId'] as String? ?? '',
      assigneeName: data['assigneeName'] as String? ?? '',
      priority: _priorityFromString(data['priority'] as String? ?? 'medium'),
      subTasks: (data['subTasks'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      status: _statusFromString(data['status'] as String? ?? 'todo'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
}


