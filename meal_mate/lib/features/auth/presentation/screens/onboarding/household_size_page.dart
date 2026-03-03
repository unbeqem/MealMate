import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_notifier.dart';

/// Onboarding screen 1 — lets the user select their household size (1-10).
class HouseholdSizePage extends ConsumerWidget {
  const HouseholdSizePage({
    super.key,
    required this.onNext,
  });

  /// Callback invoked when the user taps "Next" to advance to page 2.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingData = ref.watch(onboardingNotifierProvider);
    final householdSize = onboardingData.householdSize;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'How many people are in your household?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll use this to size your meal plans and shopping lists.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Current value display
          Text(
            '$householdSize',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            householdSize == 1 ? 'person' : 'people',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Increment / decrement controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: householdSize > 1
                    ? () => ref
                        .read(onboardingNotifierProvider.notifier)
                        .setHouseholdSize(householdSize - 1)
                    : null,
                icon: const Icon(Icons.remove),
                iconSize: 32,
                style: IconButton.styleFrom(
                  minimumSize: const Size(56, 56),
                ),
              ),
              const SizedBox(width: 48),
              IconButton.filled(
                onPressed: householdSize < 10
                    ? () => ref
                        .read(onboardingNotifierProvider.notifier)
                        .setHouseholdSize(householdSize + 1)
                    : null,
                icon: const Icon(Icons.add),
                iconSize: 32,
                style: IconButton.styleFrom(
                  minimumSize: const Size(56, 56),
                ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
