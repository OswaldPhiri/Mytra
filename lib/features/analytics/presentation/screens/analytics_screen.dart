import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/extensions.dart';
import '../../dashboard/presentation/widgets/spending_chart_widget.dart';
import '../../dashboard/presentation/widgets/category_pie_chart.dart';
import '../../../../providers/app_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(budgetSummaryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Total Spending 
          summaryAsync.when(
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Total Spending This Month', 
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    summary.totalExpenses.formattedCurrency,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text('Daily Spending Trend', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          const SpendingChartWidget(),
          
          const SizedBox(height: 24),
          const Text('Spending by Category', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          const CategoryPieChart(),
        ],
      ),
    );
  }
}
