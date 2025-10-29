import 'package:get_it/get_it.dart';
import 'package:task_app/core/services/connectivity_service.dart';
import 'package:task_app/core/services/local_storage_service.dart';
import 'package:task_app/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:task_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:task_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:task_app/features/auth/domain/usecases/signup_usecase.dart';
import 'package:task_app/features/auth/domain/usecases/signin_usecase.dart';
import 'package:task_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:task_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_app/core/theme/theme_cubit.dart';

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
  sl.registerLazySingleton(() => GetCurrentUser(authRepository: sl()));
  sl.registerLazySingleton(() => SignOut(authRepository: sl()));

  // BLoC
  sl.registerFactory(() => AuthBloc(
    signUpWithEmailAndPassword: sl(),
    signInWithEmailAndPassword: sl(),
    getCurrentUser: sl(),
    signOut: sl(),
    connectivityService: sl(),
    localStorageService: sl(),
  ));

  // Theme Cubit
  sl.registerFactory(() => ThemeCubit(localStorageService: sl()));
}
