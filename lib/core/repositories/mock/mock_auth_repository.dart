import '../../models/models.dart';
import '../auth_repository.dart';
import '../landlord_profile_repository.dart';
import '../student_profile_repository.dart';
import '../user_repository.dart';
import 'mock_seed_data.dart';

/// In-memory [AuthRepository]. `Users` has no password field of its own (by
/// design -- see the ERD), so credentials live only in this repository's
/// private map and never round-trip through `User.toMap`/`fromMap`.
///
/// Every seeded `Users` row (see [MockSeedData.users]) can be logged into
/// during development with [seedPassword].
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    required this.userRepository,
    required this.studentProfileRepository,
    required this.landlordProfileRepository,
  }) : _credentials = {
          for (final user in MockSeedData.users)
            user.email.toLowerCase(): seedPassword,
        };

  final UserRepository userRepository;
  final StudentProfileRepository studentProfileRepository;
  final LandlordProfileRepository landlordProfileRepository;

  final Map<String, String> _credentials;

  static const seedPassword = 'password123';

  @override
  Future<User> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final storedPassword = _credentials[normalizedEmail];
    if (storedPassword == null || storedPassword != password) {
      throw const AuthException('Incorrect email or password.');
    }

    final user = await userRepository.getByEmail(normalizedEmail);
    if (user == null) {
      throw const AuthException('No account found for this email.');
    }
    if (user.status == UserStatus.suspended) {
      throw const AuthException('This account has been suspended.');
    }
    return user;
  }

  @override
  Future<User> signUpStudent({
    required String name,
    required String email,
    required String contactNo,
    required String password,
    required String campusId,
  }) async {
    final normalizedEmail = _validateSignup(name, email, contactNo, password);

    final user = await userRepository.create(User(
      userId: '',
      name: name.trim(),
      email: normalizedEmail,
      contactNo: contactNo.trim(),
      role: UserRole.student,
      status: UserStatus.active,
    ));

    await studentProfileRepository.create(StudentProfile(
      studentId: '',
      userId: user.userId,
      campusId: campusId,
      preferences: const {},
    ));

    _credentials[normalizedEmail] = password;
    return user;
  }

  @override
  Future<User> signUpLandlord({
    required String name,
    required String email,
    required String contactNo,
    required String password,
  }) async {
    final normalizedEmail = _validateSignup(name, email, contactNo, password);

    final user = await userRepository.create(User(
      userId: '',
      name: name.trim(),
      email: normalizedEmail,
      contactNo: contactNo.trim(),
      role: UserRole.landlord,
      status: UserStatus.active,
    ));

    // The sign-up form only collects one contact number; it's used for both
    // the Users row and the LandlordProfiles row until a later phase adds a
    // separate business-contact field to the profile screen.
    await landlordProfileRepository.create(LandlordProfile(
      landlordId: '',
      userId: user.userId,
      contactNo: contactNo.trim(),
      verificationStatus: VerificationStatus.pending,
    ));

    _credentials[normalizedEmail] = password;
    return user;
  }

  @override
  Future<void> logout() async {
    // No server-side session to invalidate in the mock; AuthNotifier clears
    // local state. A Firebase-backed implementation will call
    // FirebaseAuth.instance.signOut() here.
  }

  String _validateSignup(
    String name,
    String email,
    String contactNo,
    String password,
  ) {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty) {
      throw const AuthException('Name is required.');
    }
    if (!normalizedEmail.contains('@')) {
      throw const AuthException('Enter a valid email address.');
    }
    if (contactNo.trim().isEmpty) {
      throw const AuthException('Contact number is required.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }
    if (_credentials.containsKey(normalizedEmail)) {
      throw const AuthException('An account with this email already exists.');
    }
    return normalizedEmail;
  }
}
