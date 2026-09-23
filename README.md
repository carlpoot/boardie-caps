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
    theme/              # AppColors, AppTypography, shared status-display extensions, AppTheme
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
    landlord/              # bottom-nav shell: properties, visits, room requests, reports tabs
      properties/            # CRUD + amenities + photos
      rooms/                 # CRUD via RoomAvailabilityService
      visit_requests/        # Accept/Reschedule/Decline
      room_requests/         # Approve/Decline (never Confirm)
      reports/               # PDF generation (pdf + printing packages)
    admin/                 # bottom-nav shell: users, verify, reported, reports tabs
      users/                  # Manage Users: role filter, status toggle
      verification/           # Verify Listings: Verify/Reject a pending Property
      reported_listings/      # Review Reported Listings: Reviewed/Dismissed/Reject Property
      reports/                # PDF generation, system-wide (not landlord-scoped)
    sos/                   # (empty — reserved for later phases)
    map/                   # (empty — reserved for later phases)
    shared/                # guest_home placeholder
```

Phase 1 was models and the data layer only. Phase 2 added authentication
against a mock `AuthRepository` and role-based routing. Phase 3a/3b built
every student-facing screen. Phase 4 built every landlord-facing screen.
Phase 5 (this one) builds every admin-facing screen. A design-system
retrofit ran between Phase 4 and Phase 5 -- see
[Design system](#design-system-theme-retrofit) below.

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

## Landlord screens (Phase 4)

Every landlord screen lives under `lib/features/landlord/`, reusing Phase
1's repositories and Phase 3's `RoomAvailabilityService` -- no repository
changes were needed for this phase. `RoomRequestService` gained two new
methods (`approveRequest`/`declineRequest`) so every `RoomRequests` status
transition, student- and landlord-side alike, stays in that one tested
service rather than being re-implemented per screen.

- **Manage Property Listings** (`properties/`): CRUD for `Properties`
  scoped to `landlord_id`, with nested `Amenities` and `PropertyImages`
  management. New properties always start `verification_status = pending`
  -- only an admin can move that (Phase 5).
- **Update Rooms and Occupancy** (`rooms/`, nested under a property, not
  its own tab): CRUD for `Rooms`. Every write recalculates
  `availability_updated_at`, and the availability badge shown here calls
  the exact same `RoomAvailabilityService` the student side uses, so the
  two can never disagree. `held_count` is never an editable field -- it's
  derived from active `RoomRequests`.
- **Respond to Visit Requests** (`visit_requests/`): every `VisitRequest`
  against the landlord's properties, grouped by status. Accept/Reschedule/
  Decline only act on `pending` ones; Reschedule prompts for a new
  date/time and overwrites `requested_datetime` with it (the ERD has no
  separate "proposed datetime" field).
- **Respond to Room Requests** (`room_requests/`): a **separate queue**
  from Visit Requests, never merged. Approve/Decline act on the *live*
  (expiry-aware) `pending` status via `RoomRequestService.effectiveStatus`.
  A landlord can never set `status = confirmed` -- that guard lives in
  `RoomRequestService.confirmRequest` itself (student-only, per the Use
  Case diagram), not just in the UI.
- **Generate Landlord Reports** (`reports/`): four report types --
  `listings`, `room_availability`, `occupancy`, `reservation` -- built as
  real PDFs via the `pdf` package and opened via `printing`
  (`Printing.layoutPdf`, fired without being awaited, since that dialog
  stays open until the user dismisses it and must not block report
  generation). Every report's content is gathered by `landlord_id` first,
  so it's structurally impossible for one landlord's report to include
  another's data. `Reports.created_by` is the landlord's `Users.user_id`,
  not their `landlord_id`.

  **Flagging two choices back, per the task's own ask:**
  - **`report_type = "reservation"` covers *both* `VisitRequests` and
    `RoomRequests`** as two sections in one PDF
    ([report_pdf_builder.dart](lib/features/landlord/reports/report_pdf_builder.dart)).
    The manuscript's single "reservation" report predates the split between
    the two entities, so neither alone is a faithful reading of what that
    report meant to cover.
  - **No OS file picker was wired up for adding property photos**, despite
    the task naming one. `add_image_button` on Property Details opens a
    dialog where the landlord pastes an image URL instead. Reasoning: a
    real picker needs an additional platform-specific package
    (`image_picker`/`file_picker`) that wasn't among the two the task named
    for this phase (`pdf`, `printing`), and native pickers use platform
    channels that `flutter_test` can't drive without extensive mocking --
    which would mean either leaving that flow untested or spending
    disproportionate effort on a flow explicitly described as a throwaway
    mock ("mock in-memory URL for now"). The substantive behavior --
    creating/deleting `PropertyImages` rows with a placeholder URL standing
    in for the eventual Firebase Storage URL -- is unaffected either way.
  - A PDF-generation detail worth noting even though it isn't a judgment
    call: the `pdf` package's built-in Helvetica font has no glyph for the
    peso sign (₱, U+20B1), so PDF output uses a literal "PHP" prefix instead
    -- the UI itself still shows ₱ everywhere else, since Flutter's own text
    rendering has no such limitation.

## Design system (theme retrofit)

Before Phase 5, every screen styled itself independently -- ad hoc
`Colors.*`/`TextStyle(...)` literals, and the room-availability
status→color/label map duplicated verbatim between the student and
landlord sides. `lib/core/theme/` now holds the one shared design system,
and every screen (Phases 2-5) was retrofitted onto it -- presentation
only, no layout or business-logic changes:

- [`app_colors.dart`](lib/core/theme/app_colors.dart) -- the base palette
  (blue primary, per the wireframes) plus semantic status colors shared
  across **every** status family in the app: green (positive/final),
  orange (pending/awaiting), red (negative), teal
  (affirmative-but-not-final), grey (terminal/inactive). No family invents
  its own hues.
- [`status_display.dart`](lib/core/theme/status_display.dart) -- the ONE
  place every status enum maps to a color and label, as Dart extensions:
  `RoomAvailabilityStatus`, `RoomRequestStatus`, `VisitRequestStatus`,
  `VerificationStatus` (Phase 4 retrofit), plus `UserStatus` and
  `ReportedListingReviewStatus` (added in Phase 5, same vocabulary --
  active/reviewed read as green, suspended/full read as red, dismissed
  reads as the same neutral grey as expired/cancelled).
- [`app_typography.dart`](lib/core/theme/app_typography.dart) -- a text
  style scale (headline/title/body/label/caption), one platform font
  family throughout.
- [`app_theme.dart`](lib/core/theme/app_theme.dart) -- the actual
  `ThemeData` (light mode only), wired into `main.dart` in place of the
  original bare `ColorScheme.fromSeed`.

## Admin screens (Phase 5)

Every admin screen lives under `lib/features/admin/`, reusing Phase 1's
repositories and the design system above -- no repository changes were
needed for this phase either.

- **Manage Users** (`users/`): every `Users` row, filterable by role, each
  shown with its linked `LandlordProfiles`/`StudentProfiles` record inline
  (a user has at most one, never both). The only action is toggling
  `Users.status` between `active` and `suspended`.
- **Verify Listings** (`verification/`): every `Properties` row with
  `verification_status = pending`, system-wide, with its photos and its
  owning landlord's own `LandlordProfiles.verification_status` shown for
  context. Verify/Reject write only `Properties.verification_status` --
  never `LandlordProfiles.verification_status`, which is a separate field
  on a separate entity (identity/account verification vs. per-listing
  verification) that this screen never touches.
- **Review Reported Listings** (`reported_listings/`): every
  `ReportedListings` row with `review_status = pending`, system-wide, with
  the reported property's name and the reporting user's name resolved for
  display. Actions set `review_status` to `reviewed` or `dismissed`.
- **Generate Admin Reports** (`reports/`): three report types --
  `users`, `listing_verification`, `reported_listings` -- built with the
  same `pdf`/`printing` pattern as the landlord reports (including the
  same fire-before-any-`await` fix for the browser print-dialog timing
  issue), but system-wide rather than scoped to a `landlord_id`.

  **Flagging three choices back, per the task's own ask:**
  - **A pending `ReportedListings` row against a property is a warning,
    not a hard block, on verifying it.** Verifying opens a confirm dialog
    that lists any unreviewed reports and their reasons when they exist,
    but the admin can still proceed. Reasoning: an unreviewed report is
    unverified on the admin's side too -- it could be mistaken, retaliatory,
    or simply outdated by the time verification happens. A hard block would
    let anyone freeze a legitimate listing indefinitely just by filing a
    report, with no recourse until that specific report is triaged. A
    warning keeps a human in the loop with the actual reason surfaced,
    without giving an unvetted report unilateral veto power.
  - **Marking a `ReportedListings` row `reviewed` or `dismissed` never
    cascades into `Properties.verification_status`.** The two fields are
    changed by two entirely separate, explicit actions: reviewing/
    dismissing a report only ever writes `review_status`, and rejecting the
    reported property is a distinct "Reject Property" button on the same
    Reported Listings card (as well as being available for any
    still-`pending` property from the Verify Listings screen). Reasoning:
    auto-rejecting a listing as a side effect of simply acknowledging a
    report would be a surprising, hard-to-reverse action hiding behind what
    reads as routine triage -- and a report can be filed against a property
    in *any* verification state (the seed data has one against an
    already-`rejected` property), so a cascade tied only to the `pending`
    Verify Listings queue couldn't handle every case anyway. Because
    `Properties.verification_status` isn't restricted to `pending`
    properties only, "Reject Property" doubles as the one explicit path to
    revoke an already-verified listing's status in response to a
    substantiated report -- there's no separate "un-verify" flow.
  - **Admin reports cover the whole platform, with no `created_by`
    scoping filter on the data itself** (only on which rows show up in
    "Generated Reports", same as the landlord side) -- e.g.
    `listing_verification` includes every landlord's properties, not just
    ones this admin has personally verified. This matches the task's own
    description of these reports as system-wide oversight tools, distinct
    in kind from the landlord reports.

    **A real testing gap surfaced while verifying this claim, worth noting
    for both report features:** `Printing.layoutPdf`'s `onLayout` callback
    -- the only caller of the private row-gathering/PDF-building logic in
    both `_buildPdfBytes` functions (admin and landlord) -- never fires
    under `flutter_test`, since there's no platform channel and the call
    fails before it ever renders a page. Confirmed by temporarily
    instrumenting it with a print statement and observing it never printed
    during a "generate report" widget test. That means the existing
    report-generation widget tests (both sides) only ever proved a
    `Reports` row gets created -- never that the underlying data-gathering
    logic queries what it claims to. [`gatherListingVerificationRows`
    ](lib/features/admin/reports/admin_reports_providers.dart) was pulled
    out of `_buildPdfBytes` as its own top-level function specifically to
    close that gap for the system-wide claim above: a test seeds properties
    under two different landlords and calls it directly (via a captured
    `WidgetRef`, bypassing `Printing.layoutPdf` entirely), asserting the
    returned rows span both `landlord_id`s. The landlord side's equivalent
    functions remain inline and not similarly covered -- flagging that as
    a pre-existing gap this phase didn't introduce, not one it fully closed.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
