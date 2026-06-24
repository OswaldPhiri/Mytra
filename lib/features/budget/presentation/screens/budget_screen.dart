import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../providers/app_providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBudgetsAsync = ref.watch(allBudgetsProvider);
    final summaryAsync = ref.watch(budgetSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(AppConstants.routeAddBudget),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Current Budget Summary
          summaryAsync.when(
            loading: () => const SizedBox(height: 120),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) {
              if (summary.budget == null) {
                return _buildNoBudget(context);
              }
              return _buildActiveSummary(context, summary);
            },
          ),
          const SizedBox(height: 24),
          const Text('Budget History',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          allBudgetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (budgets) {
              if (budgets.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No budgets yet', style: TextStyle(color: Colors.grey, fontFamily: 'Inter')),
                  ),
                );
              }
              return Column(
                children: budgets
                    .map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _BudgetCard(
                            budget: b,
                            onEdit: () => context.push('/budget/edit/${b.id}'),
                            onDelete: () => _confirmDelete(context, ref, b.id),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routeAddBudget),
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
        backgroundColor: AppColors.seedColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildActiveSummary(BuildContext context, BudgetSummary summary) {
    final theme = Theme.of(context);
    final pct = summary.usagePercentage;
    final isOver = summary.remaining < 0;
    final barColor = isOver ? AppColors.expense : pct > 0.8 ? Colors.orange : AppColors.income;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Budget',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: const Text('Active',
                    style: TextStyle(fontFamily: 'Inter', color: AppColors.income, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(summary.budget!.name,
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(
            '${DateTime.now().formattedMonth}',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(pct * 100).toStringAsFixed(0)}% used',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: barColor, fontWeight: FontWeight.w600)),
              Text('${summary.totalExpenses.compactCurrency} / ${summary.budget!.amount.compactCurrency}',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                    label: 'Remaining',
                    value: summary.remaining.formattedCurrency,
                    color: isOver ? AppColors.expense : AppColors.income),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryChip(
                    label: 'Spent', value: summary.totalExpenses.formattedCurrency, color: AppColors.expense),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoBudget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('No Active Budget',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Create a budget to start tracking your spending',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontFamily: 'Inter')),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push(AppConstants.routeAddBudget),
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget', style: TextStyle(fontFamily: 'Inter')),
        content: const Text('Are you sure?', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(budgetNotifierProvider.notifier).deleteBudget(id);
    }
  }
}

class _BudgetCard extends StatelessWidget {
  final budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({required this.budget, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime(budget.year, budget.month);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(budget.name,
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(date.formattedMonth,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          Text(budget.amount.formattedCurrency,
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(fontFamily: 'Inter'))),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontFamily: 'Inter', color: AppColors.expense))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: color.withOpacity(0.8))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
