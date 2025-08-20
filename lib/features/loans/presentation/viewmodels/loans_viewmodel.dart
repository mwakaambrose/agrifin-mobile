import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/loan_models.dart';
import '../../data/loan_repository.dart';

class LoansViewModel extends BaseViewModel {
  final LoanRepository _repo;
  LoansViewModel(this._repo);

  List<LoanApplication> loans = [];

  Future<void> load(int cycleId) async {
    setBusy(true);
    setError(null);
    try {
      loans = await _repo.listLoans(cycleId: cycleId);
    } catch (e) {
      setError('Failed to load loans');
      loans = [];
    } finally {
      setBusy(false);
    }
  }

  Future<bool> applyLoan({
    required int meetingId,
    required int memberId,
    required int amount,
    required int termWeeks,
    required InterestType interestType,
    required double interestRate,
    required String purpose,
  }) async {
    setBusy(true);
    setError(null);
    try {
      final app = await _repo.apply(
        meetingId: meetingId,
        memberId: memberId,
        amount: amount,
        durationWeeks: termWeeks,
        interestRate: interestRate.toInt(),
        interestType: interestType,
        purpose: purpose,
      );
      loans = [app, ...loans];
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to apply for loan');
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> repayLoan({
    required int meetingId,
    required int loanId,
    required int amount,
  }) async {
    setError(null);
    try {
      await _repo.repay(meetingId: meetingId, loanId: loanId, amount: amount);
      // Update local state: mark the first unpaid installment as paid
      final idx = loans.indexWhere((l) => l.id == loanId);
      if (idx != -1) {
        final loan = loans[idx];
        final schedule = loan.schedule ?? const [];
        final unpaidIndex = schedule.indexWhere((s) => !s.paid);
        if (unpaidIndex != -1) {
          final updatedSchedule = [
            for (var i = 0; i < schedule.length; i++)
              i == unpaidIndex
                  ? LoanRepaymentScheduleItem(
                    installment: schedule[i].installment,
                    dueDate: schedule[i].dueDate,
                    principal: schedule[i].principal,
                    interest: schedule[i].interest,
                    total: schedule[i].total,
                    paid: true,
                  )
                  : schedule[i],
          ];
          loans[idx] = LoanApplication(
            id: loan.id,
            memberId: loan.memberId,
            memberName: loan.memberName,
            memberPhone: loan.memberPhone,
            amount: loan.amount,
            termWeeks: loan.termWeeks,
            interestType: loan.interestType,
            interestRate: loan.interestRate,
            purpose: loan.purpose,
            status: loan.status,
            schedule: updatedSchedule,
          );
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      setError('Failed to repay loan');
      return false;
    }
  }
}
