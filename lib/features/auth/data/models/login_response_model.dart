import 'package:mobile_emi_manager/features/auth/data/models/user_model.dart';

/// Response model for POST /auth/login
class LoginResponseModel {
  final String accessToken;
  final UserModel user;

  const LoginResponseModel({
    required this.accessToken,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['accessToken'] as String? ?? json['token'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}
