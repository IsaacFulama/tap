import 'package:flutter_test/flutter_test.dart';
import 'package:untitled11/pages/finance/finance.dart';
import 'package:untitled11/pages/finance/modelfinance.dart';

TransactionModel _transaction({
  required String type,
  required double amount,
  String currency = 'USD',
  String category = 'General',
  String fund = 'Général',
}) {
  return TransactionModel(
    type: type,
    categorie: category,
    montant: amount,
    date: DateTime(2026, 1, 15),
    description: 'Test transaction',
    evenement: '',
    fondAssocie: fund,
    donateur: 'Test',
    devise: currency,
  );
}

void main() {
  group('ChurchFinanceEngine', () {
    test('converts CDF transactions to USD before calculating the balance', () {
      final engine = ChurchFinanceEngine(
        transactions: [
          _transaction(type: 'entree', amount: 200),
          _transaction(type: 'sortie', amount: 142500, currency: 'CDF'),
        ],
        budgetMensuel: 250,
        tauxChange: 2850,
      );

      expect(engine.totalEntreesUSD, 200);
      expect(engine.totalSortiesUSD, 50);
      expect(engine.soldeGlobalUSD, 150);
    });

    test('calculates the budget consumption ratio from expenses', () {
      final engine = ChurchFinanceEngine(
        transactions: [
          _transaction(type: 'sortie', amount: 100),
          _transaction(type: 'sortie', amount: 50),
        ],
        budgetMensuel: 250,
      );

      expect(engine.tauxConsommationBudget, 0.6);
    });

    test('returns no expense category when there are no outgoing transactions', () {
      final engine = ChurchFinanceEngine(
        transactions: [_transaction(type: 'entree', amount: 100)],
        budgetMensuel: 250,
      );

      expect(engine.categorieLaPlusDepensiere, 'Aucune');
    });
  });
}
