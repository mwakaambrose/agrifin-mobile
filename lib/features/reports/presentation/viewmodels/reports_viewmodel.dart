import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/api/reports_api_repository.dart';
import '../../../shareout/data/api/shareout_api_repository.dart';

class ReportSummary {
  final String title;
  final String value;
  final double? amount;
  ReportSummary(this.title, this.value, {this.amount});
}

class ProfitAndLossItem {
  final String label;
  final double amount; // positive for income, negative for expenses
  ProfitAndLossItem(this.label, this.amount);
}

class ProfitAndLossReport {
  final List<ProfitAndLossItem> items;
  ProfitAndLossReport(this.items);
  double get totalIncome =>
      items.where((e) => e.amount > 0).fold(0, (p, e) => p + e.amount);
  double get totalExpenses =>
      items.where((e) => e.amount < 0).fold(0, (p, e) => p + e.amount.abs());
  double get net => totalIncome - totalExpenses;
}

class ReportsViewModel extends BaseViewModel {
  List<ReportSummary> summaries = [];
  List<ReportSummary> interestSummaries = [];
  ProfitAndLossReport? pnl;
  ShareoutDto? shareout;
  String? shareoutError;
  bool executingShareout = false;
  Map<String, dynamic>? cycle;

  bool get isCycleClosing {
    final c = cycle;
    if (c == null) return false;
    final status = c['status']?.toString().toLowerCase();
    if (status != null &&
        (status.contains('closing') || status == 'closing_out')) {
      return true;
    }
    final isClosing = c['is_closing'];
    if (isClosing is bool) return isClosing;
    if (isClosing is num) return isClosing != 0;
    return false;
  }

  bool get canExecuteShareout =>
      isCycleClosing && (shareout?.executedAt == null);

  Future<void> load(int cycleId) async {
    setBusy(true);
    try {
      // Load cycle summary
      final dto = await ReportsApiRepository().cycleSummary(cycleId);
      cycle = dto.cycle;
      final metrics = dto.metrics;
      final totalSavings = (metrics['total_savings'] as num? ?? 0).toDouble();
      final totalOutstandingLoan =
          (metrics['outstanding_loans'] as num? ?? 0).toDouble();
      final finesCollected =
          (metrics['fines_collected'] as num? ?? 0).toDouble();
      final socialFund =
          (metrics['social_funds_total'] as num? ?? 0).toDouble();
      summaries = [
        ReportSummary(
          'Total Savings',
          'UGX ${totalSavings.toStringAsFixed(0)}',
          amount: totalSavings,
        ),
        ReportSummary(
          'Outstanding Loans',
          'UGX ${totalOutstandingLoan.toStringAsFixed(0)}',
          amount: totalOutstandingLoan,
        ),
        ReportSummary(
          'Fines Collected',
          'UGX ${finesCollected.toStringAsFixed(0)}',
          amount: finesCollected,
        ),
        ReportSummary(
          'Social Fund',
          'UGX ${socialFund.toStringAsFixed(0)}',
          amount: socialFund,
        ),
      ];

      // Process interest summaries
      // final totalInterestEarned =
      //     (metrics['total_interest_earned'] as num? ?? 0).toDouble();
      final totalInterestPaid =
          (metrics['total_interest_paid'] as num? ?? 0).toDouble();
      interestSummaries = [
        // ReportSummary(
        //   'Interest Earned',
        //   'UGX ${totalInterestEarned.toStringAsFixed(0)}',
        //   amount: totalInterestEarned,
        // ),
        ReportSummary(
          'Interest Earned',
          'UGX ${totalInterestPaid.toStringAsFixed(0)}',
          amount: totalInterestPaid,
        ),
      ];

      final pnlMap = dto.profitAndLoss;
      final items = <ProfitAndLossItem>[];
      pnlMap.forEach((k, v) {
        if (v is num) {
          items.add(
            ProfitAndLossItem(k.toString().replaceAll('_', ' '), v.toDouble()),
          );
        }
      });
      pnl = ProfitAndLossReport(items);

      // Load shareout data (don't fail the whole load if this errors)
      try {
        shareoutError = null;
        shareout = await ShareoutApiRepository().get(cycleId);
      } catch (e) {
        shareout = null;
        shareoutError = e.toString();
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> reloadShareout(int cycleId) async {
    try {
      shareoutError = null;
      shareout = await ShareoutApiRepository().get(cycleId);
      notifyListeners();
    } catch (e) {
      shareout = null;
      shareoutError = e.toString();
      notifyListeners();
    }
  }

  Future<bool> executeShareout(int cycleId) async {
    if (!canExecuteShareout) {
      shareoutError = 'Shareout can only be executed during cycle closure.';
      notifyListeners();
      return false;
    }
    executingShareout = true;
    notifyListeners();
    try {
      await ShareoutApiRepository().execute(cycleId);
      await reloadShareout(cycleId);
      return true;
    } catch (e) {
      shareoutError = e.toString();
      return false;
    } finally {
      executingShareout = false;
      notifyListeners();
    }
  }
}
