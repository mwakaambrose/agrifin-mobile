import 'package:flutter/foundation.dart';

class SummaryMetric {
  final String label;
  final double value;
  final String unit; // e.g. 'UGX', '%'
  SummaryMetric({required this.label, required this.value, required this.unit});
}

class ReportsViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  // mock aggregated values
  double _totalSavings = 120000;
  double _outstandingLoans = 45000;
  double _fineIncome = 9000;
  double _socialFund = 15000;
  double _averageAttendance = 0.87; // 87%

  bool get isLoading => _loading;
  String? get error => _error;

  double get totalSavings => _totalSavings;
  double get outstandingLoans => _outstandingLoans;
  double get fineIncome => _fineIncome;
  double get socialFund => _socialFund;
  double get averageAttendance => _averageAttendance;

  List<SummaryMetric> get dashboardMetrics => [
    SummaryMetric(label: 'Total Savings', value: _totalSavings, unit: 'UGX'),
    SummaryMetric(
      label: 'Outstanding Loans',
      value: _outstandingLoans,
      unit: 'UGX',
    ),
    SummaryMetric(label: 'Fine Income', value: _fineIncome, unit: 'UGX'),
    SummaryMetric(label: 'Social Fund', value: _socialFund, unit: 'UGX'),
    SummaryMetric(
      label: 'Attendance',
      value: _averageAttendance * 100,
      unit: '%',
    ),
  ];

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    // Here you would load fresh figures from repositories/services
    _loading = false;
    notifyListeners();
  }

  // Update mutators for integrating data sources later
  void updateSavings(double v) {
    _totalSavings = v;
    notifyListeners();
  }

  void updateOutstandingLoans(double v) {
    _outstandingLoans = v;
    notifyListeners();
  }

  void updateFineIncome(double v) {
    _fineIncome = v;
    notifyListeners();
  }

  void updateSocialFund(double v) {
    _socialFund = v;
    notifyListeners();
  }

  void updateAttendance(double ratio) {
    _averageAttendance = ratio.clamp(0, 1);
    notifyListeners();
  }
}
