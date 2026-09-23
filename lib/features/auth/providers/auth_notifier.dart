import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Whether the first-time onboarding carousel has been shown this session.
///
/// Not persisted yet -- there's no local-storage layer until a later phase,
/// so this resets on every cold start. That's an acceptable placeholder for
/// this phase; swap for a real persisted flag (SharedPreferences, or a
/// Firebase user doc field) once one exists.
final hasSeenOnboardingProvider = StateProvider<bool>((ref) => false);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.login(email: email, password: password);
      state = await _stateForUser(user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> signUpStudent({
    required String name,
    required String email,
    required String contactNo,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final campusId = await _defaultCampusId();
      final user = await _authRepository.signUpStudent(
        name: name,
        email: email,
        contactNo: contactNo,
        password: password,
        campusId: campusId,
      );
      state = await _stateForUser(user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> signUpLandlord({
    required String name,
    required String email,
    required String contactNo,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.signUpLandlord(
        name: name,
        email: email,
        contactNo: contactNo,
        password: password,
      );
      state = await _stateForUser(user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  void continueAsGuest() {
    state = const AuthState(status: AuthStatus.guest);
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState();
  }

  Future<AuthState> _stateForUser(User user) async {
    String? studentId;
    String? landlordId;
    if (user.role == UserRole.student) {
      final profile =
          await ref.read(studentProfileRepositoryProvider).getByUserId(user.userId);
      studentId = profile?.studentId;
    } else if (user.role == UserRole.landlord) {
      final profile =
          await ref.read(landlordProfileRepositoryProvider).getByUserId(user.userId);
      landlordId = profile?.landlordId;
    }
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      studentId: studentId,
      landlordId: landlordId,
    );
  }

  /// Students don't pick a campus at sign-up yet, so every new student
  /// profile defaults to the seeded "Bicol University" row.
  Future<String> _defaultCampusId() async {
    final campusRepository = ref.read(campusRepositoryProvider);
    final matches = await campusRepository.searchByName('Bicol University');
    if (matches.isNotEmpty) return matches.first.campusId;
    final all = await campusRepository.getAll();
    return all.first.campusId;
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
