import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:project_pipeline/core/services/connectivity_service.dart';
import 'package:project_pipeline/core/services/local_storage_service.dart';
import 'package:project_pipeline/core/usecase/usecase.dart';
import 'package:project_pipeline/core/utils/error_mapper.dart';
import 'package:project_pipeline/features/auth/domain/entities/user_entity.dart';
import 'package:project_pipeline/features/auth/domain/usecases/signup_usecase.dart';
import 'package:project_pipeline/features/auth/domain/usecases/signin_usecase.dart';
import 'package:project_pipeline/features/auth/domain/usecases/auth_usecases.dart';
import 'package:project_pipeline/features/auth/domain/usecases/update_username_usecase.dart';
import 'package:project_pipeline/features/auth/domain/usecases/google_signin_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpWithEmailAndPassword _signUpWithEmailAndPassword;
  final SignInWithEmailAndPassword _signInWithEmailAndPassword;
  final GoogleSignIn _googleSignIn;
  final GetCurrentUser _getCurrentUser;
  final SignOut _signOut;
  final UpdateUsernameUsecase _updateUsernameUsecase;
  final ConnectivityService _connectivityService;
  final LocalStorageService _localStorageService;

  AuthBloc({
    required SignUpWithEmailAndPassword signUpWithEmailAndPassword,
    required SignInWithEmailAndPassword signInWithEmailAndPassword,
    required GoogleSignIn googleSignIn,
    required GetCurrentUser getCurrentUser,
    required SignOut signOut,
    required UpdateUsernameUsecase updateUsernameUsecase,
    required ConnectivityService connectivityService,
    required LocalStorageService localStorageService,
  })  : _signUpWithEmailAndPassword = signUpWithEmailAndPassword,
        _signInWithEmailAndPassword = signInWithEmailAndPassword,
        _googleSignIn = googleSignIn,
        _getCurrentUser = getCurrentUser,
        _signOut = signOut,
        _updateUsernameUsecase = updateUsernameUsecase,
        _connectivityService = connectivityService,
        _localStorageService = localStorageService,
        super(AuthInitial()) {
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<CheckAuthStatusRequested>(_onCheckAuthStatusRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<UpdateUsernameRequested>(_onUpdateUsernameRequested);
  }

  // Friendly error mapping moved to core/utils/error_mapper.dart

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Check connectivity
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      emit(const AuthError('Check your internet connectivity'));
      return;
    }

    final result = await _signUpWithEmailAndPassword(
      SignUpParams(
        userName: event.userName,
        email: event.email,
        password: event.password,
      ),
    );

    await result.fold(
      (failure) async {
        emit(AuthError(authFriendlyMessage(failure.message)));
      },
      (user) async {
        await _localStorageService.cacheUser(user);
        emit(AuthSuccess(user));
      },
    );
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Check connectivity
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      emit(const AuthError('Check your internet connectivity'));
      return;
    }

    final result = await _signInWithEmailAndPassword(
      SignInParams(
        email: event.email,
        password: event.password,
      ),
    );

    await result.fold(
      (failure) async {
        emit(AuthError(authFriendlyMessage(failure.message)));
      },
      (user) async {
        await _localStorageService.cacheUser(user);
        emit(AuthSuccess(user));
      },
    );
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 [AuthBloc] Google Sign-In requested');
    emit(AuthLoading());

    // Check connectivity
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      print('❌ [AuthBloc] No internet connectivity');
      emit(const AuthError('Check your internet connectivity'));
      return;
    }

    print('🔵 [AuthBloc] Calling Google Sign-In usecase...');
    final result = await _googleSignIn(NoParams());

    await result.fold(
      (failure) async {
        print('❌ [AuthBloc] Google Sign-In failed: ${failure.message}');
        final friendlyMessage = authFriendlyMessage(failure.message);
        print('❌ [AuthBloc] Showing user message: $friendlyMessage');
        emit(AuthError(friendlyMessage));
      },
      (user) async {
        print('✅ [AuthBloc] Google Sign-In successful for user: ${user.userName}');
        await _localStorageService.cacheUser(user);
        emit(AuthSuccess(user));
      },
    );
  }

  Future<void> _onCheckAuthStatusRequested(
    CheckAuthStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final isLoggedIn = await _localStorageService.isUserLoggedIn();
    
    if (isLoggedIn) {
      final cachedUser = await _localStorageService.getCachedUser();
      if (cachedUser != null) {
        final isConnected = await _connectivityService.checkConnectivity();
        
        if (isConnected) {
          // Try to get current user from Firebase
          final result = await _getCurrentUser(NoParams());
          await result.fold(
            (failure) async {
              emit(AuthOffline(cachedUser));
            },
            (user) async {
              await _localStorageService.cacheUser(user);
              emit(AuthAuthenticated(user));
            },
          );
        } else {
          // Offline mode with cached user
          emit(AuthOffline(cachedUser));
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Clear local storage first
    await _localStorageService.logout();

    // Sign out from Firebase (if connected)
    final isConnected = await _connectivityService.checkConnectivity();
    if (isConnected) {
      final result = await _signOut(NoParams());
      result.fold(
        (failure) {
          // Even if Firebase sign out fails, we've cleared local storage
          emit(AuthUnauthenticated());
        },
        (_) {
          emit(AuthUnauthenticated());
        },
      );
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onUpdateUsernameRequested(
    UpdateUsernameRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(UsernameUpdating());

    // Check connectivity
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      emit(const UsernameUpdateError('Check your internet connectivity'));
      return;
    }

    final result = await _updateUsernameUsecase(
      UpdateUsernameParams(
        uid: event.uid,
        newUsername: event.newUsername,
      ),
    );

    await result.fold(
      (failure) async {
        emit(UsernameUpdateError(authFriendlyMessage(failure.message)));
      },
      (user) async {
        // Update cached user
        await _localStorageService.cacheUser(user);
        emit(UsernameUpdated(user));
        // Transition to authenticated state with small delay to allow UI to show success
        await Future.delayed(const Duration(milliseconds: 500));
        emit(AuthAuthenticated(user));
      },
    );
  }
}
