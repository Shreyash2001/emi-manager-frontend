import 'package:mobile_emi_manager/features/auth/domain/entities/user.dart';
import 'package:mobile_emi_manager/shared/enums/user_role.dart';

/// API model for User — maps JSON to/from the domain [User] entity.
/// Keep this separate from the domain entity.
class UserModel {
  final String id;
  final String name;
  final String mobileNumber;
  final String role;
  final String? storeId;
  final String? storeName;
  final String? profileImageUrl;
  final StoreThemeModel? theme;

  const UserModel({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.role,
    this.storeId,
    this.storeName,
    this.profileImageUrl,
    this.theme,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final themeJson = json['theme'] as Map<String, dynamic>?;
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      role: json['role'] as String? ?? 'STORE_OWNER',
      storeId: json['storeId'] as String?,
      storeName: json['storeName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      theme: themeJson != null ? StoreThemeModel.fromJson(themeJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobileNumber': mobileNumber,
        'role': role,
        if (storeId != null) 'storeId': storeId,
        if (storeName != null) 'storeName': storeName,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (theme != null) 'theme': theme!.toJson(),
      };

  /// Convert to domain entity.
  User toDomain() {
    return User(
      id: id,
      name: name,
      mobileNumber: mobileNumber,
      role: UserRole.fromString(role),
      storeId: storeId,
      storeName: storeName,
      profileImageUrl: profileImageUrl,
      storeTheme: theme?.toDomain(),
    );
  }
}

/// API model for store theme.
class StoreThemeModel {
  final String? primaryColor;
  final String? secondaryColor;
  final String? accentColor;
  final String? backgroundColor;
  final String? logoUrl;

  const StoreThemeModel({
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.backgroundColor,
    this.logoUrl,
  });

  factory StoreThemeModel.fromJson(Map<String, dynamic> json) {
    return StoreThemeModel(
      primaryColor: json['primaryColor'] as String?,
      secondaryColor: json['secondaryColor'] as String?,
      accentColor: json['accentColor'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (primaryColor != null) 'primaryColor': primaryColor,
        if (secondaryColor != null) 'secondaryColor': secondaryColor,
        if (accentColor != null) 'accentColor': accentColor,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (logoUrl != null) 'logoUrl': logoUrl,
      };

  StoreTheme toDomain() => StoreTheme(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        accentColor: accentColor,
        backgroundColor: backgroundColor,
        logoUrl: logoUrl,
      );
}
