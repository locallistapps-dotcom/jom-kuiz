import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/payment_transaction.dart';
import '../../controllers/payment_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Admin screen — view all payment transactions with search and filter.
class AdminPaymentScreen extends ConsumerStatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  ConsumerState<AdminPaymentScreen> createState() =>
      _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends ConsumerState<AdminPaymentScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _localSearch = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const List<_StatusOption> _statusOptions = <_StatusOption>[
    _StatusOption(label: 'All', value: null),
    _StatusOption(label: 'Paid', value: 'success'),
    _StatusOption(label: 'Pending', value: 'pending'),
    _StatusOption(label: 'Failed', value: 'failed'),
    _StatusOption(label: 'Expired', value: 'expired'),
  ];

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(adminPaymentFilterProvider);
    final state = ref.watch(adminPaymentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                ref.read(adminPaymentControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // ── Filters ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: <Widget>[
                // Search by parent ID prefix
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by parent ID or bill code…',
                    prefixIcon: const Icon(Icons.search_outlined),
                    suffixIcon: _localSearch.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _localSearch = '');
                            },
                          )
                        : null,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setState(() => _localSearch = v.toLowerCase()),
                ),
                const SizedBox(height: 8),

                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((opt) {
                      final bool selected = filter.status == opt.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(opt.label),
                          selected: selected,
                          onSelected: (_) {
                            ref
                                .read(adminPaymentFilterProvider.notifier)
                                .state = filter.copyWith(
                              status: opt.value,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Summary strip ─────────────────────────────────────────────────
          state.whenData((transactions) {
            final int total = transactions.length;
            final int success = transactions
                .where((t) => t.isSuccess)
                .length;
            final int pending = transactions
                .where((t) => t.isPending)
                .length;
            final int failed = transactions
                .where((t) => t.isFailed || t.isExpired)
                .length;
            final int totalRevenueSen = transactions
                .where((t) => t.isSuccess)
                .fold(0, (sum, t) => sum + t.amount);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _SummaryChip(
                          label: 'Total',
                          value: '$total',
                          color: Theme.of(context).colorScheme.primary),
                      _SummaryChip(
                          label: 'Paid',
                          value: '$success',
                          color: Colors.green.shade600),
                      _SummaryChip(
                          label: 'Pending',
                          value: '$pending',
                          color: Colors.orange.shade600),
                      _SummaryChip(
                          label: 'Failed',
                          value: '$failed',
                          color: Theme.of(context).colorScheme.error),
                      _SummaryChip(
                          label: 'Revenue',
                          value:
                              'RM ${(totalRevenueSen / 100).toStringAsFixed(0)}',
                          color:
                              Theme.of(context).colorScheme.tertiary),
                    ],
                  ),
                ),
              ),
            );
          }).valueOrNull ??
              const SizedBox.shrink(),

          // ── Transaction list ──────────────────────────────────────────────
          Expanded(
            child: state.when(
              loading: () =>
                  const LoadingWidget(message: 'Loading payments...'),
              error: (err, _) => AppErrorWidget(
                message: err.toString(),
                onRetry: () => ref
                    .read(adminPaymentControllerProvider.notifier)
                    .refresh(),
              ),
              data: (List<PaymentTransaction> transactions) {
                // Apply local search filter.
                final List<PaymentTransaction> filtered =
                    _localSearch.isEmpty
                        ? transactions
                        : transactions
                            .where((t) =>
                                t.parentId
                                    .toLowerCase()
                                    .contains(_localSearch) ||
                                t.billCode
                                    .toLowerCase()
                                    .contains(_localSearch) ||
                                (t.transactionId
                                        ?.toLowerCase()
                                        .contains(_localSearch) ??
                                    false))
                            .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No transactions found.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _AdminTransactionCard(transaction: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption({required this.label, required this.value});
  final String label;
  final String? value;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(
      {super.key,
      required this.label,
      required this.value,
      required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }
}

class _AdminTransactionCard extends StatelessWidget {
  const _AdminTransactionCard({super.key, required this.transaction});
  final PaymentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color statusColor = _statusColor(transaction.status, cs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    transaction.billCode,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    transaction.status.displayLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _Info(
                icon: Icons.person_outline,
                text:
                    'Parent: ${transaction.parentId.substring(0, 8)}…'),
            _Info(
                icon: Icons.payments_outlined,
                text:
                    'RM ${(transaction.amount / 100).toStringAsFixed(2)}'),
            if (transaction.transactionId != null)
              _Info(
                  icon: Icons.confirmation_number_outlined,
                  text: 'Ref: ${transaction.transactionId}'),
            if (transaction.paymentMethod != null)
              _Info(
                  icon: Icons.credit_card_outlined,
                  text: transaction.paymentMethod!),
            _Info(
                icon: Icons.access_time_outlined,
                text: _fmtDate(transaction.createdAt)),
            if (transaction.paidAt != null)
              _Info(
                  icon: Icons.check_circle_outline,
                  text: 'Paid: ${_fmtDate(transaction.paidAt!)}',
                  color: Colors.green.shade700),
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

  String _fmtDate(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}';
  }
}

class _Info extends StatelessWidget {
  const _Info(
      {super.key,
      required this.icon,
      required this.text,
      this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: <Widget>[
          Icon(icon,
              size: 14,
              color: color ?? Theme.of(context).colorScheme.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
