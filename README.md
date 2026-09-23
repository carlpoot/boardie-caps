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
    services/           # RoomAvailabilityService, distance_utils
    routing/            # go_router config + the role-based redirect guard
    theme/              # (empty — reserved for later phases)
  features/
    auth/                 # login, onboarding, sign-up, AuthState/AuthNotifier
    student/               # bottom-nav shell: home, map, reservations, profile tabs
      home/                  # browse: search, filters, PropertyCard list
      map/                   # MapView placeholder
      property_details/      # gallery, amenities, rooms, save, request actions
      visit_requests/        # Request Visit sheet + VisitRequestCard
      room_requests/         # Request Room wiring + RoomRequestCard
      reservations/          # Room Holds / Visit Requests tabs
      profile/               # personal info, saved list, campus anchor
      compare_properties/    # selection state + side-by-side comparison
    landlord/              # landlord_home placeholder
    admin/                 # admin_home placeholder
    sos/                   # (empty — reserved for later phases)
    map/                   # (empty — reserved for later phases)
    shared/                # guest_home placeholder
```

Phase 1 was models and the data layer only. Phase 2 added authentication
against a mock `AuthRepository` and role-based routing. Phase 3a built the
first half of the student-facing screens (browsing and property details).
Phase 3b (this one) builds the second half: visit requests, room
requests/holds, reservations, profile, and compare properties. Landlord/Admin
screens are still "Logged in as `<role>`" placeholders.

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

## Student browsing and property details (Phase 3a)

[`RoomAvailabilityService`](lib/core/services/room_availability_service.dart)
is the one piece of shared, tested business logic this phase adds: given a
`Room`, it returns both how many slots are actually open right now
(`capacity - current_occupancy - active RoomRequest holds`) and which
map-legend status that implies (Available / Limited / Full / Reserved — see
`RoomAvailability`). It's a `Provider` in
[service_providers.dart](lib/core/providers/service_providers.dart), kept
separate from `repository_providers.dart` since a service composes
repositories rather than backing one entity. Phase 3b (room requests),
Phase 4 (landlord room management), and the Phase 8 map all need this exact
calculation, which is why it isn't buried inside a screen.

- **A pending or approved hold counts the same as an occupant** for
  Full/Limited purposes — it's occupying a slot even though it isn't a firm
  booking yet. Only a **confirmed** hold produces the distinct `reserved`
  status, taking priority over the occupancy-based status.
- **Incidental fix while building this:** two seeded `RoomRequests.held_until`
  values were anchored to the fixed historical seed date rather than
  `DateTime.now()`, so those holds had already silently "expired" by
  wall-clock time. Fixed in
  [mock_seed_data.dart](lib/core/repositories/mock/mock_seed_data.dart) so
  the demo data stays meaningful no matter when the app is actually run.

`lib/features/student/`:
- `home/` — search bar, filter chips (All / Near BU / one per distinct
  `Rooms.room_type`), and a horizontally-scrollable `PropertyCard` list.
  Only `verified` properties are shown. All of it is fetched once via
  `studentBrowsePropertiesProvider` and filtered client-side.
- `map/` — `MapView`: a distance-sorted list/grid placeholder. It's the only
  file that needs to change when a real `GoogleMap` widget replaces it.
- `property_details/` — photo gallery, amenities, address, and every
  `Room` with a live availability badge. The Save heart icon is **real**
  (creates/deletes a `SavedProperties` row); "Request Visit" and "Request
  Room" are stubbed with a snackbar — that logic is Phase 3b.

The "Near BU" distance filter and the map placeholder's distance text both
use [`haversineDistanceKm`](lib/core/services/distance_utils.dart) against
the student's own `StudentProfiles.campus_id`, not a hardcoded campus.

## Visit requests, room holds, reservations, profile, compare (Phase 3b)

[`RoomRequestService`](lib/core/services/room_request_service.dart) holds
every `RoomRequests` business rule as a standalone, tested service (see
[room_request_service_test.dart](test/core/services/room_request_service_test.dart)) —
the 4-active-holds cap, live expiry, and the confirm/auto-cancel rule. Kept
out of widgets so Phase 4's landlord side can reuse the exact same logic.

- **Live expiry is a read-time computation, not a write-back.** A hold's
  `held_until` can pass with nothing ever setting `status = 'expired'` on
  the row — there's no scheduled job in the mock phase to do that.
  `RoomRequestService.effectiveStatus`/`isLiveExpired` treat it as expired
  regardless of what's stored, and everything that cares (the 4-hold cap,
  the Reservations "Expired" filter) goes through those helpers rather than
  trusting `RoomRequest.status` directly. **Flagging the choice per the
  task's own ask:** this mirrors how `RoomAvailabilityService` (Phase 3a)
  already treats expiry — purely computed, never a side-effecting write —
  and avoids turning a shared read method into a hidden mutation. When the
  Firebase phase adds a scheduled Cloud Function to flip stale rows, that
  function should own writing the field; this client logic wouldn't need
  to change, since it already discounts a live-expired row either way.
- **The 4-hold cap and the confirm/auto-cancel rule are enforced only in
  `RoomRequestService`**, not duplicated as a UI-level check — the "Request
  Room" button itself is still gated by `RoomAvailabilityService` (is this
  *room* full?), which is a separate, complementary concern from "does this
  *student* already have 4 holds?".
- **Reservations' four filter tabs (Active/Confirmed/Expired/Cancelled)**
  lump `pending`+`approved` into "Active", and fold `declined` into
  "Cancelled" — the wireframe has no tab of its own for `declined`, and
  both represent "this hold didn't go through". See `_HoldFilter` in
  [room_holds_tab.dart](lib/features/student/reservations/room_holds_tab.dart).
- **Set Campus Anchor** (no supporting wireframe prose) is a plain radio
  picker over `Campuses`, writing to `StudentProfiles.campus_id`. Flagging
  back per the task's note: a map-based pin-drop is an equally plausible
  reading if a real map exists by the time this needs revisiting.
- **Compare Properties** (also no supporting prose) is a working
  interpretation: a "Compare" toggle on Browse (Home tab) and on the Saved
  Properties list puts cards into a selection mode (capped at 3, shared
  across both entry points via `compareSelectionProvider`), and a
  side-by-side screen shows min price, amenities, distance from the
  student's campus anchor, and live room availability per property.
  Flagging back in case a different interaction (e.g. a persistent
  multi-select from search results only) was intended instead.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
