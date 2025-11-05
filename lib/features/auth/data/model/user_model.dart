import 'package:project_pipeline/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    super.uid,
    required super.userName,
    required super.email,
    required super.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      userName: json['userName'],
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'password': password,
    };
  }

  UserModel copyWith({
    String? uid,
    String? userName,
    String? email,
    String? password,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}