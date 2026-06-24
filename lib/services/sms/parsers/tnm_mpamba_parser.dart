import 'sms_parser_interface.dart';

/// Parser for TNM Mpamba (Malawi)
class TnmMpambaParser implements SmsParserInterface {
  @override
  String get parserName => 'TNM Mpamba';

  @override
  RegExp get senderPattern =>
      RegExp(r'(TNM|MPAMBA|TNM\s*MPAMBA)', caseSensitive: false);

  static final _expensePatterns = [
    RegExp(r'(?:Cash Out|Withdrawal|Paid|Sent|Payment)\s+(?:of\s+)?(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    RegExp(r'(?:MWK|MK)\s*([\d,]+(?:\.\d{1,2})?)\s+(?:has been )?(?:deducted|debited|withdrawn)', caseSensitive: false),
  ];

  static final _incomePatterns = [
    RegExp(r'(?:Received|Cash In|Deposited|Credit)\s+(?:of\s+)?(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    RegExp(r'(?:MWK|MK)\s*([\d,]+(?:\.\d{1,2})?)\s+(?:has been )?(?:credited|deposited|received)', caseSensitive: false),
  ];

  static final _balancePattern = RegExp(
    r'(?:Balance|Bal)[:\s]+(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  @override
  ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  }) {
    // Try expense
    for (final pattern in _expensePatterns) {
      final m = pattern.firstMatch(body);
      if (m != null) {
        final amount = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (amount != null) {
          return ParsedTransaction(
            amount: amount,
            transactionType: 'expense',
            description: _buildDescription(body, true),
            referenceNumber: SmsParserInterface.extractReference(body),
            sender: 'TNM Mpamba',
            category: 'Transfers',
            rawMessage: body,
          );
        }
      }
    }

    // Try income
    for (final pattern in _incomePatterns) {
      final m = pattern.firstMatch(body);
      if (m != null) {
        final amount = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (amount != null) {
          return ParsedTransaction(
            amount: amount,
            transactionType: 'income',
            description: _buildDescription(body, false),
            referenceNumber: SmsParserInterface.extractReference(body),
            sender: 'TNM Mpamba',
            category: 'Transfers',
            rawMessage: body,
          );
        }
      }
    }

    // Fallback: generic extraction
    final amount = SmsParserInterface.extractAmount(body);
    if (amount != null) {
      final isExpense = RegExp(r'\b(deducted|debited|paid|sent|withdrawn)\b', caseSensitive: false).hasMatch(body);
      return ParsedTransaction(
        amount: amount,
        transactionType: isExpense ? 'expense' : 'income',
        description: isExpense ? 'TNM Mpamba Transaction' : 'TNM Mpamba Received',
        referenceNumber: SmsParserInterface.extractReference(body),
        sender: 'TNM Mpamba',
        category: 'Transfers',
        rawMessage: body,
      );
    }

    return null;
  }

  String _buildDescription(String body, bool isExpense) {
    final merchantMatch = RegExp(
      r'(?:to|from|at)\s+([A-Za-z0-9\s]{3,30}?)(?:\.|,|\s+(?:for|on))',
      caseSensitive: false,
    ).firstMatch(body);

    if (merchantMatch != null) {
      return 'Mpamba ${isExpense ? "to" : "from"} ${merchantMatch.group(1)!.trim()}';
    }
    return isExpense ? 'Mpamba Cash Out' : 'Mpamba Cash In';
  }
}
