import 'package:equatable/equatable.dart';
class UserEntity extends Equatable {
  final String? uid;
  final String userName;
  final String email;
  final String password;

  UserEntity({
    this.uid,
    required this.userName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'password': password,
    };
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      uid: json['uid'],
      userName: json['userName'],
      email: json['email'],
      password: json['password'],
    );
  }

  @override
  List<Object?> get props => [uid, userName, email, password];
}