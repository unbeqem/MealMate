import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_data.freezed.dart';

@freezed
class OnboardingData with _$OnboardingData {
  const factory OnboardingData({
    @Default(1) int householdSize,
    @Default([]) List<String> dietaryPreferences,
  }) = _OnboardingData;
}
