class ReferralSummary {
  final String referralCode;
  final int referredCount;
  final int earnedPatitas;
  final String shareMessage;

  const ReferralSummary({
    required this.referralCode,
    required this.referredCount,
    required this.earnedPatitas,
    required this.shareMessage,
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    return ReferralSummary(
      referralCode: json['referral_code'] as String,
      referredCount: json['referred_count'] as int? ?? 0,
      earnedPatitas: json['earned_patitas'] as int? ?? 0,
      shareMessage: json['share_message'] as String? ?? '',
    );
  }
}
