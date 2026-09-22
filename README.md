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
    routing/            # (empty — reserved for later phases)
    theme/              # (empty — reserved for later phases)
  features/
    auth/
    student/
    landlord/
    admin/
    sos/
    map/
    shared/
```

No screens have been built yet — this phase is models and the data layer only.

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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
