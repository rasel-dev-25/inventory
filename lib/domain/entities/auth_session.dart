import 'enums.dart';

/// The signed-in user's identity plus their resolved shop membership —
/// the two facts every screen needs in order to decide what to show, per
/// the working plan's M1 decision: owner has full access, staff is
/// view-only, no per-table exceptions.
///
/// [shopId]/[role] are null between a successful sign-in and onboarding
/// completing: a brand-new user has an authenticated session but no
/// shop membership yet, until either `AuthRepository.createShopAndBecomeOwner`
/// succeeds or an existing owner adds them as staff
/// (`AuthRepository.addStaffMemberByEmail`) and the session is re-resolved.
class AuthSession {
  final String userId;
  final String? email;
  final String? shopId;
  final ShopMemberRole? role;

  const AuthSession({required this.userId, this.email, this.shopId, this.role});

  /// True once onboarding is complete — a shop membership has been
  /// resolved, one way or the other.
  bool get hasShop => shopId != null && role != null;

  bool get isOwner => role == ShopMemberRole.owner;
  bool get isStaff => role == ShopMemberRole.staff;

  AuthSession copyWith({String? shopId, ShopMemberRole? role}) {
    return AuthSession(
      userId: userId,
      email: email,
      shopId: shopId ?? this.shopId,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.email == email &&
      other.shopId == shopId &&
      other.role == role;

  @override
  int get hashCode => Object.hash(userId, email, shopId, role);

  @override
  String toString() =>
      'AuthSession(userId: $userId, email: $email, shopId: $shopId, role: $role)';
}
