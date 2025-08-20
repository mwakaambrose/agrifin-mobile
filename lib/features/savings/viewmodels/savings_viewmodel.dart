import 'package:flutter/foundation.dart';

class SavingsEntry {
  final String id;
  final String memberId;
  double amount;
  DateTime date;

  SavingsEntry({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.date,
  });
}

class SavingsViewModel extends ChangeNotifier {
  final List<SavingsEntry> _entries = [
    SavingsEntry(
      id: 's1',
      memberId: 'M1',
      amount: 10000,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SavingsEntry(
      id: 's2',
      memberId: 'M2',
      amount: 15000,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SavingsEntry(
      id: 's3',
      memberId: 'M1',
      amount: 12000,
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  bool _loading = false;
  String? _error;

  List<SavingsEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _loading;
  String? get error => _error;
  double get totalSavings => _entries.fold(0.0, (s, e) => s + e.amount);

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _loading = false;
    notifyListeners();
  }

  void addEntry({
    required String memberId,
    required double amount,
    DateTime? date,
  }) {
    _entries.add(
      SavingsEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        memberId: memberId,
        amount: amount,
        date: date ?? DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void removeEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<SavingsEntry> memberEntries(String memberId) =>
      _entries.where((e) => e.memberId == memberId).toList(growable: false);
}
