import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/income.dart';
import '../../core/models/expense.dart';
import '../../providers/income_provider.dart';
import '../../providers/expense_provider.dart';
import 'transaction_list_item.dart';
import 'add_transaction_dialog.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentIncomes = ref.watch(recentIncomeProvider);
    final recentExpenses = ref.watch(recentExpenseProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to transactions screen
                    // This would typically use a router or navigator
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTransactionsList(recentIncomes, recentExpenses, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    AsyncValue<List<Income>> recentIncomes,
    AsyncValue<List<Expense>> recentExpenses,
    WidgetRef ref,
  ) {
    return recentIncomes.when(
      loading: () => recentExpenses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: CircularProgressIndicator()),
        data: (expenses) => const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => recentExpenses.when(
        loading: () => Center(
          child: Text(
            'Error loading incomes: $error',
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
        error: (expenseError, expenseStack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading transactions',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again later',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        data: (expenses) => Center(
          child: Text(
            'Error loading incomes: $error',
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      ),
      data: (incomes) => recentExpenses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading expenses: $error',
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
        data: (expenses) {
          // Combine and sort transactions by date
          final List<dynamic> allTransactions = [
            ...incomes,
            ...expenses,
          ];

          if (allTransactions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No recent transactions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add your first transaction to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort by date (most recent first)
          allTransactions.sort((a, b) {
            final dateA = a is Income ? a.date : (a as Expense).date;
            final dateB = b is Income ? b.date : (b as Expense).date;
            return dateB.compareTo(dateA);
          });

          // Take only the first 5 transactions
          final recentTransactions = allTransactions.take(5).toList();

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTransactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = recentTransactions[index];
              
              return TransactionListItem(
                transaction: transaction,
                onTap: () {
                  // Show details dialog similar to transactions screen
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(transaction is Income ? 'Income Details' : 'Expense Details'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category: ' +
                              (transaction is Income
                                  ? (transaction.category?.name ?? 'Uncategorized')
                                  : (transaction as Expense).category?.name ?? 'Uncategorized')),
                          const SizedBox(height: 8),
                          Text('Amount: ' + (transaction is Income
                              ? transaction.amount.toString()
                              : (transaction as Expense).amount.toString())),
                          const SizedBox(height: 8),
                          Text('Date: ' + (transaction is Income
                              ? transaction.date.toString()
                              : (transaction as Expense).date.toString())),
                          if ((transaction is Income ? transaction.note : (transaction as Expense).note)?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text('Notes: ' + ((transaction is Income ? transaction.note : (transaction as Expense).note) ?? '')),
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                onEdit: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddTransactionDialog(
                      type: transaction is Income ? 'income' : 'expense',
                      transaction: transaction,
                      isEditing: true,
                    ),
                  );
                },
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Transaction'),
                      content: Text(
                        'Are you sure you want to delete this ' +
                            (transaction is Income ? 'income' : 'expense') +
                            ' entry?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              final container = ProviderScope.containerOf(context);
                              if (transaction is Income) {
                                await container.read(incomeNotifierProvider.notifier).deleteIncome(transaction.id!);
                              } else {
                                await container.read(expenseNotifierProvider.notifier).deleteExpense((transaction as Expense).id!);
                              }
                              // Refresh recent lists
                              container.invalidate(recentIncomeProvider);
                              container.invalidate(recentExpenseProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete transaction: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleEditTransaction(dynamic transaction) {
    // TODO: Implement edit functionality
    // This could navigate to an edit screen or show a dialog
  }

  void _handleDeleteTransaction(dynamic transaction) {
    // TODO: Implement delete functionality
    // This could show a confirmation dialog and then delete the transaction
  }
}