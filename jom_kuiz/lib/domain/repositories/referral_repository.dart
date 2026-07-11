import '../../core/utils/result.dart';
import '../entities/referral.dart';

/// Abstract contract for referral-code operations.
abstract interface class ReferralRepository {
  /// Returns the referral record for [referrerId] (creates one if absent).
  Future<Result<Referral>> getReferral({required String referrerId});

  /// Applies a [code] for a new [refereeId], awarding points to the referrer.
  Future<Result<Referral>> applyReferral({
    required String code,
    required String refereeId,
  });
}
