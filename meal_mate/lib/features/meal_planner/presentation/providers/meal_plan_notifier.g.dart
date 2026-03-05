// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

final class CurrentUserIdProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentUserIdHash() => r'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';

/// Stream-based Riverpod notifier for the weekly meal plan grid.
///
/// Watches Drift reactively — any insert/update/delete on mealPlanSlots
/// for the given [weekStart] automatically emits a new state.

@ProviderFor(MealPlanNotifier)
final mealPlanNotifierProvider = MealPlanNotifierFamily._();

/// Stream-based Riverpod notifier for the weekly meal plan grid.
final class MealPlanNotifierProvider
    extends $StreamNotifierProvider<MealPlanNotifier, List<MealSlot>> {
  MealPlanNotifierProvider._({
    required MealPlanNotifierFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'mealPlanNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mealPlanNotifierHash();

  @override
  String toString() {
    return r'mealPlanNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MealPlanNotifier create() => MealPlanNotifier();

  @override
  bool operator ==(Object other) {
    return other is MealPlanNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mealPlanNotifierHash() => r'b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3';

final class MealPlanNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MealPlanNotifier,
          AsyncValue<List<MealSlot>>,
          List<MealSlot>,
          Stream<List<MealSlot>>,
          DateTime
        > {
  MealPlanNotifierFamily._()
    : super(
        retry: null,
        name: r'mealPlanNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MealPlanNotifierProvider call(DateTime weekStart) =>
      MealPlanNotifierProvider._(argument: weekStart, from: this);

  @override
  String toString() => r'mealPlanNotifierProvider';
}

abstract class _$MealPlanNotifier
    extends $StreamNotifier<List<MealSlot>> {
  late final _$args = ref.$arg as DateTime;
  DateTime get weekStart => _$args;

  Stream<List<MealSlot>> build(DateTime weekStart);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<MealSlot>>, List<MealSlot>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MealSlot>>, List<MealSlot>>,
              AsyncValue<List<MealSlot>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
