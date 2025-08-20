enum InterestType { flat, reducing }

class LoanApplication {
  final int id;
  final int memberId;
  final String? memberName;
  final String? memberPhone;
  final int amount;
  final int termWeeks;
  final InterestType interestType;
  final double interestRate; // percent per term unit
  final String purpose;
  final String status; // pending, approved, rejected, disbursed
  final List<LoanRepaymentScheduleItem>? schedule;

  LoanApplication({
    required this.id,
    required this.memberId,
    this.memberName,
    this.memberPhone,
    required this.amount,
    required this.termWeeks,
    required this.interestType,
    required this.interestRate,
    required this.purpose,
    required this.status,
    this.schedule,
  });
}

class LoanRepaymentScheduleItem {
  final int installment;
  final DateTime dueDate;
  final int principal;
  final int interest;
  final int total;
  final bool paid;

  LoanRepaymentScheduleItem({
    required this.installment,
    required this.dueDate,
    required this.principal,
    required this.interest,
    required this.total,
    required this.paid,
  });
}
