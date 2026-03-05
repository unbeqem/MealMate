import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_slot.freezed.dart';

@freezed
sealed class MealSlot with _$MealSlot {
  const factory MealSlot({
    required String id,
    required String dayOfWeek,
    required String mealType,
    required DateTime weekStart,
    String? recipeId, // Spoonacular ID as string (e.g. "716429")
    String? recipeTitle,
    String? recipeImage,
  }) = _MealSlot;
}
