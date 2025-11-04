import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_app/features/projects/data/models/project_model.dart';
import 'package:task_app/features/projects/domain/entities/project_entity.dart';
import 'package:task_app/features/projects/domain/repositories/project_repository.dart';

abstract class ProjectRemoteDatasource {
  Future<ProjectEntity> createProject({
    required String name,
    required String description,
    required String creatorUid,
    required String creatorName,
    required List<Map<String, dynamic>> teamMembers,
  });

  Future<List<ProjectEntity>> getProjects(String userId);

  Future<List<ProjectEntity>> getOpenProjects(String userId);

  Future<UserInfo> findUserByEmail(String email);

  Future<void> sendTeamInvite({
    required String projectId,
    required String invitedUserUid,
    required String invitedUserEmail,
    required String creatorUid,
    required String creatorName,
    required String projectName,
    required String role,
    required bool hasAccess,
  });

  Future<List<ProjectInvite>> getInvites(String userId);

  Future<void> acceptInvite(String inviteId);

  Future<void> rejectInvite(String inviteId);
}

class ProjectRemoteDatasourceImpl implements ProjectRemoteDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ProjectEntity> createProject({
    required String name,
    required String description,
    required String creatorUid,
    required String creatorName,
    required List<Map<String, dynamic>> teamMembers,
  }) async {
    try {
      final projectRef = _firestore.collection('Projects').doc();
      final projectId = projectRef.id;
      final now = DateTime.now();

      // Get creator email from Users collection
      final creatorDoc = await _firestore.collection('Users').doc(creatorUid).get();
      final creatorEmail = creatorDoc.exists
          ? (creatorDoc.data()?['email'] as String? ?? '')
          : '';

      // Create members list with creator as admin
      final List<Map<String, dynamic>> membersList = [
        {
          'uid': creatorUid,
          'email': creatorEmail,
          'name': creatorName,
          'role': 'admin',
          'hasAccess': true,
        },
      ];

      // Process team members and send invites
      final List<ProjectInviteModel> pendingInvites = [];
      for (final member in teamMembers) {
        final email = member['email'] as String;
        final role = member['role'] as String;
        final hasAccess = member['hasAccess'] as bool;

        // Find user by email
        final userQuery = await _firestore
            .collection('Users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first;
          final userUid = userDoc.id;

          // Create invite
          final inviteRef = _firestore.collection('TeamInvites').doc();
          final inviteId = inviteRef.id;

          await inviteRef.set({
            'inviteId': inviteId,
            'projectId': projectId,
            'projectName': name,
            'invitedUserUid': userUid,
            'invitedUserEmail': email,
            'creatorUid': creatorUid,
            'creatorName': creatorName,
            'createdAt': Timestamp.fromDate(now),
            'role': role,
            'hasAccess': hasAccess,
            'status': 'pending',
          });

          pendingInvites.add(ProjectInviteModel(
            inviteId: inviteId,
            projectId: projectId,
            projectName: name,
            invitedUserUid: userUid,
            invitedUserEmail: email,
            creatorUid: creatorUid,
            creatorName: creatorName,
            createdAt: now,
            role: role,
            hasAccess: hasAccess,
            status: 'pending',
          ));
        }
      }

      // Create project
      final projectModel = ProjectModel(
        id: projectId,
        name: name,
        description: description,
        creatorUid: creatorUid,
        creatorName: creatorName,
        createdAt: now,
        members: membersList
            .map((m) => ProjectMemberModel(
                  uid: m['uid'] as String,
                  email: m['email'] as String,
                  name: m['name'] as String,
                  role: m['role'] as String,
                  hasAccess: m['hasAccess'] as bool,
                ))
            .toList(),
        pendingInvites: pendingInvites,
      );

      await projectRef.set({
        'id': projectId,
        'name': name,
        'description': description,
        'creatorUid': creatorUid,
        'creatorName': creatorName,
        'createdAt': Timestamp.fromDate(now),
        'members': membersList,
        'pendingInvites': pendingInvites.map((i) => i.toJson()).toList(),
      });

      return projectModel;
    } catch (e) {
      throw Exception('Error creating project: $e');
    }
  }

  @override
  Future<List<ProjectEntity>> getProjects(String userId) async {
    try {
      // Get all projects and filter client-side since Firestore doesn't support
      // array-contains queries on nested fields easily
      final projectsQuery = await _firestore.collection('Projects').get();

      final projects = projectsQuery.docs
          .where((doc) {
            final data = doc.data();
            final members = data['members'] as List<dynamic>? ?? [];
            return members.any((m) =>
                m is Map<String, dynamic> && m['uid'] == userId);
          })
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ProjectModel.fromJson(data);
          })
          .toList();

      return projects;
    } catch (e) {
      throw Exception('Error getting projects: $e');
    }
  }

  @override
  Future<List<ProjectEntity>> getOpenProjects(String userId) async {
    try {
      // Get all projects where user is a member
      final projectsQuery = await _firestore.collection('Projects').get();

      final userProjects = projectsQuery.docs.where((doc) {
        final data = doc.data();
        final members = data['members'] as List<dynamic>? ?? [];
        return members.any((m) =>
            m is Map<String, dynamic> && m['uid'] == userId);
      }).toList();

      // Filter projects that have incomplete tasks
      final List<ProjectEntity> openProjects = [];

      for (var projectDoc in userProjects) {
        final tasksSnapshot = await _firestore
            .collection('Projects')
            .doc(projectDoc.id)
            .collection('tasks')
            .where('status', whereIn: ['todo', 'inProgress'])
            .limit(1)
            .get();

        if (tasksSnapshot.docs.isNotEmpty) {
          final data = projectDoc.data();
          data['id'] = projectDoc.id;
          openProjects.add(ProjectModel.fromJson(data));
        }
      }

      return openProjects;
    } catch (e) {
      throw Exception('Error getting open projects: $e');
    }
  }

  @override
  Future<UserInfo> findUserByEmail(String email) async {
    try {
      final userQuery = await _firestore
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found');
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();

      return UserInfo(
        uid: userDoc.id,
        email: email,
        name: userData['userName'] as String? ?? email,
      );
    } catch (e) {
      throw Exception('Error finding user: $e');
    }
  }

  @override
  Future<void> sendTeamInvite({
    required String projectId,
    required String invitedUserUid,
    required String invitedUserEmail,
    required String creatorUid,
    required String creatorName,
    required String projectName,
    required String role,
    required bool hasAccess,
  }) async {
    try {
      final inviteRef = _firestore.collection('TeamInvites').doc();
      final inviteId = inviteRef.id;

      await inviteRef.set({
        'inviteId': inviteId, // Store inviteId in document for reference
        'projectId': projectId,
        'projectName': projectName,
        'invitedUserUid': invitedUserUid,
        'invitedUserEmail': invitedUserEmail,
        'creatorUid': creatorUid,
        'creatorName': creatorName,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'role': role,
        'hasAccess': hasAccess,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Error sending invite: $e');
    }
  }

  @override
  Future<List<ProjectInvite>> getInvites(String userId) async {
    try {
      final invitesQuery = await _firestore
          .collection('TeamInvites')
          .where('invitedUserUid', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return invitesQuery.docs.map((doc) {
        final data = doc.data();
        data['inviteId'] = doc.id; // Use document ID as inviteId
        return ProjectInviteModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error getting invites: $e');
    }
  }

  @override
  Future<void> acceptInvite(String inviteId) async {
    try {
      final inviteDoc = await _firestore.collection('TeamInvites').doc(inviteId).get();
      if (!inviteDoc.exists) {
        throw Exception('Invite not found');
      }

      final inviteData = inviteDoc.data()!;
      final projectId = inviteData['projectId'] as String;
      final invitedUserUid = inviteData['invitedUserUid'] as String;
      final role = inviteData['role'] as String;
      final hasAccess = inviteData['hasAccess'] as bool;

      // Get user info
      final userDoc = await _firestore.collection('Users').doc(invitedUserUid).get();
      final userData = userDoc.data()!;
      final email = userData['email'] as String;
      final name = userData['userName'] as String? ?? email;

      // Update invite status
      await _firestore.collection('TeamInvites').doc(inviteId).update({
        'status': 'accepted',
      });

      // Add member to project
      final projectDoc = await _firestore.collection('Projects').doc(projectId).get();
      if (projectDoc.exists) {
        final projectData = projectDoc.data()!;
        final members = List<Map<String, dynamic>>.from(projectData['members'] as List);

        members.add({
          'uid': invitedUserUid,
          'email': email,
          'name': name,
          'role': role,
          'hasAccess': hasAccess,
        });

        // Remove from pending invites
        final pendingInvites =
            List<Map<String, dynamic>>.from(projectData['pendingInvites'] as List? ?? []);
        pendingInvites.removeWhere((invite) => invite['inviteId'] == inviteId);

        await _firestore.collection('Projects').doc(projectId).update({
          'members': members,
          'pendingInvites': pendingInvites,
        });
      }
    } catch (e) {
      throw Exception('Error accepting invite: $e');
    }
  }

  @override
  Future<void> rejectInvite(String inviteId) async {
    try {
      await _firestore.collection('TeamInvites').doc(inviteId).update({
        'status': 'rejected',
      });
    } catch (e) {
      throw Exception('Error rejecting invite: $e');
    }
  }
}

