import 'package:fpdart/fpdart.dart';
import 'package:task_app/core/error/failure.dart';
import 'package:task_app/core/usecase/usecase.dart';
import 'package:task_app/features/projects/domain/repositories/project_repository.dart';

class SendTeamInvite implements UseCase<void, SendTeamInviteParams> {
  final ProjectRepository repository;

  SendTeamInvite(this.repository);

  @override
  Future<Either<Failure, void>> call(SendTeamInviteParams params) async {
    return await repository.sendTeamInvite(
      projectId: params.projectId,
      invitedUserUid: params.invitedUserUid,
      invitedUserEmail: params.invitedUserEmail,
      creatorUid: params.creatorUid,
      creatorName: params.creatorName,
      projectName: params.projectName,
      role: params.role,
      hasAccess: params.hasAccess,
    );
  }
}

class SendTeamInviteParams {
  final String projectId;
  final String invitedUserUid;
  final String invitedUserEmail;
  final String creatorUid;
  final String creatorName;
  final String projectName;
  final String role;
  final bool hasAccess;

  SendTeamInviteParams({
    required this.projectId,
    required this.invitedUserUid,
    required this.invitedUserEmail,
    required this.creatorUid,
    required this.creatorName,
    required this.projectName,
    required this.role,
    required this.hasAccess,
  });
}

