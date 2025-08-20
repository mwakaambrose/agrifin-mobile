import 'package:flutter/foundation.dart';

class FineItem {
  final String id;
  final String memberName;
  final String reason;
  final double amount;
  final DateTime date;
  bool paid;

  FineItem({
    required this.id,
    required this.memberName,
    required this.reason,
    required this.amount,
    required this.date,
    this.paid = false,
  });
}

class FinesViewModel extends ChangeNotifier {
  final List<FineItem> _fines = [
    FineItem(
      id: 'f1',
      memberName: 'John Doe',
      reason: 'Late to meeting',
      amount: 2000,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FineItem(
      id: 'f2',
      memberName: 'Jane Smith',
      reason: 'Missed savings contribution',
      amount: 5000,
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    FineItem(
      id: 'f3',
      memberName: 'Peter Okello',
      reason: 'Absent without notice',
      amount: 8000,
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  bool _loading = false;
  String? _error;

  List<FineItem> get fines => List.unmodifiable(_fines);
  bool get isLoading => _loading;
  String? get error => _error;
  double get totalOutstanding =>
      _fines.where((f) => !f.paid).fold(0.0, (sum, f) => sum + f.amount);
  int get unpaidCount => _fines.where((f) => !f.paid).length;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _loading = false;
    notifyListeners();
  }

  void markPaid(String id) {
    final idx = _fines.indexWhere((f) => f.id == id);
    if (idx == -1) return;
    _fines[idx] = FineItem(
      id: _fines[idx].id,
      memberName: _fines[idx].memberName,
      reason: _fines[idx].reason,
      amount: _fines[idx].amount,
      date: _fines[idx].date,
      paid: true,
    );
    notifyListeners();
  }

  void addFine({
    required String memberName,
    required String reason,
    required double amount,
    DateTime? date,
  }) {
    _fines.add(
      FineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        memberName: memberName,
        reason: reason,
        amount: amount,
        date: date ?? DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void removeFine(String id) {
    _fines.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  void clearPaid() {
    _fines.removeWhere((f) => f.paid);
    notifyListeners();
  }
}
