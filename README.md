# Boardie

A Flutter capstone app for finding student boarding houses near Bicol-area
campuses. Stack: Flutter/Dart, Riverpod for DI/state, go_router for
navigation. Firebase (Auth, Firestore, Storage, Cloud Messaging) is planned
for a later phase; this phase builds the UI against an in-memory mock data
layer so development isn't blocked on Firebase billing/API keys.

## Project structure (feature-first)

```
lib/
  core/
    models/            # plain Dart data classes (fromMap/toMap/copyWith)
    repositories/       # abstract repository interfaces (CRUD + entity-specific queries)
    repositories/mock/  # in-memory implementations, seeded with sample data
    providers/          # Riverpod providers wiring interfaces -> mock impls
    services/           # (empty — reserved for later phases)
    routing/            # go_router config + the role-based redirect guard
    theme/              # (empty — reserved for later phases)
  features/
    auth/                # login, onboarding, sign-up, AuthState/AuthNotifier
    student/              # student_home placeholder
    landlord/             # landlord_home placeholder
    admin/                # admin_home placeholder
    sos/                  # (empty — reserved for later phases)
    map/                  # (empty — reserved for later phases)
    shared/               # guest_home placeholder
```

Phase 1 was models and the data layer only. Phase 2 (this one) adds
authentication against a mock `AuthRepository` and role-based routing; the
actual student/landlord/admin/guest feature screens are still placeholders
that just say "Logged in as `<role>`" — those come in a later phase.

## Data model spec

Every model's `fromMap`/`toMap` uses the exact snake_case keys below (mapped
to camelCase Dart properties), so nothing drifts from the ERD. Status enums
are marked `// TODO: confirm enum values` in [enums.dart](lib/core/models/enums.dart)
pending sign-off on the working value sets.

| Entity | Fields (snake_case, as in ERD) |
| --- | --- |
| **Users** | `user_id` (PK), `name`, `email`, `contact_no`, `role`, `status` |
| **LandlordProfiles** | `landlord_id` (PK), `user_id` (FK→Users), `contact_no`, `verification_status` |
| **StudentProfiles** | `student_id` (PK), `user_id` (FK→Users), `campus_id` (FK→Campuses), `preferences` |
| **Campuses** | `campus_id` (PK), `name`, `latitude`, `longitude` |
| **Properties** | `property_id` (PK), `landlord_id` (FK→LandlordProfiles), `name`, `address`, `latitude`, `longitude`, `storeys`, `verification_status`, `min_price`, `utilities_updated_at`, `created_at` |
| **Rooms** | `room_id` (PK), `property_id` (FK→Properties), `room_type`, `capacity`, `current_occupancy`, `held_count`, `rent_price`, `availability_updated_at` |
| **Amenities** | `amenity_id` (PK), `property_id` (FK→Properties), `amenity_name` |
| **PropertyImages** | `image_id` (PK), `property_id` (FK→Properties), `image_url` |
| **VisitRequests** | `visit_id` (PK), `student_id` (FK→StudentProfiles), `property_id` (FK→Properties), `landlord_id` (FK→LandlordProfiles), `status`, `requested_datetime`, `responded_datetime`, `created_at` |
| **RoomRequests** | `request_id` (PK), `student_id` (FK→StudentProfiles), `room_id` (FK→Rooms), `property_id` (FK→Properties), `landlord_id` (FK→LandlordProfiles), `status`, `held_until`, `approved_at`, `confirmed_at`, `created_at` |
| **SavedProperties** | `save_id` (PK), `student_id` (FK→StudentProfiles), `property_id` (FK→Properties), `saved_at` |
| **ReportedListings** | `report_issue_id` (PK), `property_id` (FK→Properties), `reported_by` (FK→Users), `reason`, `review_status` |
| **Reports** | `report_id` (PK), `created_by` (FK→Users), `report_type`, `date_generated`, `file_url` |

`VisitRequests` ("ask to visit a property in person") and `RoomRequests`
("place a temporary hold on one specific room") are intentionally separate
entities/features, not merged.

`Rooms` availability (Available / Limited / Full / Reserved, per the map
legend) is derived, not stored: Available/Limited/Full comes from
`current_occupancy` vs `capacity` (see `Room.occupancyStatus`), and Reserved
comes from an active `confirmed` `RoomRequest` for that room (see
`RoomRequestRepository.getActiveHoldsForRoom`).

## Dependency injection

Every repository is exposed as a Riverpod `Provider` in
[repository_providers.dart](lib/core/providers/repository_providers.dart),
typed to the *abstract* interface. UI code should only ever depend on these
providers and the abstract interfaces in `core/repositories/` — swapping the
mock implementations for real Firebase-backed ones later requires changing
only the right-hand side of each provider.

## Auth flow and role-based routing (Phase 2)

Authentication runs against a mock `AuthRepository`
([auth_repository.dart](lib/core/repositories/auth_repository.dart) /
[mock_auth_repository.dart](lib/core/repositories/mock/mock_auth_repository.dart)),
following the same interface-in-`core`, mock-in-`core/repositories/mock`
pattern as every Phase 1 entity repository — a real Firebase Auth
implementation can replace the mock later behind the same interface.

- **`Users` has no password field** (per the Phase 1 ERD), so credentials
  live only in `MockAuthRepository`'s private in-memory map and never touch
  `User.toMap`/`fromMap`.
- **Every seeded `Users` row can be logged into** with the password
  `password123` (see `MockAuthRepository.seedPassword`) — useful for
  exercising each role without going through sign-up. For example:
  `grace.admin@boardie.io` (admin), `ramon.landlord@boardie.io` (landlord),
  `anna.student@boardie.io` (student).
- **Sign-up** creates a `Users` row plus a linked `StudentProfiles` or
  `LandlordProfiles` row (never both, never an admin — admin accounts are
  seeded/assigned manually). New students default to the seeded "Bicol
  University" campus since there's no campus picker yet.
- **Guest sessions** never create a `Users` row at all — `AuthState.status`
  distinguishes `guest` from `unauthenticated` so the router knows the
  difference, but both read as `UserRole.guest` for permission checks.
- **Onboarding's "seen it already" flag is in-memory only** (`hasSeenOnboardingProvider`)
  — there's no local-storage layer yet, so it resets on every cold start.
  That's an acceptable placeholder until a later phase adds persistence.

Routing lives in
[app_router.dart](lib/core/routing/app_router.dart) (go_router). The
redirect guard reads the current `AuthState` and bounces an unauthorized
route attempt back to that role's own home route. Two assumptions made
while building this, flagged for review:

- **SOS is a Guest-tier action** (no login required), per the task's own
  note that it's public safety info.
- **Landlord and Admin do *not* inherit the Guest-tier browsing routes.**
  The spec defines Student's permissions as "everything Guest can do, plus
  ...", but Landlord's and Admin's permission lists are standalone
  management capabilities with no stated overlap — so only `guest` and
  `student` roles pass the `/guest` prefix guard. If landlords/admins should
  also be able to browse listings like a guest, `_roleAllowed` in
  `app_router.dart` is the one place to relax.

Every other capability from the spec (Browse Listings, Request Visit,
Manage Property Listings, Manage Users, etc.) is reserved as a commented
route stub in `AppRoutes` — the path prefixes those stubs live under are
already what the guard gates by role, so later phases can add real
`GoRoute`s under them without touching the redirect logic itself.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
