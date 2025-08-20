import 'package:flutter/foundation.dart';

class Member {
  final String id;
  String name;
  String role;
  String phone;
  DateTime joinedOn;
  double totalSavings;
  double outstandingLoans;

  Member({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.joinedOn,
    required this.totalSavings,
    required this.outstandingLoans,
  });

  Member copyWith({
    String? name,
    String? role,
    String? phone,
    double? totalSavings,
    double? outstandingLoans,
  }) => Member(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    phone: phone ?? this.phone,
    joinedOn: joinedOn,
    totalSavings: totalSavings ?? this.totalSavings,
    outstandingLoans: outstandingLoans ?? this.outstandingLoans,
  );
}

class MemberViewModel extends ChangeNotifier {
  Member _member = Member(
    id: 'M1',
    name: 'Waiswa Steven',
    role: 'Group Leader',
    phone: '+256700000000',
    joinedOn: DateTime.now().subtract(const Duration(days: 600)),
    totalSavings: 550000,
    outstandingLoans: 45000,
  );

  bool _loading = false;
  String? _error;

  Member get member => _member;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _loading = false;
    notifyListeners();
  }

  void updatePhone(String phone) {
    _member = _member.copyWith(phone: phone);
    notifyListeners();
  }

  void updateRole(String role) {
    _member = _member.copyWith(role: role);
    notifyListeners();
  }

  void addSavings(double amount) {
    _member = _member.copyWith(totalSavings: _member.totalSavings + amount);
    notifyListeners();
  }

  void adjustOutstandingLoan(double delta) {
    _member = _member.copyWith(
      outstandingLoans: (_member.outstandingLoans + delta).clamp(
        0,
        double.infinity,
      ),
    );
    notifyListeners();
  }
}

// Legacy MemberProfileViewModel - consider removal after migration.
// class MemberProfile {
//   final String id;
//   String name;
//   String role;
//   String phone;
//   DateTime joinedOn;
//   double totalSavings;
//   double outstandingLoans;

//   MemberProfile({
//     required this.id,
//     required this.name,
//     required this.role,
//     required this.phone,
//     required this.joinedOn,
//     required this.totalSavings,
//     required this.outstandingLoans,
//   });

//   MemberProfile copyWith({
//     String? name,
//     String? role,
//     String? phone,
//     double? totalSavings,
//     double? outstandingLoans,
//   }) => MemberProfile(
//     id: id,
//     name: name ?? this.name,
//     role: role ?? this.role,
//     phone: phone ?? this.phone,
//     joinedOn: joinedOn,
//     totalSavings: totalSavings ?? this.totalSavings,
//     outstandingLoans: outstandingLoans ?? this.outstandingLoans,
//   );
// }

// class MemberViewModel extends ChangeNotifier {
//   MemberProfile _member = MemberProfile(
//     id: 'M1',
//     name: 'Waiswa Steven',
//     role: 'Group Leader',
//     phone: '+256700000000',
//     joinedOn: DateTime.now().subtract(const Duration(days: 600)),
//     totalSavings: 550000,
//     outstandingLoans: 45000,
//   );

//   bool _loading = false;
//   String? _error;

//   MemberProfile get member => _member;
//   bool get isLoading => _loading;
//   String? get error => _error;

//   Future<void> refresh() async {
//     _loading = true;
//     _error = null;
//     notifyListeners();
//     await Future.delayed(const Duration(milliseconds: 400));
//     _loading = false;
//     notifyListeners();
//   }

//   void updatePhone(String phone) {
//     _member = _member.copyWith(phone: phone);
//     notifyListeners();
//   }

//   void updateRole(String role) {
//     _member = _member.copyWith(role: role);
//     notifyListeners();
//   }

//   void addSavings(double amount) {
//     _member = _member.copyWith(totalSavings: _member.totalSavings + amount);
//     notifyListeners();
//   }

//   void adjustOutstandingLoan(double delta) {
//     _member = _member.copyWith(
//       outstandingLoans: (_member.outstandingLoans + delta).clamp(
//         0,
//         double.infinity,
//       ),
//     );
//     notifyListeners();
//   }
// }
