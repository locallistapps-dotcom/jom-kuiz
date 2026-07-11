import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../domain/entities/subscription_package.dart';
import '../providers/subscription_providers.dart';

/// Manages the list of [SubscriptionPackage]s.
///
/// Used by both the Admin Package Management screen (all packages) and the
/// Parent Subscription screen (active packages only).
final AutoDisposeAsyncNotifierProviderFamily<SubscriptionPackageController,
        List<SubscriptionPackage>, bool?> subscriptionPackageControllerProvider =
    AsyncNotifierProvider.autoDispose
        .family<SubscriptionPackageController, List<SubscriptionPackage>, bool?>(
            SubscriptionPackageController.new);

/// `arg` = `isActive` filter:
/// - `true`  → active packages only (parent view)
/// - `false` → inactive packages only
/// - `null`  → all packages (admin view)
class SubscriptionPackageController
    extends AutoDisposeFamilyAsyncNotifier<List<SubscriptionPackage>, bool?> {
  @override
  Future<List<SubscriptionPackage>> build(bool? arg) async {
    final Result<List<SubscriptionPackage>> result = await ref
        .read(subscriptionServiceProvider)
        .getPackages(isActive: arg);
    return result.when(
      success: (List<SubscriptionPackage> list) => list,
      failure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<SubscriptionPackage>>.loading();
    state = await AsyncValue.guard(() async {
      final Result<List<SubscriptionPackage>> result = await ref
          .read(subscriptionServiceProvider)
          .getPackages(isActive: arg);
      return result.when(
          success: (List<SubscriptionPackage> list) => list,
          failure: (f) => throw f);
    });
  }

  // ── Admin mutations ────────────────────────────────────────────────────────

  Future<Result<SubscriptionPackage>> createPackage({
    required String name,
    String? description,
    required int maxChildren,
    required List<String> includedSubjectIds,
    required int priceCents,
    required int durationDays,
  }) async {
    final Result<SubscriptionPackage> result = await ref
        .read(subscriptionServiceProvider)
        .createPackage(
          name: name,
          description: description,
          maxChildren: maxChildren,
          includedSubjectIds: includedSubjectIds,
          priceCents: priceCents,
          durationDays: durationDays,
        );
    result.when(
      success: (SubscriptionPackage pkg) {
        final List<SubscriptionPackage> current =
            List<SubscriptionPackage>.from(state.valueOrNull ?? <SubscriptionPackage>[]);
        state = AsyncValue<List<SubscriptionPackage>>.data(
            <SubscriptionPackage>[...current, pkg]);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<SubscriptionPackage>> updatePackage({
    required String id,
    required String name,
    String? description,
    required int maxChildren,
    required List<String> includedSubjectIds,
    required int priceCents,
    required int durationDays,
    required bool isActive,
  }) async {
    final Result<SubscriptionPackage> result = await ref
        .read(subscriptionServiceProvider)
        .updatePackage(
          id: id,
          name: name,
          description: description,
          maxChildren: maxChildren,
          includedSubjectIds: includedSubjectIds,
          priceCents: priceCents,
          durationDays: durationDays,
          isActive: isActive,
        );
    result.when(
      success: (SubscriptionPackage updated) {
        final List<SubscriptionPackage> current =
            List<SubscriptionPackage>.from(state.valueOrNull ?? <SubscriptionPackage>[]);
        final int idx = current.indexWhere((SubscriptionPackage p) => p.id == id);
        if (idx != -1) {
          current[idx] = updated;
          state = AsyncValue<List<SubscriptionPackage>>.data(current);
        }
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> deletePackage(String id) async {
    final Result<void> result =
        await ref.read(subscriptionServiceProvider).deletePackage(id);
    result.when(
      success: (_) {
        final List<SubscriptionPackage> current =
            List<SubscriptionPackage>.from(state.valueOrNull ?? <SubscriptionPackage>[]);
        current.removeWhere((SubscriptionPackage p) => p.id == id);
        state = AsyncValue<List<SubscriptionPackage>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<SubscriptionPackage>> toggleActive(
      String id, bool isActive) async {
    final Result<SubscriptionPackage> result = await ref
        .read(subscriptionServiceProvider)
        .togglePackageActive(id, isActive);
    result.when(
      success: (SubscriptionPackage updated) {
        final List<SubscriptionPackage> current =
            List<SubscriptionPackage>.from(state.valueOrNull ?? <SubscriptionPackage>[]);
        final int idx = current.indexWhere((SubscriptionPackage p) => p.id == id);
        if (idx != -1) {
          current[idx] = updated;
          state = AsyncValue<List<SubscriptionPackage>>.data(current);
        }
      },
      failure: (_) {},
    );
    return result;
  }
}
