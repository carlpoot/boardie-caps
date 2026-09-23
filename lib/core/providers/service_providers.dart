import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/room_availability_service.dart';
import 'repository_providers.dart';

/// Service providers, kept separate from [repository_providers.dart] since
/// a service composes repositories rather than backing a single ERD entity.
final roomAvailabilityServiceProvider = Provider<RoomAvailabilityService>(
  (ref) => RoomAvailabilityService(
    roomRequestRepository: ref.watch(roomRequestRepositoryProvider),
  ),
);
