class FineType {
  final int id;
  final String key; // API fine_type_key
  final String name;
  final int amount; // default or configured amount
  final bool adjustable; // whether amount can be overridden on assign
  FineType({
    required this.id,
    required this.key,
    required this.name,
    required this.amount,
    this.adjustable = false,
  });
}

class FineRecord {
  final int id;
  final int memberId;
  final FineType type;
  final DateTime date;
  final bool paid;
  final int amount; // UGX amount
  final String? reason;
  final DateTime? paidAt;
  final int? transactionId;
  final Map<String, dynamic>? member;
  final Map<String, dynamic>? meeting;

  FineRecord({
    required this.id,
    required this.memberId,
    required this.type,
    required this.date,
    required this.paid,
    required this.amount,
    this.reason,
    this.paidAt,
    this.transactionId,
    this.member,
    this.meeting,
  });
}
