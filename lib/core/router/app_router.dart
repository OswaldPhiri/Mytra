import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/budget/presentation/screens/budget_screen.dart';
import '../../features/budget/presentation/screens/add_budget_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/rules/presentation/screens/rules_screen.dart';
import '../../features/rules/presentation/screens/add_rule_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/export_screen.dart';
import '../../features/settings/presentation/screens/permissions_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../providers/core_providers.dart';
import '../constants/app_constants.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppConstants.routeDashboard,
  debugLogDiagnostics: false,
  routes: [
    // Onboarding
    GoRoute(
      path: AppConstants.routeOnboarding,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: OnboardingScreen(),
      ),
    ),

    // Shell with bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppConstants.routeDashboard,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppConstants.routeTransactions,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TransactionsScreen(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return MaterialPage(child: TransactionDetailScreen(id: id));
              },
            ),
          ],
        ),
        GoRoute(
          path: AppConstants.routeBudget,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BudgetScreen(),
          ),
        ),
        GoRoute(
          path: AppConstants.routeAnalytics,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AnalyticsScreen(),
          ),
        ),
        GoRoute(
          path: AppConstants.routeSettings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),

    // Modals / full-screen routes outside shell
    GoRoute(
      path: AppConstants.routeAddTransaction,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => MaterialPage(
        fullscreenDialog: true,
        child: AddTransactionScreen(
          prefillAmount: state.extra as double?,
        ),
      ),
    ),
    GoRoute(
      path: AppConstants.routeAddBudget,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        child: AddBudgetScreen(),
      ),
    ),
    GoRoute(
      path: '/budget/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return MaterialPage(
          fullscreenDialog: true,
          child: AddBudgetScreen(editId: id),
        );
      },
    ),
    GoRoute(
      path: AppConstants.routeAddRule,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        child: AddRuleScreen(),
      ),
    ),
    GoRoute(
      path: '/rules/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return MaterialPage(
          fullscreenDialog: true,
          child: AddRuleScreen(editId: id),
        );
      },
    ),
    GoRoute(
      path: AppConstants.routeExport,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        child: ExportScreen(),
      ),
    ),
    GoRoute(
      path: AppConstants.routePermissions,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        child: PermissionsScreen(),
      ),
    ),
  ],
);

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const _routes = [
    AppConstants.routeDashboard,
    AppConstants.routeTransactions,
    AppConstants.routeBudget,
    AppConstants.routeAnalytics,
    AppConstants.routeSettings,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial sync on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerSync();
    }
  }

  void _triggerSync() {
    final isSmsEnabled = ref.read(smsMonitoringEnabledProvider);
    if (isSmsEnabled) {
      ref.read(syncServiceProvider).syncSmsInbox();
    }
  }

  void _onDestinationSelected(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      context.go(_routes[index]);
    }
  }

  int _locationToIndex(String location) {
    if (location.startsWith(AppConstants.routeTransactions)) return 1;
    if (location.startsWith(AppConstants.routeBudget)) return 2;
    if (location.startsWith(AppConstants.routeAnalytics)) return 3;
    if (location.startsWith(AppConstants.routeSettings)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _locationToIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
