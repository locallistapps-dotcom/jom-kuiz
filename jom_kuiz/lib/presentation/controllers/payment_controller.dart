import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/subscription_package.dart';
import '../providers/payment_providers.dart';
import '../providers/subscription_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Checkout controller — creates the bill and holds the pending transaction.
// ═══════════════════════════════════════════════════════════════════════════

sealed class PaymentCheckoutState {
  const PaymentCheckoutState();
}

class PaymentCheckoutIdle extends PaymentCheckoutState {
  const PaymentCheckoutIdle();
}

class PaymentCheckoutCreating extends PaymentCheckoutState {
  const PaymentCheckoutCreating();
}

/// Bill created — contains the pending transaction the UI should open.
class PaymentCheckoutReady extends PaymentCheckoutState {
  const PaymentCheckoutReady(this.transaction);
  final PaymentTransaction transaction;
}

class PaymentCheckoutError extends PaymentCheckoutState {
  const PaymentCheckoutError(this.message);
  final String message;
}

final AutoDisposeNotifierProvider<PaymentCheckoutController,
        PaymentCheckoutState> paymentCheckoutControllerProvider =
    NotifierProvider.autoDispose<PaymentCheckoutController,
        PaymentCheckoutState>(PaymentCheckoutController.new);

class PaymentCheckoutController
    extends AutoDisposeNotifier<PaymentCheckoutState> {
  @override
  PaymentCheckoutState build() => const PaymentCheckoutIdle();

  /// Creates a ToyyibPay bill.
  ///
  /// [parentId], [parentName], [parentEmail] come from [ParentProfile].
  Future<void> createBill({
    required SubscriptionPackage package,
    required String parentId,
    required String parentName,
    required String parentEmail,
  }) async {
    state = const PaymentCheckoutCreating();

    final Result<PaymentTransaction> result =
        await ref.read(paymentServiceProvider).createBill(
              parentId: parentId,
              package: package,
              parentName: parentName,
              parentEmail: parentEmail,
            );

    result.when(
      success: (PaymentTransaction tx) {
        state = PaymentCheckoutReady(tx);
      },
      failure: (Failure f) {
        state = PaymentCheckoutError(f.message);
      },
    );
  }

  void reset() => state = const PaymentCheckoutIdle();

  /// Lightweight poll — reads the DB record for [billCode] without calling
  /// ToyyibPay. Returns the transaction or `null` on failure.
  Future<PaymentTransaction?> pollBillCode(String billCode) async {
    final Result<PaymentTransaction?> result =
        await ref.read(paymentServiceProvider).pollStatus(billCode);
    return result.when(
      success: (PaymentTransaction? tx) => tx,
      failure: (_) => null,
    );
  }

  /// Server-side verify — calls ToyyibPay via the Edge Function and activates
  /// the subscription if payment was successful.
  Future<PaymentTransaction?> verifyBillCode(String billCode) async {
    final Result<PaymentTransaction> result =
        await ref.read(paymentServiceProvider).verifyPayment(billCode);
    return result.when(
      success: (PaymentTransaction tx) => tx,
      failure: (_) => null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Status polling controller — polls payment_transactions for a bill code.
// ═══════════════════════════════════════════════════════════════════════════

final AutoDisposeAsyncNotifierProviderFamily<PaymentStatusController,
        PaymentTransaction?, String> paymentStatusControllerProvider =
    AsyncNotifierProvider.autoDispose.family<PaymentStatusController,
        PaymentTransaction?, String>(PaymentStatusController.new);

/// Polls the local `payment_transactions` record every [_pollIntervalSecs]
/// seconds until the status is final (success / failed / expired).
///
/// On reaching a final state it also calls [verifyPayment] so the server
/// double-checks directly with ToyyibPay and activates the subscription.
class PaymentStatusController
    extends AutoDisposeFamilyAsyncNotifier<PaymentTransaction?, String> {
  static const int _pollIntervalSecs = 5;

  Timer? _timer;

  @override
  Future<PaymentTransaction?> build(String arg) async {
    // arg = billCode
    ref.onDispose(() => _timer?.cancel());
    final PaymentTransaction? tx = await _poll();
    if (tx != null && !tx.status.isFinal) {
      _startPolling();
    }
    return tx;
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: _pollIntervalSecs),
      (_) => _tick(),
    );
  }

  Future<void> _tick() async {
    final PaymentTransaction? tx = await _poll();
    if (tx != null && tx.status.isFinal) {
      _timer?.cancel();
      // Trigger server-side verification so subscription is activated.
      if (tx.status == PaymentTransactionStatus.success) {
        await ref.read(paymentServiceProvider).verifyPayment(arg);
        // Invalidate subscription state so dashboard reflects new subscription.
        ref.invalidate(subscriptionServiceProvider);
      }
    }
  }

  Future<PaymentTransaction?> _poll() async {
    final Result<PaymentTransaction?> result =
        await ref.read(paymentServiceProvider).pollStatus(arg);
    final PaymentTransaction? tx = result.when(
      success: (PaymentTransaction? t) => t,
      failure: (_) => state.valueOrNull,
    );
    state = AsyncValue<PaymentTransaction?>.data(tx);
    return tx;
  }

  /// Manual verify — called when the user returns from the browser and taps
  /// "I've completed the payment". Forces a server-side verification.
  Future<Result<PaymentTransaction>> verify() async {
    state = const AsyncValue<PaymentTransaction?>.loading();
    final Result<PaymentTransaction> result =
        await ref.read(paymentServiceProvider).verifyPayment(arg);
    result.when(
      success: (PaymentTransaction tx) {
        state = AsyncValue<PaymentTransaction?>.data(tx);
        if (tx.status.isFinal) {
          _timer?.cancel();
          if (tx.isSuccess) {
            ref.invalidate(subscriptionServiceProvider);
          }
        }
      },
      failure: (Failure f) {
        state = AsyncValue<PaymentTransaction?>.error(f, StackTrace.current);
      },
    );
    return result;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Payment history controller — parent's transaction list.
// ═══════════════════════════════════════════════════════════════════════════

final AutoDisposeAsyncNotifierProviderFamily<PaymentHistoryController,
        List<PaymentTransaction>, String> paymentHistoryControllerProvider =
    AsyncNotifierProvider.autoDispose.family<PaymentHistoryController,
        List<PaymentTransaction>, String>(PaymentHistoryController.new);

class PaymentHistoryController
    extends AutoDisposeFamilyAsyncNotifier<List<PaymentTransaction>, String> {
  @override
  Future<List<PaymentTransaction>> build(String arg) async {
    // arg = parentId
    final Result<List<PaymentTransaction>> result =
        await ref.read(paymentServiceProvider).getParentTransactions(arg);
    return result.when(
      success: (List<PaymentTransaction> list) => list,
      failure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<PaymentTransaction>>.loading();
    state = await AsyncValue.guard(() async {
      final Result<List<PaymentTransaction>> result =
          await ref.read(paymentServiceProvider).getParentTransactions(arg);
      return result.when(
          success: (List<PaymentTransaction> list) => list,
          failure: (f) => throw f);
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Admin payment controller — all transactions with search & filter.
// ═══════════════════════════════════════════════════════════════════════════

class AdminPaymentFilter {
  const AdminPaymentFilter({this.status, this.parentId});
  final String? status;
  final String? parentId;

  AdminPaymentFilter copyWith({String? status, String? parentId}) =>
      AdminPaymentFilter(
        status: status ?? this.status,
        parentId: parentId ?? this.parentId,
      );
}

final StateProvider<AdminPaymentFilter> adminPaymentFilterProvider =
    StateProvider<AdminPaymentFilter>(
        (_) => const AdminPaymentFilter());

final AutoDisposeAsyncNotifierProvider<AdminPaymentController,
        List<PaymentTransaction>> adminPaymentControllerProvider =
    AsyncNotifierProvider.autoDispose<AdminPaymentController,
        List<PaymentTransaction>>(AdminPaymentController.new);

class AdminPaymentController
    extends AutoDisposeAsyncNotifier<List<PaymentTransaction>> {
  @override
  Future<List<PaymentTransaction>> build() async {
    final AdminPaymentFilter filter =
        ref.watch(adminPaymentFilterProvider);
    final Result<List<PaymentTransaction>> result =
        await ref.read(paymentServiceProvider).getAllTransactions(
              status: filter.status,
              parentId: filter.parentId?.isNotEmpty == true
                  ? filter.parentId
                  : null,
            );
    return result.when(
      success: (List<PaymentTransaction> list) => list,
      failure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<PaymentTransaction>>.loading();
    state = await AsyncValue.guard(() => build());
  }
}
