enum TransactionType { savings, loanDisbursement, loanRepayment, fine, social }

class TransactionRecord {
  final int id;
  final TransactionType type;
  final DateTime date;
  final int amount; // UGX integer
  final String? memberName; // optional context
  final String? description;

  TransactionRecord({
    required this.id,
    required this.type,
    required this.date,
    required this.amount,
    this.memberName,
    this.description,
  });
}
