// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the list of saved plan templates and template lifecycle operations.

@ProviderFor(TemplateNotifier)
final templateNotifierProvider = TemplateNotifierProvider._();

/// Manages the list of saved plan templates and template lifecycle operations.
final class TemplateNotifierProvider
    extends $AsyncNotifierProvider<TemplateNotifier, List<PlanTemplate>> {
  TemplateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templateNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templateNotifierHash();

  @$internal
  @override
  TemplateNotifier create() => TemplateNotifier();
}

String _$templateNotifierHash() =>
    r'c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4';

abstract class _$TemplateNotifier
    extends $AsyncNotifier<List<PlanTemplate>> {
  FutureOr<List<PlanTemplate>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PlanTemplate>>, List<PlanTemplate>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PlanTemplate>>,
                List<PlanTemplate>
              >,
              AsyncValue<List<PlanTemplate>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
