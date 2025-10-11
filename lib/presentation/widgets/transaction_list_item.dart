import 'package:flutter/material.dart';
import '../../core/models/income.dart';
import '../../core/models/expense.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/currency_provider.dart';

class TransactionListItem extends StatelessWidget {
  final dynamic transaction; // Can be Income or Expense
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction is Income;
    final amount = isIncome 
        ? (transaction as Income).amount 
        : (transaction as Expense).amount;
    final category = isIncome 
        ? (transaction as Income).category 
        : (transaction as Expense).category;
    final date = isIncome 
        ? (transaction as Income).date 
        : (transaction as Expense).date;
    final notes = isIncome 
        ? (transaction as Income).note 
        : (transaction as Expense).note;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        onLongPress: onEdit,
        leading: CircleAvatar(
          backgroundColor: isIncome 
              ? Colors.green.withOpacity(0.1) 
              : Colors.red.withOpacity(0.1),
          child: Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          notes ?? 'No description',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category?.name ?? 'Unknown Category'),
            Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (notes?.isNotEmpty == true)
              Text(
                notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer(builder: (context, ref, _) {
              final formatted = ref.read(currencyProvider.notifier).format(amount);
              return Text(
                '${isIncome ? '+' : '-'}$formatted',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              );
            }),
            const SizedBox(width: 8),
            PopupMenuButton<int>(
              onSelected: (value) {
                if (value == 1) {
                  onEdit?.call();
                } else if (value == 2) {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<int>(value: 1, child: Text('Edit')),
                const PopupMenuItem<int>(value: 2, child: Text('Delete')),
              ],
            ),
          ],
        ),
        isThreeLine: false,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}