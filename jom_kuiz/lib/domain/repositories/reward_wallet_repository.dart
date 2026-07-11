import '../../core/utils/result.dart';
import '../entities/reward_wallet.dart';

/// Abstract contract for reward-wallet operations.
abstract interface class RewardWalletRepository {
  /// Returns the wallet and transaction history for [userId].
  Future<Result<RewardWallet>> getWallet({required String userId});

  /// Redeems [points] from [userId]'s wallet for a given [reason].
  Future<Result<RewardWallet>> redeemPoints({
    required String userId,
    required int points,
    required String reason,
  });
}
