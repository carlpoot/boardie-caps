import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/room_availability_service.dart';
import '../../auth/providers/auth_notifier.dart';
import 'property_details_data.dart';

final propertyDetailsProvider =
    FutureProvider.family<PropertyDetailsData?, String>((ref, propertyId) async {
  final propertyRepository = ref.watch(propertyRepositoryProvider);
  final imageRepository = ref.watch(propertyImageRepositoryProvider);
  final amenityRepository = ref.watch(amenityRepositoryProvider);
  final roomRepository = ref.watch(roomRepositoryProvider);
  final savedPropertyRepository = ref.watch(savedPropertyRepositoryProvider);
  final availabilityService = ref.watch(roomAvailabilityServiceProvider);
  final studentId = ref.watch(authNotifierProvider).studentId;

  final property = await propertyRepository.getById(propertyId);
  if (property == null) return null;

  final images = await imageRepository.getByProperty(propertyId);
  final amenities = await amenityRepository.getByProperty(propertyId);
  final rooms = await roomRepository.getByProperty(propertyId);

  final roomAvailabilities = <String, RoomAvailability>{};
  for (final room in rooms) {
    roomAvailabilities[room.roomId] = await availabilityService.getAvailability(room);
  }

  final isSaved = studentId == null
      ? false
      : await savedPropertyRepository.isSaved(studentId, propertyId);

  return PropertyDetailsData(
    property: property,
    images: images,
    amenities: amenities,
    rooms: rooms,
    roomAvailabilities: roomAvailabilities,
    isSaved: isSaved,
  );
});
