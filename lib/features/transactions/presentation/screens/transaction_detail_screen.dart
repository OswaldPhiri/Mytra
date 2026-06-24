import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../providers/app_providers.dart';
import '../../../../data/database/tables/tables.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final int id;
  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionByIdProvider(id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        actions: [
          txAsync.whenData((tx) => tx != null
              ? IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                  onPressed: () => _confirmDelete(context, ref, tx),
                )
              : const SizedBox.shrink()).value ?? const SizedBox.shrink(),
        ],
      ),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tx) {
          if (tx == null) return const Center(child: Text('Transaction not found'));
          return _buildDetail(context, ref, tx);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Transaction tx) {
    final theme = Theme.of(context);
    final isExpense = tx.transactionType == 'expense';
    final date = DateTime.fromMillisecondsSinceEpoch(tx.date);
    final color = AppColors.getCategoryColor(tx.category);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Amount card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isExpense
                ? AppColors.expense.withOpacity(0.1)
                : AppColors.income.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpense
                  ? AppColors.expense.withOpacity(0.3)
                  : AppColors.income.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: isExpense ? AppColors.expense : AppColors.income,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                '${isExpense ? '-' : '+'}${tx.amount.formattedCurrency}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isExpense ? AppColors.expense : AppColors.income,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tx.description,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Details card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(label: 'Date', value: date.formattedDateTime, icon: Icons.calendar_today_outlined),
                const Divider(height: 16),
                _DetailRow(label: 'Category', value: tx.category, icon: Icons.label_outline, valueColor: color),
                const Divider(height: 16),
                _DetailRow(label: 'Source', value: tx.source.toUpperCase(), icon: Icons.source_outlined),
                if (tx.sender != null) ...[
                  const Divider(height: 16),
                  _DetailRow(label: 'Sender', value: tx.sender!, icon: Icons.sms_outlined),
                ],
                if (tx.referenceNumber != null) ...[
                  const Divider(height: 16),
                  _DetailRow(label: 'Reference', value: tx.referenceNumber!, icon: Icons.tag_rounded),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Edit category
        _CategoryEditor(transaction: tx),
        const SizedBox(height: 16),
        // Raw message
        if (tx.rawMessage != null && tx.rawMessage!.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Original Message',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    tx.rawMessage!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction', style: TextStyle(fontFamily: 'Inter')),
        content: const Text('This action cannot be undone.', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(transactionNotifierProvider.notifier).deleteTransaction(tx.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

class _CategoryEditor extends ConsumerStatefulWidget {
  final Transaction transaction;
  const _CategoryEditor({required this.transaction});

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late String _category;

  @override
  void initState() {
    super.initState();
    _category = widget.transaction.category;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Category',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.defaultCategories.map((cat) {
                final selected = cat == _category;
                final color = AppColors.getCategoryColor(cat);
                return GestureDetector(
                  onTap: () async {
                    setState(() => _category = cat);
                    await ref.read(transactionNotifierProvider.notifier).updateTransaction(
                          widget.transaction.toCompanion(true).copyWith(
                                category: Value(cat),
                                isManuallyEdited: const Value(true),
                              ),
                        );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? color : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
