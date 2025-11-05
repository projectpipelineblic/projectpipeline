import 'package:get_it/get_it.dart';
import 'package:project_pipeline/core/services/connectivity_service.dart';
import 'package:project_pipeline/core/services/local_storage_service.dart';
import 'package:project_pipeline/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:project_pipeline/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:project_pipeline/features/auth/domain/repositories/auth_repository.dart';
import 'package:project_pipeline/features/auth/domain/usecases/signup_usecase.dart';
import 'package:project_pipeline/features/auth/domain/usecases/signin_usecase.dart';
import 'package:project_pipeline/features/auth/domain/usecases/auth_usecases.dart';
import 'package:project_pipeline/features/auth/domain/usecases/update_username_usecase.dart';
import 'package:project_pipeline/features/auth/domain/usecases/google_signin_usecase.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/core/theme/theme_cubit.dart';
import 'package:project_pipeline/features/projects/data/datasources/project_remote_datasource.dart';
import 'package:project_pipeline/features/projects/data/repositories/project_repository_impl.dart';
import 'package:project_pipeline/features/projects/domain/repositories/project_repository.dart';
import 'package:project_pipeline/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_projects_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/find_user_by_email_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/send_team_invite_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_invites_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/accept_invite_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/reject_invite_usecase.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/data/datasources/task_remote_data_source.dart';
import 'package:project_pipeline/features/projects/data/repositories/task_repository_impl.dart';
import 'package:project_pipeline/features/projects/domain/repositories/task_repository.dart';
import 'package:project_pipeline/features/projects/domain/usecases/stream_tasks_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/create_task_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/update_task_status_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_user_tasks_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_open_projects_usecase.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/task_bloc.dart';
import 'package:project_pipeline/features/home/presentation/bloc/dashboard_bloc.dart';
import 'package:project_pipeline/features/tasks_board/domain/usecases/get_all_user_tasks_usecase.dart';
import 'package:project_pipeline/features/tasks_board/presentation/bloc/tasks_board_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ========== Core Services ==========
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService());

  // ========== Auth Feature ==========
  
  // Data Sources
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDatasource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignUpWithEmailAndPassword(authRepository: sl()));
  sl.registerLazySingleton(() => SignInWithEmailAndPassword(authRepository: sl()));
  sl.registerLazySingleton(() => GoogleSignIn(authRepository: sl()));
  sl.registerLazySingleton(() => GetCurrentUser(authRepository: sl()));
  sl.registerLazySingleton(() => SignOut(authRepository: sl()));
  sl.registerLazySingleton(() => UpdateUsernameUsecase(sl()));

  // BLoC
  sl.registerFactory(() => AuthBloc(
    signUpWithEmailAndPassword: sl(),
    signInWithEmailAndPassword: sl(),
    googleSignIn: sl(),
    getCurrentUser: sl(),
    signOut: sl(),
    updateUsernameUsecase: sl(),
    connectivityService: sl(),
    localStorageService: sl(),
  ));

  // Theme Cubit
  sl.registerFactory(() => ThemeCubit(localStorageService: sl()));

  // ========== Projects Feature ==========
  
  // Data Sources
  sl.registerLazySingleton<ProjectRemoteDatasource>(
    () => ProjectRemoteDatasourceImpl(),
  );
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(remoteDatasource: sl()),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(remote: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateProject(sl()));
  sl.registerLazySingleton(() => GetProjects(sl()));
  sl.registerLazySingleton(() => GetOpenProjects(sl()));
  sl.registerLazySingleton(() => FindUserByEmail(sl()));
  sl.registerLazySingleton(() => SendTeamInvite(sl()));
  sl.registerLazySingleton(() => GetInvites(sl()));
  sl.registerLazySingleton(() => AcceptInvite(sl()));
  sl.registerLazySingleton(() => RejectInvite(sl()));
  sl.registerLazySingleton(() => StreamTasks(sl()));
  sl.registerLazySingleton(() => GetUserTasks(sl()));
  sl.registerLazySingleton(() => CreateTask(sl()));
  sl.registerLazySingleton(() => UpdateTaskStatus(sl()));

  // BLoC
  sl.registerFactory(() => ProjectBloc(
    createProject: sl(),
    getProjects: sl(),
    findUserByEmail: sl(),
    getInvites: sl(),
    acceptInvite: sl(),
    rejectInvite: sl(),
  ));
  sl.registerFactory(() => TaskBloc(
        streamTasks: sl(),
        createTask: sl(),
        updateTaskStatus: sl(),
      ));
  sl.registerFactory(() => DashboardBloc(
        getUserTasks: sl(),
        getOpenProjects: sl(),
      ));

  // ========== Tasks Board Feature ==========
  
  // Use Cases
  sl.registerLazySingleton(() => GetAllUserTasks(sl()));

  // BLoC
  sl.registerFactory(() => TasksBoardBloc(
        getAllUserTasks: sl(),
        updateTaskStatus: sl(),
      ));
}
