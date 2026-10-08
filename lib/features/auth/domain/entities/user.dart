import 'package:equatable/equatable.dart';
import 'package:mobile_emi_manager/shared/enums/user_role.dart';

/// Domain entity representing a logged-in user.
/// This is clean — no Dio, no JSON, no Flutter UI dependencies.
class User extends Equatable {
  final String id;
  final String name;
  final String mobileNumber;
  final UserRole role;
  final String? storeId;
  final String? storeName;
  final String? profileImageUrl;
  final StoreTheme? storeTheme;

  const User({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.role,
    this.storeId,
    this.storeName,
    this.profileImageUrl,
    this.storeTheme,
  });

  bool get isStoreOwner => role.isStoreOwner;
  bool get isSuperAdmin => role.isSuperAdmin;

  User copyWith({
    String? id,
    String? name,
    String? mobileNumber,
    UserRole? role,
    String? storeId,
    String? storeName,
    String? profileImageUrl,
    StoreTheme? storeTheme,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      storeTheme: storeTheme ?? this.storeTheme,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        mobileNumber,
        role,
        storeId,
        storeName,
        profileImageUrl,
        storeTheme,
      ];
}

/// Store-specific theme colors returned by the backend.
class StoreTheme extends Equatable {
  final String? primaryColor;
  final String? secondaryColor;
  final String? accentColor;
  final String? backgroundColor;
  final String? logoUrl;

  const StoreTheme({
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.backgroundColor,
    this.logoUrl,
  });

  @override
  List<Object?> get props => [
        primaryColor,
        secondaryColor,
        accentColor,
        backgroundColor,
        logoUrl,
      ];
}
