/// Request model for POST /auth/login
class LoginRequestModel {
  final String mobileNumber;
  final String password;

  const LoginRequestModel({
    required this.mobileNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'mobileNumber': mobileNumber,
        'password': password,
      };
}
