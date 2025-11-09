import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';

class SprintModel extends SprintEntity {
  const SprintModel({
    required super.id,
    required super.projectId,
    required super.name,
    super.goal,
    required super.startDate,
    required super.endDate,
    required super.status,
    super.totalStoryPoints,
    super.completedStoryPoints,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
  });

  factory SprintModel.fromJson(Map<String, dynamic> json) {
    return SprintModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      goal: json['goal'] as String?,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      status: _statusFromString(json['status'] as String),
      totalStoryPoints: json['totalStoryPoints'] as int? ?? 0,
      completedStoryPoints: json['completedStoryPoints'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'goal': goal,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': _statusToString(status),
      'totalStoryPoints': totalStoryPoints,
      'completedStoryPoints': completedStoryPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  factory SprintModel.fromEntity(SprintEntity entity) {
    return SprintModel(
      id: entity.id,
      projectId: entity.projectId,
      name: entity.name,
      goal: entity.goal,
      startDate: entity.startDate,
      endDate: entity.endDate,
      status: entity.status,
      totalStoryPoints: entity.totalStoryPoints,
      completedStoryPoints: entity.completedStoryPoints,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }

  SprintModel copyWith({
    String? id,
    String? projectId,
    String? name,
    String? goal,
    DateTime? startDate,
    DateTime? endDate,
    SprintStatus? status,
    int? totalStoryPoints,
    int? completedStoryPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return SprintModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      totalStoryPoints: totalStoryPoints ?? this.totalStoryPoints,
      completedStoryPoints: completedStoryPoints ?? this.completedStoryPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  static SprintStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
        return SprintStatus.planning;
      case 'active':
        return SprintStatus.active;
      case 'completed':
        return SprintStatus.completed;
      case 'cancelled':
        return SprintStatus.cancelled;
      default:
        return SprintStatus.planning;
    }
  }

  static String _statusToString(SprintStatus status) {
    switch (status) {
      case SprintStatus.planning:
        return 'planning';
      case SprintStatus.active:
        return 'active';
      case SprintStatus.completed:
        return 'completed';
      case SprintStatus.cancelled:
        return 'cancelled';
    }
  }
}

