import '../models/models.dart';

/// Thrown by [AuthRepository] when a login or sign-up attempt is rejected
/// (bad credentials, duplicate email, suspended account, etc.).
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Authentication against a `Users` row (plus its linked `StudentProfiles`
/// or `LandlordProfiles` row on sign-up). Backed today by
/// [MockAuthRepository]; a Firebase Auth-backed implementation arrives in a
/// later phase behind this same interface.
///
/// Administrator accounts are seeded/assigned manually and are never
/// created through sign-up, so there is no `signUpAdmin`.
abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
  });

  /// Creates a `Users` row with `role = student` and a linked
  /// `StudentProfiles` row.
  Future<User> signUpStudent({
    required String name,
    required String email,
    required String contactNo,
    required String password,
    required String campusId,
  });

  /// Creates a `Users` row with `role = landlord` and a linked
  /// `LandlordProfiles` row (`verification_status = pending`).
  Future<User> signUpLandlord({
    required String name,
    required String email,
    required String contactNo,
    required String password,
  });

  Future<void> logout();
}
