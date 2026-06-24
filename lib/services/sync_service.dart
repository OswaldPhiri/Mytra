import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/app_database.dart';
import 'sms/sms_service.dart';

class SyncService {
  final AppDatabase _db;
  final SmsService _smsService;
  final SharedPreferences _prefs;
  final SmsQuery _query = SmsQuery();

  static const String _lastSyncKey = 'last_sms_sync_timestamp';

  SyncService(this._db, this._smsService, this._prefs);

  Future<void> syncSmsInbox() async {
    final hasPermission = await Permission.sms.isGranted;
    if (!hasPermission) return;

    final lastSyncStr = _prefs.getString(_lastSyncKey);
    DateTime? lastSync;
    if (lastSyncStr != null) {
      lastSync = DateTime.parse(lastSyncStr);
    } else {
      // If first time, only sync the last 7 days to avoid overwhelming the db
      lastSync = DateTime.now().subtract(const Duration(days: 7));
    }

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      sort: true,
    );

    int processedCount = 0;
    for (var message in messages) {
      if (message.date == null || message.body == null || message.address == null) continue;
      
      // Stop if we reached messages older than our last sync
      if (message.date!.isBefore(lastSync)) {
        break; 
      }

      final sender = message.address!;
      final body = message.body!;
      final date = message.date!;

      // Check if we already processed this exact message (safeguard)
      final existing = await _db.transactionDao.getTransactionByRawMessage(body);
      if (existing == null) {
        await _smsService.processSms(sender, body, date);
        processedCount++;
      }
    }

    // Update last sync time
    await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    print('Sync complete. Processed $processedCount new SMS messages.');
  }
}
