// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analyzed_instruction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalyzedInstruction _$AnalyzedInstructionFromJson(Map<String, dynamic> json) =>
    _AnalyzedInstruction(
      name: json['name'] as String? ?? '',
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => InstructionStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AnalyzedInstructionToJson(
  _AnalyzedInstruction instance,
) => <String, dynamic>{'name': instance.name, 'steps': instance.steps};

_InstructionStep _$InstructionStepFromJson(Map<String, dynamic> json) =>
    _InstructionStep(
      number: (json['number'] as num).toInt(),
      step: json['step'] as String,
    );

Map<String, dynamic> _$InstructionStepToJson(_InstructionStep instance) =>
    <String, dynamic>{'number': instance.number, 'step': instance.step};
