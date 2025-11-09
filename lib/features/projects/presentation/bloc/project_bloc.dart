import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_projects_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/find_user_by_email_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_invites_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/accept_invite_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/reject_invite_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final CreateProject _createProject;
  final GetProjects _getProjects;
  final FindUserByEmail _findUserByEmail;
  final GetInvites _getInvites;
  final AcceptInvite _acceptInvite;
  final RejectInvite _rejectInvite;
  final UpdateProject _updateProject;
  final DeleteProject _deleteProject;

  ProjectBloc({
    required CreateProject createProject,
    required GetProjects getProjects,
    required FindUserByEmail findUserByEmail,
    required GetInvites getInvites,
    required AcceptInvite acceptInvite,
    required RejectInvite rejectInvite,
    required UpdateProject updateProject,
    required DeleteProject deleteProject,
  })  : _createProject = createProject,
        _getProjects = getProjects,
        _findUserByEmail = findUserByEmail,
        _getInvites = getInvites,
        _acceptInvite = acceptInvite,
        _rejectInvite = rejectInvite,
        _updateProject = updateProject,
        _deleteProject = deleteProject,
        super(ProjectInitial()) {
    on<CreateProjectRequested>(_onCreateProjectRequested);
    on<GetProjectsRequested>(_onGetProjectsRequested);
    on<FindUserByEmailRequested>(_onFindUserByEmailRequested);
    on<GetInvitesRequested>(_onGetInvitesRequested);
    on<AcceptInviteRequested>(_onAcceptInviteRequested);
    on<RejectInviteRequested>(_onRejectInviteRequested);
    on<UpdateProjectRequested>(_onUpdateProjectRequested);
    on<DeleteProjectRequested>(_onDeleteProjectRequested);
  }

  Future<void> _onCreateProjectRequested(
    CreateProjectRequested event,
    Emitter<ProjectState> emit,
  ) async {
    print('🔵 [ProjectBloc] CreateProjectRequested event received');
    print('🔍 [ProjectBloc] Project name: ${event.name}');
    print('🔍 [ProjectBloc] Custom statuses from event: ${event.customStatuses}');
    print('🔍 [ProjectBloc] Project type: ${event.projectType}');
    print('🔍 [ProjectBloc] Workflow type: ${event.workflowType}');
    print('🔍 [ProjectBloc] Project key: ${event.projectKey}');
    
    emit(ProjectLoading());
    final result = await _createProject(
      CreateProjectParams(
        name: event.name,
        description: event.description,
        creatorUid: event.creatorUid,
        creatorName: event.creatorName,
        teamMembers: event.teamMembers,
        customStatuses: event.customStatuses,
        projectType: event.projectType,
        workflowType: event.workflowType,
        projectKey: event.projectKey,
        additionalFeatures: event.additionalFeatures,
      ),
    );

    result.fold(
      (failure) {
        print('❌ [ProjectBloc] Project creation failed: ${failure.message}');
        emit(ProjectError(message: failure.message));
      },
      (project) {
        print('✅ [ProjectBloc] Project created successfully: ${project.id}');
        print('🔍 [ProjectBloc] Returned project has ${project.customStatuses?.length ?? 0} custom statuses');
        emit(ProjectCreated(project: project));
      },
    );
  }

  Future<void> _onGetProjectsRequested(
    GetProjectsRequested event,
    Emitter<ProjectState> emit,
  ) async {
    print('🔵 [ProjectBloc] GetProjectsRequested for user: ${event.userId}');
    emit(ProjectLoading());
    final result = await _getProjects(GetProjectsParams(userId: event.userId));

    result.fold(
      (failure) {
        print('❌ [ProjectBloc] Failed to load projects: ${failure.message}');
        emit(ProjectError(message: failure.message));
      },
      (projects) {
        print('✅ [ProjectBloc] Loaded ${projects.length} projects');
        for (var project in projects) {
          print('   📁 Project: ${project.name} (ID: ${project.id})');
        }
        emit(ProjectLoaded(projects: projects));
        print('✅ [ProjectBloc] Emitted ProjectLoaded state');
      },
    );
  }

  Future<void> _onFindUserByEmailRequested(
    FindUserByEmailRequested event,
    Emitter<ProjectState> emit,
  ) async {
    final result = await _findUserByEmail(
      FindUserByEmailParams(email: event.email),
    );

    result.fold(
      (failure) => emit(ProjectError(message: failure.message)),
      (userInfo) => emit(UserFound(userInfo: userInfo)),
    );
  }

  Future<void> _onGetInvitesRequested(
    GetInvitesRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    final result = await _getInvites(GetInvitesParams(userId: event.userId));

    result.fold(
      (failure) => emit(ProjectError(message: failure.message)),
      (invites) => emit(InvitesLoaded(invites: invites)),
    );
  }

  Future<void> _onAcceptInviteRequested(
    AcceptInviteRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    final result = await _acceptInvite(AcceptInviteParams(inviteId: event.inviteId));

    result.fold(
      (failure) => emit(ProjectError(message: failure.message)),
      (_) => emit(InviteAccepted()),
    );
  }

  Future<void> _onRejectInviteRequested(
    RejectInviteRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    final result = await _rejectInvite(RejectInviteParams(inviteId: event.inviteId));

    result.fold(
      (failure) => emit(ProjectError(message: failure.message)),
      (_) => emit(InviteRejected()),
    );
  }

  Future<void> _onUpdateProjectRequested(
    UpdateProjectRequested event,
    Emitter<ProjectState> emit,
  ) async {
    print('🔵 [ProjectBloc] UpdateProjectRequested event received');
    print('🔍 [ProjectBloc] Project ID: ${event.projectId}');
    print('🔍 [ProjectBloc] Custom statuses from event: ${event.customStatuses}');
    
    emit(ProjectLoading());
    final result = await _updateProject(
      UpdateProjectParams(
        projectId: event.projectId,
        name: event.name,
        description: event.description,
        customStatuses: event.customStatuses,
      ),
    );

    result.fold(
      (failure) {
        print('❌ [ProjectBloc] Project update failed: ${failure.message}');
        emit(ProjectError(message: failure.message));
      },
      (project) {
        print('✅ [ProjectBloc] Project updated successfully: ${project.id}');
        print('🔍 [ProjectBloc] Updated project has ${project.customStatuses?.length ?? 0} custom statuses');
        emit(ProjectUpdated(project: project));
      },
    );
  }

  Future<void> _onDeleteProjectRequested(
    DeleteProjectRequested event,
    Emitter<ProjectState> emit,
  ) async {
    print('🗑️ [ProjectBloc] DeleteProjectRequested event received');
    print('🔍 [ProjectBloc] Project ID: ${event.projectId}');
    
    emit(ProjectLoading());
    final result = await _deleteProject(event.projectId);

    result.fold(
      (failure) {
        print('❌ [ProjectBloc] Project deletion failed: ${failure.message}');
        emit(ProjectError(message: failure.message));
      },
      (_) {
        print('✅ [ProjectBloc] Project deleted successfully');
        emit(ProjectDeleted());
      },
    );
  }
}

