import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/payment_transaction.dart';
import '../../../domain/entities/subscription_package.dart';
import '../../controllers/parent_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../controllers/parent_subscription_controller.dart';

/// Payment checkout screen.
///
/// States:
///   1. Idle      — shows package summary + "Proceed to Payment" button.
///   2. Creating  — loading indicator while bill is being created.
///   3. Ready     — bill created; user is prompted to open ToyyibPay in browser.
///   4. Waiting   — browser opened; polls every [_pollSecs] seconds for status.
///   5. Done      — final status received; navigates to confirmation.
class PaymentCheckoutScreen extends ConsumerStatefulWidget {
  const PaymentCheckoutScreen({super.key, required this.package});
  final SubscriptionPackage package;

  @override
  ConsumerState<PaymentCheckoutScreen> createState() =>
      _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState
    extends ConsumerState<PaymentCheckoutScreen> {
  static const int _pollSecs = 5;

  bool _browserOpened = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Bill creation ──────────────────────────────────────────────────────────

  Future<void> _createBill() async {
    final profile = ref.read(parentControllerProvider).valueOrNull;
    if (profile == null) return;

    await ref.read(paymentCheckoutControllerProvider.notifier).createBill(
          package: widget.package,
          parentId: profile.parentId,
          parentName: profile.fullName,
          parentEmail: profile.email,
        );
  }

  // ── Open ToyyibPay ─────────────────────────────────────────────────────────

  Future<void> _openPaymentUrl(String url) async {
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open browser. Copy and paste this URL:\n$url',
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }
    if (launched) {
      setState(() => _browserOpened = true);
      _startPolling();
    }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    final PaymentCheckoutState state =
        ref.read(paymentCheckoutControllerProvider);
    if (state is! PaymentCheckoutReady) return;
    final String billCode = state.transaction.billCode;

    _pollTimer = Timer.periodic(
      const Duration(seconds: _pollSecs),
      (_) => _checkStatus(billCode),
    );
  }

  Future<void> _checkStatus(String billCode) async {
    final result = await ref
        .read(paymentCheckoutControllerProvider.notifier)
        .pollBillCode(billCode);

    if (result != null && result.status.isFinal) {
      _pollTimer?.cancel();
      if (mounted) {
        context.pushReplacement(
          AppRoutes.paymentStatus,
          extra: PaymentStatusArgs(
            transaction: result,
            package: widget.package,
          ),
        );
      }
    }
  }

  // ── Manual verify ──────────────────────────────────────────────────────────

  Future<void> _manualVerify(String billCode) async {
    _pollTimer?.cancel();
    final result = await ref
        .read(paymentCheckoutControllerProvider.notifier)
        .verifyBillCode(billCode);

    if (result != null && mounted) {
      context.pushReplacement(
        AppRoutes.paymentStatus,
        extra: PaymentStatusArgs(
          transaction: result,
          package: widget.package,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(paymentCheckoutControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: checkoutState is PaymentCheckoutCreating
            ? const SizedBox.shrink()
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: switch (checkoutState) {
            PaymentCheckoutIdle() => _IdleBody(
                package: widget.package,
                onProceed: _createBill,
              ),
            PaymentCheckoutCreating() => const _CreatingBody(),
            PaymentCheckoutReady(:final transaction) => _ReadyBody(
                transaction: transaction,
                browserOpened: _browserOpened,
                onOpenBrowser: () => _openPaymentUrl(transaction.paymentUrl),
                onVerify: () => _manualVerify(transaction.billCode),
              ),
            PaymentCheckoutError(:final message) => _ErrorBody(
                message: message,
                onRetry: () {
                  ref
                      .read(paymentCheckoutControllerProvider.notifier)
                      .reset();
                },
              ),
          },
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _IdleBody extends StatelessWidget {
  const _IdleBody(
      {super.key, required this.package, required this.onProceed});
  final SubscriptionPackage package;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Order summary card
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Order Summary',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                        )),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: 'Package',
                  value: package.name,
                  cs: cs,
                ),
                _SummaryRow(
                  label: 'Duration',
                  value: '${package.durationDays} days',
                  cs: cs,
                ),
                _SummaryRow(
                  label: 'Subjects',
                  value: '${package.includedSubjectIds.length} included',
                  cs: cs,
                ),
                _SummaryRow(
                  label: 'Children',
                  value: 'Up to ${package.maxChildren}',
                  cs: cs,
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Total',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: cs.onPrimaryContainer),
                    ),
                    Text(
                      package.priceDisplay,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Info note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.info_outline,
                  size: 18, color: cs.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You will be redirected to ToyyibPay to complete your payment '
                  'securely. After payment, return to this app to confirm.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSecondaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onProceed,
            icon: const Icon(Icons.payment_outlined),
            label: const Text('Proceed to Payment'),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {super.key,
      required this.label,
      required this.value,
      required this.cs});
  final String label;
  final String value;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onPrimaryContainer.withOpacity(0.7),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatingBody extends StatelessWidget {
  const _CreatingBody({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Preparing your payment...'),
        ],
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    super.key,
    required this.transaction,
    required this.browserOpened,
    required this.onOpenBrowser,
    required this.onVerify,
  });
  final PaymentTransaction transaction;
  final bool browserOpened;
  final VoidCallback onOpenBrowser;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 24),
        Icon(
          browserOpened
              ? Icons.hourglass_top_outlined
              : Icons.open_in_browser_outlined,
          size: 64,
          color: cs.primary,
        ),
        const SizedBox(height: 16),
        Text(
          browserOpened
              ? 'Waiting for payment...'
              : 'Your payment page is ready',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          browserOpened
              ? 'Complete your payment in the browser. This screen will '
                'update automatically once your payment is confirmed.'
              : 'Tap the button below to open the ToyyibPay payment page in '
                'your browser.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.outline,
              ),
        ),
        const SizedBox(height: 32),
        if (!browserOpened)
          FilledButton.icon(
            onPressed: onOpenBrowser,
            icon: const Icon(Icons.open_in_browser_outlined),
            label: const Text('Open Payment Page'),
          )
        else ...<Widget>[
          if (browserOpened)
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onVerify,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("I've completed the payment"),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Bill Code: ${transaction.billCode}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.outline,
              ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody(
      {super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Payment Unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

/// Arguments object passed via `GoRouter.extra` to [PaymentStatusScreen].
class PaymentStatusArgs {
  const PaymentStatusArgs({
    required this.transaction,
    required this.package,
  });
  final PaymentTransaction transaction;
  final SubscriptionPackage package;
}
