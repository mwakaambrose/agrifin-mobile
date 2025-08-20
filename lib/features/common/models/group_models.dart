class GroupProfile {
  final int id;
  final String name;
  final String region;
  final String district;
  final double? lat;
  final double? lng;

  GroupProfile({
    required this.id,
    required this.name,
    required this.region,
    required this.district,
    this.lat,
    this.lng,
  });
}

class Cycle {
  final int id;
  final int group_id;
  final DateTime startDate;
  final DateTime endDate;

  Cycle({
    required this.id,
    required this.group_id,
    required this.startDate,
    required this.endDate,
  });
}

class ConstitutionConfig {
  final int cycleId;
  final int savingsAmount;
  final double loanInterestRate; // percent
  final bool interestReducingBalance;
  final int socialFundAmount;
  final int? guarantorCount;
  final String meetingFrequency; // weekly/monthly

  ConstitutionConfig({
    required this.cycleId,
    required this.savingsAmount,
    required this.loanInterestRate,
    required this.interestReducingBalance,
    required this.socialFundAmount,
    this.guarantorCount,
    required this.meetingFrequency,
  });
}
