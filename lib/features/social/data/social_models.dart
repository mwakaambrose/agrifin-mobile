class SocialContribution {
  final int id;
  final int meetingId;
  final int memberId;
  final String? memberName;
  final int amount;
  final DateTime date;
  SocialContribution({
    required this.id,
    required this.meetingId,
    required this.memberId,
    this.memberName,
    required this.amount,
    required this.date,
  });
}

class SocialBalance {
  final int cycleId;
  final int balance;
  SocialBalance({required this.cycleId, required this.balance});
}
