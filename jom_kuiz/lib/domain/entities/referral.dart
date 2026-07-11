import 'package:equatable/equatable.dart';

/// A referral record linking a referrer to a new user.
class Referral extends Equatable {
  const Referral({
    required this.referralId,
    required this.referrerId,
    required this.code,
    required this.rewardPoints,
    required this.createdAt,
    this.refereeId,
    this.isUsed = false,
    this.usedAt,
  });

  final String referralId;

  /// User who generated the referral code.
  final String referrerId;

  /// User who signed up using this code (null until redeemed).
  final String? refereeId;

  /// The unique referral code string.
  final String code;

  /// Points awarded to the referrer on successful redemption.
  final int rewardPoints;

  final bool isUsed;
  final DateTime createdAt;
  final DateTime? usedAt;

  @override
  List<Object?> get props => <Object?>[
        referralId,
        referrerId,
        refereeId,
        code,
        rewardPoints,
        isUsed,
        createdAt,
        usedAt,
      ];
}
