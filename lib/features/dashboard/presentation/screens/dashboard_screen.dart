import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../providers/app_providers.dart';
import '../widgets/budget_overview_card.dart';
import '../widgets/spending_chart_widget.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/stats_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, theme),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                const BudgetOverviewCard(),
                const SizedBox(height: 16),
                const StatsRow(),
                const SizedBox(height: 20),
                _sectionHeader(context, 'Spending Trend', 'This Month'),
                const SizedBox(height: 12),
                const SpendingChartWidget(),
                const SizedBox(height: 20),
                _sectionHeader(context, 'By Category', null),
                const SizedBox(height: 12),
                const CategoryPieChart(),
                const SizedBox(height: 20),
                _sectionHeader(context, 'Recent Transactions', 'See All',
                    onTap: () => context.go(AppConstants.routeTransactions)),
                const SizedBox(height: 12),
                const RecentTransactionsList(),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routeAddTransaction),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: AppColors.seedColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, ThemeData theme) {
    final now = DateTime.now();
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      snap: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_greeting()},',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  now.formattedMonth,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String? action,
      {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.seedColor,
              ),
            ),
          ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
