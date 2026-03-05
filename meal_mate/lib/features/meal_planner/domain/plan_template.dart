import 'package:freezed_annotation/freezed_annotation.dart';
import 'meal_slot.dart';

part 'plan_template.freezed.dart';

@freezed
sealed class PlanTemplate with _$PlanTemplate {
  const factory PlanTemplate({
    required String id,
    required String name,
    required DateTime createdAt,
    required List<MealSlot> slots,
  }) = _PlanTemplate;
}
