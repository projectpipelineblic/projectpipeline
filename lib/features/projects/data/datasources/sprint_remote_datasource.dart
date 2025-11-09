import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/features/projects/data/models/sprint_model.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';

abstract class SprintRemoteDataSource {
  /// Get all sprints for a project
  Future<List<SprintEntity>> getSprints(String projectId);
  
  /// Stream sprints for real-time updates
  Stream<List<SprintEntity>> streamSprints(String projectId);
  
  /// Get a single sprint by ID
  Future<SprintEntity> getSprint(String projectId, String sprintId);
  
  /// Create a new sprint
  Future<String> createSprint(SprintEntity sprint);
  
  /// Update an existing sprint
  Future<void> updateSprint(SprintEntity sprint);
  
  /// Delete a sprint
  Future<void> deleteSprint(String projectId, String sprintId);
  
  /// Start a sprint (change status to active)
  Future<void> startSprint(String projectId, String sprintId);
  
  /// Complete a sprint (change status to completed)
  Future<void> completeSprint(String projectId, String sprintId);
  
  /// Get the active sprint for a project
  Future<SprintEntity?> getActiveSprint(String projectId);
}

class SprintRemoteDataSourceImpl implements SprintRemoteDataSource {
  final FirebaseFirestore firestore;

  SprintRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _getSprintsCollection(String projectId) {
    return firestore.collection('Projects').doc(projectId).collection('sprints');
  }

  @override
  Future<List<SprintEntity>> getSprints(String projectId) async {
    final snapshot = await _getSprintsCollection(projectId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SprintModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }))
        .toList();
  }

  @override
  Stream<List<SprintEntity>> streamSprints(String projectId) {
    return _getSprintsCollection(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SprintModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }))
            .toList());
  }

  @override
  Future<SprintEntity> getSprint(String projectId, String sprintId) async {
    final doc = await _getSprintsCollection(projectId).doc(sprintId).get();

    if (!doc.exists) {
      throw Exception('Sprint not found');
    }

    return SprintModel.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    });
  }

  @override
  Future<String> createSprint(SprintEntity sprint) async {
    final sprintModel = SprintModel.fromEntity(sprint);
    final docRef = _getSprintsCollection(sprint.projectId).doc();
    
    final data = sprintModel.toJson();
    data['id'] = docRef.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);
    
    return docRef.id;
  }

  @override
  Future<void> updateSprint(SprintEntity sprint) async {
    final sprintModel = SprintModel.fromEntity(sprint);
    final data = sprintModel.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _getSprintsCollection(sprint.projectId).doc(sprint.id).update(data);
  }

  @override
  Future<void> deleteSprint(String projectId, String sprintId) async {
    await _getSprintsCollection(projectId).doc(sprintId).delete();
  }

  @override
  Future<void> startSprint(String projectId, String sprintId) async {
    // First, check if there's already an active sprint
    final activeSprint = await getActiveSprint(projectId);
    if (activeSprint != null) {
      throw Exception('Cannot start sprint: Another sprint is already active');
    }

    await _getSprintsCollection(projectId).doc(sprintId).update({
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> completeSprint(String projectId, String sprintId) async {
    await _getSprintsCollection(projectId).doc(sprintId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<SprintEntity?> getActiveSprint(String projectId) async {
    final snapshot = await _getSprintsCollection(projectId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return SprintModel.fromJson({
      ...snapshot.docs.first.data() as Map<String, dynamic>,
      'id': snapshot.docs.first.id,
    });
  }
}

