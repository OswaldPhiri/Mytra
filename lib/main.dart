import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/core_providers.dart';
import 'data/database/tables/tables.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Core Providers
  final container = ProviderContainer();
  await container.read(sharedPreferencesProvider.future);
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MytraApp(),
    ),
  );
}

class MytraApp extends ConsumerStatefulWidget {
  const MytraApp({super.key});

  @override
  ConsumerState<MytraApp> createState() => _MytraAppState();
}

class _MytraAppState extends ConsumerState<MytraApp> {
  StreamSubscription<ServiceNotificationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _initNotificationListener();
  }

  void _initNotificationListener() async {
    final bool isGranted = await NotificationListenerService.isPermissionGranted();
    if (isGranted) {
      _subscription = NotificationListenerService.notificationsStream.listen((event) async {
        final isNotifEnabled = ref.read(notificationMonitoringEnabledProvider);
        if (!isNotifEnabled) return;
        
        if (event.packageName != null && event.content != null) {
          // Check if package is a banking app (Airtel Money, TNM, NB, etc.)
          final pkg = event.packageName!.toLowerCase();
          final title = event.title ?? '';
          final content = event.content!;
          final date = DateTime.now();

          // Simple package name filters
          if (pkg.contains('bank') || pkg.contains('airtel') || pkg.contains('tnm') || pkg.contains('fdh') || pkg.contains('fmb') || title.toLowerCase().contains('transaction')) {
            final existing = await ref.read(databaseProvider).transactionDao.getTransactionByRawMessage(content);
            if (existing == null) {
              await ref.read(smsServiceProvider).processSms(title.isNotEmpty ? title : pkg, content, date);
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Mytra Budget Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
