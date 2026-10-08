/// Enum for user roles.
/// Always compare against this enum — never against raw strings.
enum UserRole {
  storeOwner,
  superAdmin;

  /// Parse from API string safely. Returns [storeOwner] for unknown values.
  static UserRole fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'STORE_OWNER':
      default:
        return UserRole.storeOwner;
    }
  }

  /// Convert back to API string.
  String get apiValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.storeOwner:
        return 'STORE_OWNER';
    }
  }

  bool get isStoreOwner => this == UserRole.storeOwner;
  bool get isSuperAdmin => this == UserRole.superAdmin;
}
