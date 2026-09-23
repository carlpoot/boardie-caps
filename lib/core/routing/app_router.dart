import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_home_screen.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../../features/auth/providers/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/landlord/landlord_home_screen.dart';
import '../../features/landlord/properties/property_detail_screen.dart';
import '../../features/landlord/properties/property_form_screen.dart';
import '../../features/landlord/rooms/landlord_rooms_screen.dart';
import '../../features/landlord/rooms/room_form_screen.dart';
import '../../features/shared/guest_home_screen.dart';
import '../../features/student/compare_properties/compare_properties_screen.dart';
import '../../features/student/profile/campus_anchor_screen.dart';
import '../../features/student/profile/saved_properties_screen.dart';
import '../../features/student/property_details/property_details_screen.dart';
import '../../features/student/student_home_screen.dart';
import '../models/models.dart';

/// Route paths.
///
/// Only the auth flow and one placeholder home route per role are wired up
/// this phase. Every commented path below is a reserved stub for a specific
/// Use Case diagram capability -- the path *prefixes* they'll live under
/// are already what [_roleAllowed] gates by role, so a later phase can add
/// `GoRoute`s under them without touching the redirect guard.
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';

  // Guest-tier. Also reachable by Student, since the spec defines Student's
  // permissions as "everything Guest can do, plus ...".
  static const guestHome = '/guest';
  // TODO(phase-3): '/guest/browse'        -- Browse Listings
  // TODO(phase-3): '/guest/search'        -- Search and Filter
  // TODO(phase-3): '/guest/map'           -- View 3D GIS Map / Nearby Utilities
  // TODO(phase-3): '/guest/property/:id'  -- View Property Details / Check Room Availability

  // Access SOS Hotlines (Figure E6) lives as a bottom-nav tab on EVERY
  // role's own home shell (guest/student/landlord/admin), not a route of
  // its own -- it needs no login, per the auth phase's decision that SOS
  // is Guest-tier public-safety information, but it also needs to be
  // reachable without leaving whatever shell an authenticated role is
  // already in, so it isn't gated behind the '/guest' prefix either.

  static const studentHome = '/student/home';

  /// The pattern registered with go_router.
  static const studentPropertyDetailsPattern = '/student/property/:id';

  /// Builds a concrete path to a given property's details.
  static String studentPropertyDetails(String propertyId) =>
      '/student/property/$propertyId';

  // Request Visit lives in a bottom sheet from Property Details, not a
  // route; Manage Visit Schedule and Room Holds both live inside the
  // Reservations tab; Manage Profile lives inside the Profile tab -- none
  // of those needed a new route, just more bottom-nav destinations on the
  // existing '/student/home' shell.

  static const studentSaved = '/student/saved';
  static const studentCampusAnchor = '/student/campus-anchor';
  static const studentCompare = '/student/compare';

  static const landlordHome = '/landlord/home';

  // Manage Property Listings lives inside the Properties tab; pushed routes
  // below it handle create/edit and per-property detail.
  static const landlordPropertyForm = '/landlord/property-form';
  static const landlordPropertyDetailsPattern = '/landlord/property/:id';
  static String landlordPropertyDetails(String propertyId) =>
      '/landlord/property/$propertyId';

  // Update Rooms and Occupancy nests under a property (Property Details ->
  // Manage Rooms), rather than being a tab of its own.
  static const landlordPropertyRoomsPattern = '/landlord/property/:id/rooms';
  static String landlordPropertyRooms(String propertyId) =>
      '/landlord/property/$propertyId/rooms';
  static const landlordRoomFormPattern = '/landlord/property/:id/room-form';
  static String landlordRoomForm(String propertyId) =>
      '/landlord/property/$propertyId/room-form';

  // Respond to Visit Requests, Respond to Room Requests, and Generate
  // Landlord Reports each live inside their own bottom-nav tab -- no
  // dedicated route needed for the tabs themselves.

  // TODO(phase-3): '/landlord/profile' -- Manage Profile

  // Manage Users, Verify Listings, Review Reported Listings, and Generate
  // Admin Reports each live inside their own bottom-nav tab -- no
  // dedicated route needed for the tabs themselves.
  static const adminHome = '/admin/home';
}

