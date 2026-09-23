import 'package:flutter/material.dart';

/// The app's text style scale.
///
/// Deliberately left on the platform default font family (no `fontFamily`
/// override anywhere in this file) rather than naming a specific one --
/// "a single font family, applied consistently" is satisfied by every
/// style in the app going through this one scale, not by pinning a
/// particular typeface. Swap in a custom font later by adding `fontFamily`
/// here once; every style below inherits it automatically.
abstract final class AppTypography {
  // Headlines: property names on detail screens, section-defining titles.
  static const headlineLarge = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2);
  static const headlineMedium =
      TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.25);
  static const headlineSmall = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3);

  // Titles: card headers, list item titles, section headers ("Amenities",
  // "Rooms", "Generate a Report").
  static const titleLarge = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);
  static const titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3);
  static const titleSmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3);

  // Body: descriptions, addresses, form field content.
  static const bodyLarge = TextStyle(fontSize: 16, height: 1.4);
  static const bodyMedium = TextStyle(fontSize: 14, height: 1.4);
  static const bodySmall = TextStyle(fontSize: 12, height: 1.4);

  // Labels: button text, chip text, prices.
  static const labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2);
  static const labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2);

  // Captions: timestamps, "responded at", metadata rows.
  static const caption = TextStyle(fontSize: 11, height: 1.3);

  /// Compact, bold text for status pill/badge widgets.
  static const statusBadge = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
}
