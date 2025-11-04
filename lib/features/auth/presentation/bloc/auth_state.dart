part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserEntity user;

  const AuthSuccess(this.user);

  @override
  List<Object> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthOffline extends AuthState {
  final UserEntity user;

  const AuthOffline(this.user);

  @override
  List<Object> get props => [user];
}

class UsernameUpdating extends AuthState {}

class UsernameUpdated extends AuthState {
  final UserEntity user;

  const UsernameUpdated(this.user);

  @override
  List<Object> get props => [user];
}

class UsernameUpdateError extends AuthState {
  final String message;

  const UsernameUpdateError(this.message);

  @override
  List<Object> get props => [message];
}
