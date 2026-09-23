import 'package:flutter/material.dart';

/// The app's base palette and semantic status colors.
///
/// Every color used anywhere in the UI should trace back to a constant
/// here (or to `Theme.of(context).colorScheme`, which [AppTheme] derives
/// from these) -- no screen should declare its own one-off `Colors.*`
/// value. This is a light-mode-only palette for now.
abstract final class AppColors {
  // Primary brand palette, based on the wireframes' blue header/button
  // scheme (Figures E1-E7).
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF5E92F3);
  static const primaryDark = Color(0xFF003C8F);
  static const onPrimary = Color(0xFFFFFFFF);

  // Neutral surface/background.
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFE9ECF1);
  static const onSurface = Color(0xFF1B1B1F);
  static const onSurfaceMuted = Color(0xFF5C5F66);
  static const outline = Color(0xFFC9CCD3);

  // Semantic status colors -- reused across EVERY status family in the app
  // (RoomAvailabilityStatus, RoomRequestStatus, VisitRequestStatus,
  // VerificationStatus; see status_display.dart) rather than inventing new
  // hues per screen. Matches Figure E4's map legend exactly for the
  // room-availability family: available = green, limited = orange,
  // full = red, reserved = teal.
  static const statusAvailable = Color(0xFF2E7D32); // green 800
  static const statusLimited = Color(0xFFF57C00); // orange 700
  static const statusFull = Color(0xFFD32F2F); // red 700
  static const statusReserved = Color(0xFF00796B); // teal 700

  /// Shared with [statusLimited] -- "pending" and "limited" both mean
  /// "awaiting/not yet settled", so they read as the same hue.
  static const statusPending = statusLimited;

  /// Terminal/inactive states (expired, cancelled, completed) across every
  /// status family.
  static const statusNeutral = Color(0xFF757575); // grey 600

  static const error = statusFull;

  /// The "saved"/favorite heart icon color, used on both the student
  /// Property Details screen and the Saved Properties list.
  static const favorite = Color(0xFFE53935);
}
