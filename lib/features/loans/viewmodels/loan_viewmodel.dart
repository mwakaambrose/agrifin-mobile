import 'package:flutter/foundation.dart';

class LoanRecord {
  final String id;
  final String memberId;
  double principal;
  double balance;
  double interestRate; // annual simple for mock
  DateTime issuedOn;
  DateTime? dueDate;
  bool closed;

  LoanRecord({
    required this.id,
    required this.memberId,
    required this.principal,
    required this.balance,
    required this.interestRate,
    required this.issuedOn,
    this.dueDate,
    this.closed = false,
  });

  LoanRecord copyWith({
    double? principal,
    double? balance,
    double? interestRate,
    DateTime? issuedOn,
    DateTime? dueDate,
    bool? closed,
  }) => LoanRecord(
    id: id,
    memberId: memberId,
    principal: principal ?? this.principal,
    balance: balance ?? this.balance,
    interestRate: interestRate ?? this.interestRate,
    issuedOn: issuedOn ?? this.issuedOn,
    dueDate: dueDate ?? this.dueDate,
    closed: closed ?? this.closed,
  );
}

class LoanViewModel extends ChangeNotifier {
  final List<LoanRecord> _loans = [
    LoanRecord(
      id: 'L1',
      memberId: 'M1',
      principal: 50000,
      balance: 32000,
      interestRate: 0.10,
      issuedOn: DateTime.now().subtract(const Duration(days: 40)),
      dueDate: DateTime.now().add(const Duration(days: 50)),
    ),
    LoanRecord(
      id: 'L2',
      memberId: 'M2',
      principal: 80000,
      balance: 80000,
      interestRate: 0.12,
      issuedOn: DateTime.now().subtract(const Duration(days: 5)),
      dueDate: DateTime.now().add(const Duration(days: 85)),
    ),
  ];

  bool _loading = false;
  String? _error;

  List<LoanRecord> get loans => List.unmodifiable(_loans);
  bool get isLoading => _loading;
  String? get error => _error;
  double get totalOutstanding =>
      _loans.where((l) => !l.closed).fold(0.0, (s, l) => s + l.balance);

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _loading = false;
    notifyListeners();
  }

  void recordRepayment(String id, double amount) {
    final idx = _loans.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    final loan = _loans[idx];
    final newBalance = (loan.balance - amount).clamp(0, double.infinity);
    _loans[idx] = loan.copyWith(
      balance: newBalance.toDouble(),
      closed: newBalance == 0,
    );
    notifyListeners();
  }

  void addLoan({
    required String memberId,
    required double principal,
    required double interestRate,
    DateTime? issuedOn,
    DateTime? dueDate,
  }) {
    final loan = LoanRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: memberId,
      principal: principal,
      balance: principal,
      interestRate: interestRate,
      issuedOn: issuedOn ?? DateTime.now(),
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 90)),
    );
    _loans.add(loan);
    notifyListeners();
  }
}
