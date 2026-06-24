import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/core_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isSmsEnabled = ref.watch(smsMonitoringEnabledProvider);
    final isNotificationEnabled = ref.watch(notificationMonitoringEnabledProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Preferences'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode', style: TextStyle(fontFamily: 'Inter')),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
              activeColor: AppColors.seedColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money_outlined),
            title: const Text('Currency', style: TextStyle(fontFamily: 'Inter')),
            trailing: const Text(AppConstants.currency, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Currency is currently fixed to MWK')));
            },
          ),
          
          const Divider(),
          _buildSectionHeader(context, 'Automation'),
          ListTile(
            leading: const Icon(Icons.sms_outlined),
            title: const Text('SMS Monitoring', style: TextStyle(fontFamily: 'Inter')),
            subtitle: const Text('Read bank SMS messages', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
            trailing: Switch(
              value: isSmsEnabled,
              onChanged: (v) => ref.read(smsMonitoringEnabledProvider.notifier).toggle(),
              activeColor: AppColors.seedColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notification Monitoring', style: TextStyle(fontFamily: 'Inter')),
            subtitle: const Text('Read bank app notifications', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
            trailing: Switch(
              value: isNotificationEnabled,
              onChanged: (v) => ref.read(notificationMonitoringEnabledProvider.notifier).toggle(),
              activeColor: AppColors.seedColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.rule_rounded),
            title: const Text('Categorization Rules', style: TextStyle(fontFamily: 'Inter')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppConstants.routeRules),
          ),

          const Divider(),
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.import_export_rounded),
            title: const Text('Export Data', style: TextStyle(fontFamily: 'Inter')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppConstants.routeExport),
          ),
          
          const Divider(),
          _buildSectionHeader(context, 'System'),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Permissions Status', style: TextStyle(fontFamily: 'Inter')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppConstants.routePermissions),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Mytra', style: TextStyle(fontFamily: 'Inter')),
            subtitle: const Text('Version ${AppConstants.appVersion}', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.seedColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
