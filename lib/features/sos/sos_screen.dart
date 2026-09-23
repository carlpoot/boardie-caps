import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'data/hotlines.dart';

/// Emergency SOS (Figure E6): a red header banner over a scrollable list of
/// colored hotline cards. Reachable from every role's bottom nav (Guest,
/// Student, Landlord, Admin) without logging in -- see the comment on
/// `AppRoutes` in `app_router.dart` for why this is a tab on every home
/// shell rather than a route of its own.
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  /// Launches the device dialer via a `tel:` URI.
  ///
  /// **What this can and can't confirm, per the task's own ask not to
  /// assume success just because nothing throws:** `launchUrl`'s returned
  /// `bool` only reflects whether the platform accepted the request to
  /// launch a handler for the URI scheme -- not whether a phone call was
  /// actually placed, since neither Flutter nor the browser can observe
  /// that. On a real Android/iOS device this opens the native dialer
  /// pre-filled with the number, which is directly observable. On web,
  /// `tel:` triggers the *browser's own* handler for the scheme (an
  /// OS-level "Open Telephone Companion?" style prompt, or nothing at all
  /// if no handler is registered) -- Flutter web has no way to detect
  /// which of those happened, so a `true` result there means only "the
  /// browser was asked," not "a dialer opened." See the README for what
  /// was actually observed running this in Chrome.
  Future<void> _call(BuildContext context, Hotline hotline) async {
    // RFC 3966's tel: grammar has no notion of a literal space -- only
    // '-', '.', '(', ')' are recognized visual separators. Uri's own
    // percent-encoding would otherwise turn a formatted number's spaces
    // into a literal "%20" in the URI, which isn't valid tel: syntax (found
    // by asserting on the exact URI a test's fake platform received --
    // see sos_screen_test.dart and the README).
    final digitsOnly = hotline.phoneNumber.replaceAll(' ', '');
    final uri = Uri(scheme: 'tel', path: digitsOnly);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Could not open the dialer for ${hotline.phoneNumber}.'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.statusFull,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency SOS',
                style: AppTypography.headlineSmall.copyWith(color: AppColors.onPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Quick access to emergency services and hotlines',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: kHotlines.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final hotline = kHotlines[index];
              return _HotlineCard(
                hotline: hotline,
                onCall: () => _call(context, hotline),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HotlineCard extends StatelessWidget {
  const _HotlineCard({required this.hotline, required this.onCall});

  final Hotline hotline;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: hotline.color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: hotline.color,
              foregroundColor: AppColors.onPrimary,
              child: const Icon(Icons.phone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotline.name, style: AppTypography.titleSmall),
                  Text(
                    hotline.description,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hotline.phoneNumber,
                    style: AppTypography.labelLarge.copyWith(color: hotline.color),
                  ),
                ],
              ),
            ),
            IconButton(
              key: Key('call_hotline_${hotline.id}'),
              icon: Icon(Icons.call, color: hotline.color),
              tooltip: 'Call ${hotline.name}',
              onPressed: onCall,
            ),
          ],
        ),
      ),
    );
  }
}
