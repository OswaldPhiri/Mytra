import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../providers/app_providers.dart';
import '../../../../data/database/tables/tables.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);

    return recentAsync.when(
      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (e, _) => const SizedBox.shrink(),
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmpty(context);
        }
        return Column(
          children: transactions
              .map((tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TransactionTile(transaction: tx),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('No transactions yet',
                style: TextStyle(color: Colors.grey, fontFamily: 'Inter')),
            SizedBox(height: 4),
            Text('SMS messages will appear here automatically',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}

/// Reusable transaction tile
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.transactionType == 'expense';
    final date = DateTime.fromMillisecondsSinceEpoch(transaction.date);
    final color = AppColors.getCategoryColor(transaction.category);

    return GestureDetector(
      onTap: onTap ?? () => context.push('/transactions/${transaction.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(transaction.category),
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Description + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.category,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                      if (showDate) ...[
                        const SizedBox(width: 6),
                        Text(
                          date.relativeTime,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isExpense ? '-' : '+'}${transaction.amount.formattedCurrency}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isExpense ? AppColors.expense : AppColors.income,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'food' => Icons.restaurant_rounded,
      'transport' => Icons.directions_car_rounded,
      'utilities' => Icons.bolt_rounded,
      'rent' => Icons.home_rounded,
      'entertainment' => Icons.movie_rounded,
      'shopping' => Icons.shopping_bag_rounded,
      'salary' => Icons.payments_rounded,
      'transfers' => Icons.swap_horiz_rounded,
      'savings' => Icons.savings_rounded,
      _ => Icons.receipt_rounded,
    };
  }
}
