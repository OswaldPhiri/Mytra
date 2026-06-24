import 'package:logger/logger.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables/tables.dart';
import '../classification/transaction_classifier.dart';
import 'parsers/sms_parser_interface.dart';
import 'parsers/airtel_money_parser.dart';
import 'parsers/tnm_mpamba_parser.dart';
import 'parsers/bank_parsers.dart';

/// Orchestrates SMS parsing. Iterates all registered parsers and saves the result.
class SmsService {
  final AppDatabase _db;
  final TransactionClassifier _classifier;
  final _log = Logger();

  final List<SmsParserInterface> _parsers = [
    AirtelMoneyParser(),
    TnmMpambaParser(),
    NationalBankParser(),
    NbsBankParser(),
    FdhBankParser(),
    StandardBankParser(),
    FmbBankParser(),
  ];

  SmsService({
    required AppDatabase db,
    required TransactionClassifier classifier,
  })  : _db = db,
        _classifier = classifier;

  /// Register additional parsers at runtime
  void registerParser(SmsParserInterface parser) => _parsers.add(parser);

  /// Process a single incoming SMS
  Future<bool> processSms({
    required String body,
    required String sender,
    required DateTime date,
  }) async {
    try {
      // Find matching parser
      SmsParserInterface? matchingParser;
      for (final parser in _parsers) {
        if (parser.canHandle(sender)) {
          matchingParser = parser;
          break;
        }
      }

      if (matchingParser == null) {
        _log.d('No parser matched for sender: $sender');
        return false;
      }

      final parsed = matchingParser.parse(body: body, sender: sender, date: date);
      if (parsed == null) {
        _log.d('Parser ${matchingParser.parserName} could not parse message');
        return false;
      }

      // Apply classification rules (may override default category)
      final category = await _classifier.classify(
        description: parsed.description,
        sender: parsed.sender ?? sender,
        amount: parsed.amount,
        defaultCategory: parsed.category,
      );

      // Find active budget
      final activeBudget = await _db.budgetDao.getActiveBudget();

      // Insert transaction
      await _db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          date: date.millisecondsSinceEpoch,
          amount: parsed.amount,
          category: category,
          source: 'sms',
          transactionType: parsed.transactionType,
          description: parsed.description,
          referenceNumber: Value(parsed.referenceNumber),
          sender: Value(parsed.sender),
          rawMessage: Value(body),
          budgetId: Value(activeBudget?.id),
        ),
      );

      _log.i('SMS transaction saved: ${parsed.transactionType} ${parsed.amount} - $category');
      return true;
    } catch (e, stack) {
      _log.e('Error processing SMS', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Scan SMS inbox and process unprocessed messages (called on app start)
  Future<int> scanInbox(List<Map<String, dynamic>> messages) async {
    int processed = 0;
    for (final msg in messages) {
      final sender = msg['sender'] as String? ?? '';
      final body = msg['body'] as String? ?? '';
      final timestamp = msg['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

      final success = await processSms(body: body, sender: sender, date: date);
      if (success) processed++;
    }
    return processed;
  }
}
