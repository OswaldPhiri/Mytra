import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/app_database.dart';
import '../services/sms/sms_service.dart';
import '../services/sms/parsers/airtel_money_parser.dart';
import '../services/sms/parsers/tnm_mpamba_parser.dart';
import '../services/sms/parsers/national_bank_parser.dart';
import '../services/sms/parsers/nbs_bank_parser.dart';
import '../services/sms/parsers/fdh_bank_parser.dart';
import '../services/sms/parsers/standard_bank_parser.dart';
import '../services/sms/parsers/fmb_bank_parser.dart';
import '../services/classification/transaction_classifier.dart';
import '../services/sync_service.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final smsServiceProvider = Provider<SmsService>((ref) {
  final db = ref.watch(databaseProvider);
  final classifier = TransactionClassifier(db);
  
  return SmsService(db, classifier, parsers: [
    AirtelMoneyParser(),
    TnmMpambaParser(),
    NationalBankParser(),
    NbsBankParser(),
    FdhBankParser(),
    StandardBankParser(),
    FmbBankParser(),
  ]);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final smsService = ref.watch(smsServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  
  return SyncService(db, smsService, prefs);
});

// App settings
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences? _prefs;
  ThemeModeNotifier(this._prefs) : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(SharedPreferences? prefs) {
    final val = prefs?.getString('theme_mode') ?? 'system';
    if (val == 'dark') return ThemeMode.dark;
    if (val == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs?.setString('theme_mode', mode.name);
  }
}

// Feature toggles
final smsMonitoringEnabledProvider = StateNotifierProvider<ToggleNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return ToggleNotifier(prefs, 'sms_monitoring_enabled', true);
});

final notificationMonitoringEnabledProvider = StateNotifierProvider<ToggleNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return ToggleNotifier(prefs, 'notification_monitoring_enabled', true);
});

final onboardingCompleteProvider = StateNotifierProvider<ToggleNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return ToggleNotifier(prefs, 'onboarding_complete', false);
});

class ToggleNotifier extends StateNotifier<bool> {
  final SharedPreferences? _prefs;
  final String _key;

  ToggleNotifier(this._prefs, this._key, bool defaultValue) 
      : super(_prefs?.getBool(_key) ?? defaultValue);

  void toggle() {
    state = !state;
    _prefs?.setBool(_key, state);
  }

  void completeOnboarding() {
    state = true;
    _prefs?.setBool(_key, true);
  }
}
