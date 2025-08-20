import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/api/reports_api_repository.dart';

class ReportSummary {
  final String title;
  final String value;
  ReportSummary(this.title, this.value);
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

  Future<void> load(int cycleId) async {
    setBusy(true);
    try {
      final dto = await ReportsApiRepository().cycleSummary(cycleId);
      final metrics = dto.metrics;
      final totalSavings = (metrics['total_savings'] as num? ?? 0).toDouble();
      final totalOutstandingLoan =
          (metrics['total_outstanding_loan'] as num? ?? 0).toDouble();
      final finesCollected =
          (metrics['fines_collected'] as num? ?? 0).toDouble();
      final socialFund =
          (metrics['social_fund_balance'] as num? ?? 0).toDouble();
      summaries = [
        ReportSummary(
          'Total Savings',
          'UGX ${totalSavings.toStringAsFixed(0)}',
        ),
        ReportSummary(
          'Outstanding Loans',
          'UGX ${totalOutstandingLoan.toStringAsFixed(0)}',
        ),
        ReportSummary(
          'Fines Collected',
          'UGX ${finesCollected.toStringAsFixed(0)}',
        ),
        ReportSummary('Social Fund', 'UGX ${socialFund.toStringAsFixed(0)}'),
      ];

      // Process interest summaries
      final totalInterestEarned =
          (metrics['total_interest_earned'] as num? ?? 0).toDouble();
      final totalInterestPaid =
          (metrics['total_interest_paid'] as num? ?? 0).toDouble();
      interestSummaries = [
        ReportSummary(
          'Interest Earned',
          'UGX ${totalInterestEarned.toStringAsFixed(0)}',
        ),
        ReportSummary(
          'Interest Paid',
          'UGX ${totalInterestPaid.toStringAsFixed(0)}',
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
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }
}
