part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class SignUpRequested extends AuthEvent {
  final String userName;
  final String email;
  final String password;

  const SignUpRequested({
    required this.userName,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [userName, email, password];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class GoogleSignInRequested extends AuthEvent {}

class CheckAuthStatusRequested extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

class UpdateUsernameRequested extends AuthEvent {
  final String uid;
  final String newUsername;

  const UpdateUsernameRequested({
    required this.uid,
    required this.newUsername,
  });

  @override
  List<Object> get props => [uid, newUsername];
}
