class SavingsAccountSummary {
  final int balance;
  final int cycleId;
  SavingsAccountSummary({required this.balance, required this.cycleId});
}

class SavingsTransaction {
  final int id;
  final int memberId;
  final DateTime date;
  final int amount;
  final String? note;
  final String? memberName;

  SavingsTransaction({
    required this.id,
    required this.memberId,
    required this.date,
    required this.amount,
    this.note,
    this.memberName,
  });
}

class SavingsData {
  final SavingsAccountSummary summary;
  final List<SavingsTransaction> transactions;
  SavingsData({required this.summary, required this.transactions});
}
