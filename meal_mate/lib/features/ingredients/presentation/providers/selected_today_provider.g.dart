// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_today_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the map of ingredient IDs -> names selected as "I have these today".
///
/// CRITICAL: Uses keepAlive: true so this state survives navigation.
/// Phase 4 recipe discovery reads from this provider directly — do NOT
/// store selected-today in route args or widget state.
///
/// State is Map<String, String> (id -> name) so the expandable pill bar
/// can show ingredient name chips without additional async lookups.
///
/// Entries persist until user manually clears — NO date filter per locked decision.

@ProviderFor(SelectedTodayNotifier)
final selectedTodayProvider = SelectedTodayNotifierProvider._();

/// Manages the map of ingredient IDs -> names selected as "I have these today".
///
/// CRITICAL: Uses keepAlive: true so this state survives navigation.
/// Phase 4 recipe discovery reads from this provider directly — do NOT
/// store selected-today in route args or widget state.
///
/// State is Map<String, String> (id -> name) so the expandable pill bar
/// can show ingredient name chips without additional async lookups.
///
/// Entries persist until user manually clears — NO date filter per locked decision.
final class SelectedTodayNotifierProvider
    extends $AsyncNotifierProvider<SelectedTodayNotifier, Map<String, String>> {
  /// Manages the map of ingredient IDs -> names selected as "I have these today".
  ///
  /// CRITICAL: Uses keepAlive: true so this state survives navigation.
  /// Phase 4 recipe discovery reads from this provider directly — do NOT
  /// store selected-today in route args or widget state.
  ///
  /// State is Map<String, String> (id -> name) so the expandable pill bar
  /// can show ingredient name chips without additional async lookups.
  ///
  /// Entries persist until user manually clears — NO date filter per locked decision.
  SelectedTodayNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTodayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTodayNotifierHash();

  @$internal
  @override
  SelectedTodayNotifier create() => SelectedTodayNotifier();
}

String _$selectedTodayNotifierHash() =>
    r'a1b2c3d4e5f6789012345678901234567890abcd';

/// Manages the map of ingredient IDs -> names selected as "I have these today".
///
/// CRITICAL: Uses keepAlive: true so this state survives navigation.
/// Phase 4 recipe discovery reads from this provider directly — do NOT
/// store selected-today in route args or widget state.
///
/// State is Map<String, String> (id -> name) so the expandable pill bar
/// can show ingredient name chips without additional async lookups.
///
/// Entries persist until user manually clears — NO date filter per locked decision.

abstract class _$SelectedTodayNotifier
    extends $AsyncNotifier<Map<String, String>> {
  FutureOr<Map<String, String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<Map<String, String>>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, String>>, Map<String, String>>,
              AsyncValue<Map<String, String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
