// Core constants for the Mytra app
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Mytra';
  static const String appVersion = '1.0.0';
  static const String currency = 'MWK';
  static const String currencySymbol = 'MK';

  // Database
  static const String dbName = 'mytra_budget.db';
  static const int dbVersion = 1;

  // SharedPreferences keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyActiveBudgetId = 'active_budget_id';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyNotificationMonitorEnabled = 'notification_monitor_enabled';
  static const String keySmsMonitorEnabled = 'sms_monitor_enabled';

  // Navigation
  static const String routeDashboard = '/';
  static const String routeTransactions = '/transactions';
  static const String routeTransactionDetail = '/transactions/:id';
  static const String routeBudget = '/budget';
  static const String routeAnalytics = '/analytics';
  static const String routeRules = '/rules';
  static const String routeSettings = '/settings';
  static const String routeAddTransaction = '/add-transaction';
  static const String routeAddBudget = '/budget/add';
  static const String routeEditBudget = '/budget/edit/:id';
  static const String routeAddRule = '/rules/add';
  static const String routeEditRule = '/rules/edit/:id';
  static const String routeExport = '/settings/export';
  static const String routePermissions = '/settings/permissions';
  static const String routeOnboarding = '/onboarding';

  // SMS known senders
  static const List<String> knownSmsSenders = [
    'AIRTEL',
    'AirtelMoney',
    'AIRTEL MONEY',
    'TNM',
    'MPAMBA',
    'TNM MPAMBA',
    'NATIONAL BANK',
    'NBS',
    'NBS BANK',
    'FDH',
    'FDH BANK',
    'STANDARD BANK',
    'STANBIC',
    'FMB',
    'FMB BANK',
    'CAPITALL',
  ];

  // Categories
  static const List<String> defaultCategories = [
    'Food',
    'Transport',
    'Utilities',
    'Rent',
    'Entertainment',
    'Shopping',
    'Salary',
    'Transfers',
    'Savings',
    'Other',
  ];

  // Transaction types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // Sources
  static const String sourceSms = 'sms';
  static const String sourceNotification = 'notification';
  static const String sourceManual = 'manual';

  // Pagination
  static const int transactionsPerPage = 50;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
}
