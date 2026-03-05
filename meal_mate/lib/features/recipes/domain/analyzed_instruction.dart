import 'package:freezed_annotation/freezed_annotation.dart';

part 'analyzed_instruction.freezed.dart';
part 'analyzed_instruction.g.dart';

@freezed
sealed class AnalyzedInstruction with _$AnalyzedInstruction {
  const factory AnalyzedInstruction({
    @Default('') String name,
    @Default([]) List<InstructionStep> steps,
  }) = _AnalyzedInstruction;

  factory AnalyzedInstruction.fromJson(Map<String, dynamic> json) =>
      _$AnalyzedInstructionFromJson(json);
}

@freezed
sealed class InstructionStep with _$InstructionStep {
  const factory InstructionStep({
    required int number,
    required String step,
  }) = _InstructionStep;

  factory InstructionStep.fromJson(Map<String, dynamic> json) =>
      _$InstructionStepFromJson(json);
}
