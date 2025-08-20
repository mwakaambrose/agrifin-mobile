import 'transaction_models.dart';
import 'api/transactions_api_repository.dart';

class TransactionsRepository {
  TransactionsRepository({TransactionsApiRepository? api})
    : _api = api ?? TransactionsApiRepository();
  final TransactionsApiRepository _api;

  Future<List<TransactionRecord>> listAll({
    required int cycleId,
    TransactionType? filter,
  }) async {
    final res = await _api.list(
      cycleId: cycleId,
      type: filter == null ? null : _mapType(filter),
    );
    return res.data
        .map(
          (t) => TransactionRecord(
            id: t.id,
            type: _mapTypeBack(t.type),
            date: t.createdAt,
            amount: t.amount.toInt(),
            memberName:
                t.member != null ? (t.member!['name'] as String? ?? '') : '',
            description: t.description ?? '',
          ),
        )
        .toList();
  }

  String _mapType(TransactionType t) {
    switch (t) {
      case TransactionType.savings:
        return 'saving';
      case TransactionType.loanDisbursement:
        return 'loan_disbursement';
      case TransactionType.loanRepayment:
        return 'loan_repayment';
      case TransactionType.fine:
        return 'fine';
      case TransactionType.social:
        return 'welfare_contribution';
    }
  }

  TransactionType _mapTypeBack(String s) {
    switch (s) {
      case 'saving':
        return TransactionType.savings;
      case 'loan_disbursement':
        return TransactionType.loanDisbursement;
      case 'loan_repayment':
        return TransactionType.loanRepayment;
      case 'fine':
        return TransactionType.fine;
      case 'welfare_contribution':
      case 'welfare_disbursement':
        return TransactionType.social;
      default:
        return TransactionType.savings;
    }
  }
}
