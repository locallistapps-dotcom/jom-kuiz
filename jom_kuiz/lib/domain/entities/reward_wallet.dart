import 'package:equatable/equatable.dart';

/// The reason a wallet transaction occurred.
enum WalletTransactionType { earned, redeemed, expired, adjusted }

/// A single credit or debit in the wallet ledger.
class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.transactionId,
    required this.type,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  final String transactionId;
  final WalletTransactionType type;

  /// Positive for credits, negative for debits.
  final int points;
  final String description;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
        transactionId,
        type,
        points,
        description,
        createdAt,
      ];
}

/// A user's reward-points wallet.
class RewardWallet extends Equatable {
  const RewardWallet({
    required this.walletId,
    required this.userId,
    required this.balance,
    this.transactions = const <WalletTransaction>[],
  });

  final String walletId;
  final String userId;

  /// Current available points balance.
  final int balance;
  final List<WalletTransaction> transactions;

  @override
  List<Object?> get props => <Object?>[walletId, userId, balance, transactions];
}