/// The default landing route for a role, used both by the redirect guard
/// and by screens that need to navigate somewhere deterministic right after
/// an auth action (login, sign-up, continue-as-guest, logout).
String homeForRole(UserRole role) => switch (role) {
      UserRole.guest => AppRoutes.guestHome,
      UserRole.student => AppRoutes.studentHome,
      UserRole.landlord => AppRoutes.landlordHome,
      UserRole.admin => AppRoutes.adminHome,
    };

/// Whether [role] may sit under the top-level path prefix in [location].
///
/// Landlord and Admin are NOT granted the Guest-tier browsing prefix --
/// the spec's permission lists for those two roles are standalone
/// management capabilities with no stated overlap with Guest's browsing
/// actions (unlike Student, which is explicitly "everything Guest can do,
/// plus ..."). Flagging this back: if landlords/admins should also be able
/// to browse listings like a guest, this is the one line to relax.
bool _roleAllowed(String location, UserRole role) {
  if (location.startsWith(AppRoutes.guestHome)) {
    return role == UserRole.guest || role == UserRole.student;
  }
  if (location.startsWith('/student')) return role == UserRole.student;
  if (location.startsWith('/landlord')) return role == UserRole.landlord;
  if (location.startsWith('/admin')) return role == UserRole.admin;
  return true;
}

String? _redirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authNotifierProvider);
  final hasSeenOnboarding = ref.read(hasSeenOnboardingProvider);
  final location = state.matchedLocation;

  final isOnboardingRoute = location == AppRoutes.onboarding;
  final isAuthRoute = location == AppRoutes.login || location == AppRoutes.signup;

  // 1. First launch: onboarding gates everything else.
  if (!hasSeenOnboarding) {
    return isOnboardingRoute ? null : AppRoutes.onboarding;
  }
  if (isOnboardingRoute) {
    return authState.hasSession ? homeForRole(authState.role) : AppRoutes.login;
  }

  // 2. No session yet (never logged in, signed up, or chosen guest):
  //    only the login/signup screens are reachable.
  if (!authState.hasSession) {
    return isAuthRoute ? null : AppRoutes.login;
  }

  // 3. Already have a session (guest or authenticated): no reason to sit on
  //    the login/signup screens.
  if (isAuthRoute) {
    return homeForRole(authState.role);
  }

  // 4. Role gate: bounce an unauthorized route attempt to that role's own
  //    home, matching the Use Case diagram's actor separation.
  if (!_roleAllowed(location, authState.role)) {
    return homeForRole(authState.role);
  }

  return null;
}

/// Bridges Riverpod state changes to go_router's `refreshListenable`, so a
/// state change (e.g. logging out) re-evaluates [_redirect] for whatever
/// route the app currently sits on -- this backstops the explicit
/// `context.go(...)` calls screens already make after auth actions, and is
/// what actually protects a deep link, browser back/forward, or manually
/// typed URL.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (_, _) => notifyListeners());
    ref.listen<bool>(hasSeenOnboardingProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.guestHome,
        builder: (context, state) => const GuestHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentPropertyDetailsPattern,
        builder: (context, state) => PropertyDetailsScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.studentSaved,
        builder: (context, state) => const SavedPropertiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentCampusAnchor,
        builder: (context, state) => const CampusAnchorScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentCompare,
        builder: (context, state) => ComparePropertiesScreen(
          propertyIds: state.extra! as List<String>,
        ),
      ),
      GoRoute(
        path: AppRoutes.landlordHome,
        builder: (context, state) => const LandlordHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.landlordPropertyForm,
        builder: (context, state) => PropertyFormScreen(
          existing: state.extra as Property?,
        ),
      ),
      GoRoute(
        path: AppRoutes.landlordPropertyDetailsPattern,
        builder: (context, state) => PropertyDetailScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.landlordPropertyRoomsPattern,
        builder: (context, state) => LandlordRoomsScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.landlordRoomFormPattern,
        builder: (context, state) => RoomFormScreen(
          propertyId: state.pathParameters['id']!,
          existing: state.extra as Room?,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
      ),
    ],
  );
});
