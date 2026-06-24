import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../providers/app_providers.dart';

class StatsRow extends ConsumerWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(budgetSummaryProvider);
    final theme = Theme.of(context);

    return summaryAsync.when(
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) => Row(
        children: [
          _StatCard(
            label: 'Income',
            value: summary.totalIncome.compactCurrency,
            icon: Icons.arrow_downward_rounded,
            color: AppColors.income,
            backgroundColor: AppColors.income.withOpacity(0.1),
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Expenses',
            value: summary.totalExpenses.compactCurrency,
            icon: Icons.arrow_upward_rounded,
            color: AppColors.expense,
            backgroundColor: AppColors.expense.withOpacity(0.1),
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Budget %',
            value: '${(summary.usagePercentage * 100).toStringAsFixed(0)}%',
            icon: Icons.donut_small_rounded,
            color: AppColors.seedColor,
            backgroundColor: AppColors.seedColor.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
