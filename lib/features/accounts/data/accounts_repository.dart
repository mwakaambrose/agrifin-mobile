import 'account_model.dart';

class AccountsRepository {
  Future<List<Account>> listAccounts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Account(id: '1', name: 'Main Account', balance: 250000.0),
      Account(id: '2', name: 'Social Fund', balance: 35000.0),
      Account(id: '3', name: 'Fines & Fees', balance: 12000.0),
    ];
  }
}
