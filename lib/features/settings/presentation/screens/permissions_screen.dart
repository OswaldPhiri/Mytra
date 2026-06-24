import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../../../../core/constants/app_colors.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _smsGranted = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final sms = await Permission.sms.isGranted;
    final notif = await NotificationListenerService.isPermissionGranted();
    
    if (mounted) {
      setState(() {
        _smsGranted = sms;
        _notificationGranted = notif;
      });
    }
  }

  Future<void> _requestSms() async {
    final status = await Permission.sms.request();
    setState(() => _smsGranted = status.isGranted);
    if (status.isPermanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable SMS permission in App Settings')));
      openAppSettings();
    }
  }

  Future<void> _requestNotification() async {
    await NotificationListenerService.requestPermission();
    // NotificationListenerService requestPermission opens settings, we can't await the result directly.
    // Give user time to change it, then recheck on resume or manual refresh.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable Notification Access for Mytra, then return here.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _checkPermissions),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Mytra requires the following permissions to automate your budget tracking.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
          const SizedBox(height: 24),
          _PermissionCard(
            title: 'SMS Access',
            description: 'Required to automatically read incoming bank and mobile money messages.',
            icon: Icons.sms_outlined,
            isGranted: _smsGranted,
            onRequest: _requestSms,
          ),
          const SizedBox(height: 16),
          _PermissionCard(
            title: 'Notification Access',
            description: 'Required to read transaction alerts from banking applications.',
            icon: Icons.notifications_active_outlined,
            isGranted: _notificationGranted,
            onRequest: _requestNotification,
          ),
          const SizedBox(height: 32),
          const Text('Battery Optimization', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('For reliable background monitoring, please ensure Mytra is excluded from battery optimization.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open App Settings'),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onRequest;

  const _PermissionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isGranted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isGranted ? AppColors.income.withOpacity(0.5) : theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: isGranted ? AppColors.income : theme.colorScheme.onSurface),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16))),
                if (isGranted)
                  const Icon(Icons.check_circle_rounded, color: AppColors.income)
                else
                  ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Grant'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}
