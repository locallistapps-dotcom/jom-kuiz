import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/payment_transaction.dart';
import '../../../domain/entities/subscription_package.dart';

/// Displays the final payment result (success, failed, or expired).
///
/// Receives a [PaymentTransaction] and [SubscriptionPackage] via
/// `GoRouterState.extra` as a `_PaymentResultArgs` map.
class PaymentStatusScreen extends StatelessWidget {
  const PaymentStatusScreen({
    super.key,
    required this.transaction,
    required this.package,
  });

  final PaymentTransaction transaction;
  final SubscriptionPackage package;

  @override
  Widget build(BuildContext context) {
    final bool success = transaction.isSuccess;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              // Status icon
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: success
                        ? Colors.green.shade100
                        : cs.errorContainer,
                  ),
                  child: Icon(
                    success
                        ? Icons.check_circle_outline_rounded
                        : transaction.isExpired
                            ? Icons.timer_off_outlined
                            : Icons.cancel_outlined,
                    size: 56,
                    color: success ? Colors.green.shade700 : cs.error,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                success
                    ? 'Payment Successful!'
                    : transaction.isExpired
                        ? 'Payment Expired'
                        : 'Payment Failed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: success ? Colors.green.shade700 : cs.error,
                    ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                success
                    ? 'Your subscription to "${package.name}" is now active. '
                      'All included subjects have been unlocked for your children.'
                    : transaction.isExpired
                        ? 'The payment session expired. Please try subscribing again.'
                        : 'Your payment could not be processed. '
                          'Please try again or use a different payment method.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              // Transaction detail card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      _DetailRow(
                          label: 'Package', value: package.name),
                      _DetailRow(
                          label: 'Amount', value: package.priceDisplay),
                      _DetailRow(
                        label: 'Status',
                        value: transaction.status.displayLabel,
                        valueColor: success
                            ? Colors.green.shade700
                            : cs.error,
                      ),
                      if (transaction.transactionId != null)
                        _DetailRow(
                          label: 'Ref No.',
                          value: transaction.transactionId!,
                        ),
                      if (transaction.paymentMethod != null)
                        _DetailRow(
                          label: 'Method',
                          value: transaction.paymentMethod!,
                        ),
                      if (transaction.paidAt != null)
                        _DetailRow(
                          label: 'Paid at',
                          value: _formatDate(transaction.paidAt!),
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // CTA buttons
              if (success) ...<Widget>[
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Go to Dashboard'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.subscription),
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('View Subscription'),
                ),
              ] else ...<Widget>[
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.subscription),
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Try Again'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  child: const Text('Back to Dashboard'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
