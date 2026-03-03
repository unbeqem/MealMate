import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding_notifier.dart';

/// Onboarding screen 2 — lets the user select dietary preferences via FilterChips.
class DietaryPreferencesPage extends ConsumerWidget {
  const DietaryPreferencesPage({
    super.key,
    required this.onDone,
    required this.isSubmitting,
  });

  /// Callback invoked when the user taps "Done". Null while submission is in progress.
  final VoidCallback? onDone;

  /// True while the Supabase upsert is in progress — shows a loading indicator.
  final bool isSubmitting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingData = ref.watch(onboardingNotifierProvider);
    final selectedPreferences = onboardingData.dietaryPreferences;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Any dietary preferences?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply (or skip)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: kDietaryPreferenceOptions.map((preference) {
                final isSelected = selectedPreferences.contains(preference);
                return FilterChip(
                  label: Text(preference),
                  selected: isSelected,
                  onSelected: isSubmitting
                      ? null
                      : (_) => ref
                          .read(onboardingNotifierProvider.notifier)
                          .toggleDietaryPreference(preference),
                  selectedColor:
                      theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Done'),
          ),
        ],
      ),
    );
  }
}
