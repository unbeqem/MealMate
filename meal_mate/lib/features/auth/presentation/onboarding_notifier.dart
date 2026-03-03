import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/onboarding_data.dart';

part 'onboarding_notifier.g.dart';

/// Available dietary preference options shown in the onboarding flow.
const List<String> kDietaryPreferenceOptions = [
  'vegetarian',
  'vegan',
  'gluten-free',
  'dairy-free',
  'nut-free',
  'halal',
  'kosher',
];

/// Riverpod notifier managing onboarding state accumulation and Supabase profile upsert.
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingData build() {
    return const OnboardingData();
  }

  /// Updates the selected household size.
  void setHouseholdSize(int size) {
    state = state.copyWith(householdSize: size);
  }

  /// Adds or removes [preference] from the selected dietary preferences list.
  void toggleDietaryPreference(String preference) {
    final current = List<String>.from(state.dietaryPreferences);
    if (current.contains(preference)) {
      current.remove(preference);
    } else {
      current.add(preference);
    }
    state = state.copyWith(dietaryPreferences: current);
  }

  /// Persists onboarding data to Supabase profiles table and sets local completion flag.
  ///
  /// Order:
  /// 1. Upsert profile row in Supabase
  /// 2. Write local SharedPreferences flag
  /// 3. Invalidate self to trigger RouterRefreshNotifier rebuild
  Future<void> completeOnboarding() async {
    final user = Supabase.instance.client.auth.currentUser!;

    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'household_size': state.householdSize,
      'dietary_preferences': state.dietaryPreferences,
      'onboarding_completed': true,
      'updated_at': DateTime.now().toIso8601String(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    ref.invalidateSelf();
  }
}

/// Provider that reads the local onboarding completion flag from SharedPreferences.
///
/// The router uses this to determine whether to show onboarding or home.
/// On [initialSession] event the router syncs this from Supabase (see router.dart).
@riverpod
Future<bool> onboardingCompleted(OnboardingCompletedRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
}
