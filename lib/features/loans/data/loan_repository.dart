import 'loan_models.dart';
import 'api/loans_api_repository.dart';

class LoanRepository {
  LoanRepository({LoansApiRepository? api})
    : _api = api ?? LoansApiRepository();
  final LoansApiRepository _api;

  Future<List<LoanApplication>> listLoans({required int cycleId}) async {
    final res = await _api.list(cycleId);
    return res.data
        .map(
          (l) => LoanApplication(
            id: l.id,
            memberId: (l.member?['id'] as int?) ?? 0,
            memberName: l.member?['name'] as String?,
            memberPhone: l.member?['phone'] as String?,
            amount: l.amount.toInt(),
            termWeeks: l.durationWeeks,
            interestType:
                l.interestType == 'reducing_balance'
                    ? InterestType.reducing
                    : InterestType.flat,
            interestRate: l.interestRate,
            purpose: l.purpose,
            status: l.status,
            schedule:
                l.schedule
                    .map(
                      (s) => LoanRepaymentScheduleItem(
                        installment: s.installment,
                        dueDate: DateTime.now(),
                        principal: s.principal.toInt(),
                        interest: s.interest.toInt(),
                        total: s.total.toInt(),
                        paid: s.isPaid,
                      ),
                    )
                    .toList(),
          ),
        )
        .toList();
  }

  Future<List<LoanRepaymentScheduleItem>> getSchedule(int loanId) async {
    final loan = await _api.show(loanId);
    // Schedule is included in show response
    return loan.schedule
        .map(
          (s) => LoanRepaymentScheduleItem(
            installment: s.installment,
            dueDate:
                DateTime.now(), // API does not include due date per item; keep now.
            principal: s.principal.toInt(),
            interest: s.interest.toInt(),
            total: s.total.toInt(),
            paid: s.isPaid,
          ),
        )
        .toList();
  }

  Future<LoanApplication> apply({
    required int meetingId,
    required int memberId,
    required int amount,
    int? durationWeeks,
    int? interestRate,
    InterestType? interestType,
    String? purpose,
  }) async {
    final created = await _api.apply(
      meetingId: meetingId,
      memberId: memberId,
      amount: amount.toDouble(),
      durationWeeks: durationWeeks,
      interestRate: interestRate?.toDouble(),
      interestType:
          interestType == null
              ? null
              : (interestType == InterestType.reducing
                  ? 'reducing_balance'
                  : 'flat'),
      purpose: purpose,
    );
    return LoanApplication(
      id: created.id,
      memberId: (created.member?['id'] as int?) ?? memberId,
      memberName: created.member?['name'] as String?,
      memberPhone: created.member?['phone'] as String?,
      amount: created.amount.toInt(),
      termWeeks: created.durationWeeks,
      interestType:
          created.interestType == 'reducing_balance'
              ? InterestType.reducing
              : InterestType.flat,
      interestRate: created.interestRate,
      purpose: created.purpose,
      status: created.status,
      schedule:
          created.schedule
              .map(
                (s) => LoanRepaymentScheduleItem(
                  installment: s.installment,
                  dueDate: DateTime.now(),
                  principal: s.principal.toInt(),
                  interest: s.interest.toInt(),
                  total: s.total.toInt(),
                  paid: s.isPaid,
                ),
              )
              .toList(),
    );
  }

  Future<void> repay({
    required int meetingId,
    required int loanId,
    required int amount,
  }) async {
    await _api.repay(
      meetingId: meetingId,
      loanId: loanId,
      amount: amount.toDouble(),
    );
  }
}
