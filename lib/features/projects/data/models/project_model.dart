import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  ProjectModel({
    super.id,
    required super.name,
    required super.description,
    required super.creatorUid,
    required super.creatorName,
    required super.createdAt,
    required super.members,
    required super.pendingInvites,
    super.customStatuses,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    print('🔍 [ProjectModel.fromJson] Parsing project: ${json['name']}');
    print('🔍 [ProjectModel.fromJson] Raw customStatuses from JSON: ${json['customStatuses']}');
    print('🔍 [ProjectModel.fromJson] customStatuses type: ${json['customStatuses']?.runtimeType}');
    
    List<CustomStatusModel>? parsedStatuses;
    if (json.containsKey('customStatuses') && json['customStatuses'] != null) {
      try {
        final statusesData = json['customStatuses'] as List<dynamic>;
        print('🔍 [ProjectModel.fromJson] Parsing ${statusesData.length} statuses...');
        
        parsedStatuses = statusesData.map((s) {
          final statusMap = s as Map<String, dynamic>;
          print('  - Parsing status: ${statusMap['name']} (${statusMap['colorHex']})');
          return CustomStatusModel.fromJson(statusMap);
        }).toList();
        
        print('✅ [ProjectModel.fromJson] Successfully parsed ${parsedStatuses.length} custom statuses');
      } catch (e) {
        print('❌ [ProjectModel.fromJson] Error parsing custom statuses: $e');
        parsedStatuses = null;
      }
    } else {
      print('⚠️ [ProjectModel.fromJson] No customStatuses field in JSON');
    }
    
    return ProjectModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      creatorUid: json['creatorUid'] as String,
      creatorName: json['creatorName'] as String,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => ProjectMemberModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      pendingInvites: (json['pendingInvites'] as List<dynamic>?)
              ?.map((i) => ProjectInviteModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      customStatuses: parsedStatuses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorUid': creatorUid,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'members': members.map((m) => (m as ProjectMemberModel).toJson()).toList(),
      'pendingInvites': pendingInvites
          .map((i) => (i as ProjectInviteModel).toJson())
          .toList(),
      if (customStatuses != null)
        'customStatuses': customStatuses!
            .map((s) => (s as CustomStatusModel).toJson())
            .toList(),
    };
  }
}

class ProjectMemberModel extends ProjectMember {
  ProjectMemberModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.role,
    required super.hasAccess,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      hasAccess: json['hasAccess'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'hasAccess': hasAccess,
    };
  }
}

class ProjectInviteModel extends ProjectInvite {
  ProjectInviteModel({
    required super.inviteId,
    required super.projectId,
    required super.projectName,
    required super.invitedUserUid,
    required super.invitedUserEmail,
    required super.creatorUid,
    required super.creatorName,
    required super.createdAt,
    required super.role,
    required super.hasAccess,
    required super.status,
  });

  factory ProjectInviteModel.fromJson(Map<String, dynamic> json) {
    return ProjectInviteModel(
      inviteId: json['inviteId'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      invitedUserUid: json['invitedUserUid'] as String,
      invitedUserEmail: json['invitedUserEmail'] as String,
      creatorUid: json['creatorUid'] as String,
      creatorName: json['creatorName'] as String,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      role: json['role'] as String,
      hasAccess: json['hasAccess'] as bool,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inviteId': inviteId,
      'projectId': projectId,
      'projectName': projectName,
      'invitedUserUid': invitedUserUid,
      'invitedUserEmail': invitedUserEmail,
      'creatorUid': creatorUid,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': role,
      'hasAccess': hasAccess,
      'status': status,
    };
  }
}

class CustomStatusModel extends CustomStatus {
  const CustomStatusModel({
    required super.name,
    required super.colorHex,
  });

  factory CustomStatusModel.fromJson(Map<String, dynamic> json) {
    return CustomStatusModel(
      name: json['name'] as String,
      colorHex: json['colorHex'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'colorHex': colorHex,
    };
  }
}
