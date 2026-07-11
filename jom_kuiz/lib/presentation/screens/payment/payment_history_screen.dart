import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/payment_transaction.dart';
import '../../controllers/parent_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Shows the authenticated parent's full payment transaction history.
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(parentControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: profileState.when(
        loading: () => const LoadingWidget(message: 'Loading...'),
        error: (err, _) => AppErrorWidget(message: err.toString()),
        data: (profile) {
          if (profile == null) {
            return const AppErrorWidget(message: 'Profile unavailable');
          }
          return _HistoryBody(parentId: profile.parentId);
        },
      ),
    );
  }
}

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({super.key, required this.parentId});
  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState =
        ref.watch(paymentHistoryControllerProvider(parentId));

    return historyState.when(
      loading: () => const LoadingWidget(message: 'Loading history...'),
      error: (err, _) => AppErrorWidget(
        message: err.toString(),
        onRetry: () => ref
            .read(paymentHistoryControllerProvider(parentId).notifier)
            .refresh(),
      ),
      data: (List<PaymentTransaction> transactions) {
        if (transactions.isEmpty) {
          return const _EmptyHistory();
        }
        return RefreshIndicator(
          onRefresh: () => ref
              .read(paymentHistoryControllerProvider(parentId).notifier)
              .refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) =>
                _TransactionCard(transaction: transactions[index]),
          ),
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({super.key, required this.transaction});
  final PaymentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color statusColor = _statusColor(transaction.status, cs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _formatDate(transaction.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                        ),
                  ),
                ),
                _StatusBadge(status: transaction.status, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Bill: ${transaction.billCode}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (transaction.transactionId != null)
                        Text(
                          'Ref: ${transaction.transactionId}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      if (transaction.paymentMethod != null)
                        Text(
                          transaction.paymentMethod!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatAmount(transaction.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (transaction.paidAt != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Paid: ${_formatDate(transaction.paidAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(PaymentTransactionStatus status, ColorScheme cs) {
    switch (status) {
      case PaymentTransactionStatus.success:
        return Colors.green.shade700;
      case PaymentTransactionStatus.pending:
        return Colors.orange.shade700;
      case PaymentTransactionStatus.failed:
        return cs.error;
      case PaymentTransactionStatus.expired:
        return cs.outline;
    }
  }

  String _formatDate(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)}';
  }

  String _formatAmount(int cents) =>
      'RM ${(cents / 100).toStringAsFixed(2)}';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(
      {super.key, required this.status, required this.color});
  final PaymentTransactionStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.displayLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No payment history yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
