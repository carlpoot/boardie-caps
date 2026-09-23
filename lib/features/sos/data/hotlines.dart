import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A single emergency hotline shown on the Emergency SOS screen (Figure E6).
///
/// Deliberately NOT a Phase 1 ERD entity or repository. The ERD has no
/// table for hotline data -- the DFD's D6 "Reports and Hotline Data" store
/// bundles it with `Reports`, but nothing models hotline rows -- so this is
/// a static, hardcoded list for now, per the task's own instruction not to
/// invent a `HotlineEntity` in the data layer yet. Moving this into
/// Firestore later (to make it admin-editable) would mean adding a real
/// model/repository behind this same shape; nothing about the screen would
/// need to change beyond swapping [kHotlines] for a provider.
class Hotline {
  const Hotline({
    required this.id,
    required this.name,
    required this.description,
    required this.phoneNumber,
    required this.color,
  });

  /// Stable identifier for widget keys -- independent of [name], which is
  /// display text.
  final String id;

  final String name;
  final String description;
  final String phoneNumber;

  /// Reuses the existing semantic status palette from
  /// [AppColors]/`status_display.dart` rather than inventing new hues --
  /// red/blue/green/orange were already meaningful colors in this app
  /// before this screen existed.
  final Color color;
}

/// Matches Figure E6 exactly: four hotlines, one per emergency category.
/// Phone numbers for Police/Hospital/Fire are placeholders (plausible
/// Legazpi City / Albay landline numbers, consistent with the rest of the
/// app's seed data) -- only the National Emergency Hotline's 911 is a real,
/// specified number.
const List<Hotline> kHotlines = [
  Hotline(
    id: 'national_emergency',
    name: 'National Emergency Hotline',
    description: 'For all emergencies',
    phoneNumber: '911',
    color: AppColors.statusFull,
  ),
  Hotline(
    id: 'police',
    name: 'Police Station',
    description: 'Legazpi City Police',
    phoneNumber: '(052) 480-5000',
    color: AppColors.primary,
  ),
  Hotline(
    id: 'hospital',
    name: 'Hospital / Clinic',
    description: 'Aquinas University Hospital',
    phoneNumber: '(052) 480-0888',
    color: AppColors.statusAvailable,
  ),
  Hotline(
    id: 'fire',
    name: 'Fire Station',
    description: 'Legazpi Fire Department',
    phoneNumber: '(052) 480-1116',
    color: AppColors.statusLimited,
  ),
];
