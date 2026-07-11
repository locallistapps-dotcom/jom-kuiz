import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/parent_subscription.dart';
import '../../domain/entities/subscription_package.dart';
import '../providers/subscription_providers.dart';

/// Holds the authenticated parent's current subscription state.
///
/// Keyed by [parentId] so the controller can be scoped correctly when
/// used in both the parent dashboard and the admin subscriber list.
final AutoDisposeAsyncNotifierProviderFamily<ParentSubscriptionController,
        ParentSubscription?, String>
    parentSubscriptionControllerProvider = AsyncNotifierProvider.autoDispose
        .family<ParentSubscriptionController, ParentSubscription?, String>(
            ParentSubscriptionController.new);

class ParentSubscriptionController
    extends AutoDisposeFamilyAsyncNotifier<ParentSubscription?, String> {
  @override
  Future<ParentSubscription?> build(String arg) async {
    // arg = parentId
    final Result<ParentSubscription?> result = await ref
        .read(subscriptionServiceProvider)
        .getSubscription(arg);
    return result.when(
      success: (ParentSubscription? s) => s,
      failure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<ParentSubscription?>.loading();
    state = await AsyncValue.guard(() async {
      final Result<ParentSubscription?> result = await ref
          .read(subscriptionServiceProvider)
          .getSubscription(arg);
      return result.when(
          success: (ParentSubscription? s) => s, failure: (f) => throw f);
    });
  }

  /// Activates a new subscription using the given [package].
  ///
  /// Reserved for use by the Payment module. The UI currently exposes this
  /// as a placeholder until payment integration is completed.
  Future<Result<ParentSubscription>> activate(
      SubscriptionPackage package) async {
    final Result<ParentSubscription> result = await ref
        .read(subscriptionServiceProvider)
        .activateSubscription(parentId: arg, package: package);
    result.when(
      success: (ParentSubscription s) {
        state = AsyncValue<ParentSubscription?>.data(s);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<ParentSubscription>> cancel() async {
    final ParentSubscription? current = state.valueOrNull;
    if (current == null) {
      return const Result<ParentSubscription>.failure(
        ValidationFailure('No active subscription to cancel', 'SUB-005'),
      );
    }
    final Result<ParentSubscription> result = await ref
        .read(subscriptionServiceProvider)
        .cancelSubscription(current.id);
    result.when(
      success: (ParentSubscription s) {
        state = AsyncValue<ParentSubscription?>.data(s);
      },
      failure: (_) {},
    );
    return result;
  }
}
