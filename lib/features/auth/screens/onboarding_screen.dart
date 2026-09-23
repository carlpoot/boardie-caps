import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_notifier.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.house_outlined,
    title: 'Find a boarding house near campus',
    body: 'Browse verified listings around Bicol-area campuses, with real '
        'photos, prices, and amenities.',
  ),
  _OnboardingSlide(
    icon: Icons.map_outlined,
    title: 'See it on the map first',
    body: 'Check distance to campus, nearby utilities, and room '
        'availability before you ever schedule a visit.',
  ),
  _OnboardingSlide(
    icon: Icons.event_available_outlined,
    title: 'Request visits and hold a room',
    body: 'Ask to visit in person, or place a temporary hold on a room '
        'while you decide -- all in one place.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _page == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                key: const Key('onboarding_skip_button'),
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(slide.icon, size: 96),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => Container(
                  margin: const EdgeInsets.all(4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('onboarding_next_button'),
                  onPressed: isLastPage
                      ? _finish
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
