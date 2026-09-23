import '../../../core/models/models.dart';

/// Where the current session sits in the auth flow.
///
/// `guest` and `unauthenticated` both mean "no `Users` row" -- they're kept
/// separate so the UI/router can tell "hasn't chosen yet" (unauthenticated)
/// apart from "explicitly browsing as a guest".
enum AuthStatus { unauthenticated, guest, authenticated }

/// The app's current session, exposed by `authNotifierProvider`. This is
/// UI/session state, not one of the Phase 1 ERD entities.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.studentId,
    this.landlordId,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? studentId;
  final String? landlordId;
  final bool isLoading;
  final String? errorMessage;

  /// The effective role for routing purposes. Both an unauthenticated
  /// session and an explicit guest session read as [UserRole.guest], since
  /// neither has a `Users` row to read `role` from.
  UserRole get role => user?.role ?? UserRole.guest;

  bool get hasSession => status != AuthStatus.unauthenticated;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? studentId,
    String? landlordId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      studentId: studentId ?? this.studentId,
      landlordId: landlordId ?? this.landlordId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
