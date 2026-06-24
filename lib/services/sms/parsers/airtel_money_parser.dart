import 'sms_parser_interface.dart';

/// Parser for Airtel Money (Malawi)
class AirtelMoneyParser implements SmsParserInterface {
  @override
  String get parserName => 'Airtel Money';

  @override
  RegExp get senderPattern =>
      RegExp(r'(AIRTEL|AirtelMoney|AIRTEL\s*MONEY)', caseSensitive: false);

  // Expense patterns
  static final _withdrawalPattern = RegExp(
    r'(?:You have (?:successfully )?withdrawn|Cash Out|Withdrawal of)\s+(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _paymentPattern = RegExp(
    r'(?:You have (?:successfully )?paid|Payment of|Paid)\s+(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _transferOutPattern = RegExp(
    r'(?:You have (?:successfully )?sent|Sent|Transfer of)\s+(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _purchasePattern = RegExp(
    r'(?:Purchase of|Bought airtime of)\s+(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Income patterns
  static final _depositPattern = RegExp(
    r'(?:You have (?:successfully )?received|Cash In|Received)\s+(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _transferInPattern = RegExp(
    r'(?:transferred to you|deposited to your account)\s+(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  @override
  ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  }) {
    final amount = _tryExtractExpense(body) ?? _tryExtractIncome(body);
    if (amount == null) return null;

    final isExpense = _isExpense(body);
    final ref = SmsParserInterface.extractReference(body);
    final description = _buildDescription(body, isExpense);

    return ParsedTransaction(
      amount: amount,
      transactionType: isExpense ? 'expense' : 'income',
      description: description,
      referenceNumber: ref,
      sender: 'Airtel Money',
      category: isExpense ? 'Transfers' : 'Salary',
      rawMessage: body,
    );
  }

  double? _tryExtractExpense(String body) {
    for (final pattern in [_withdrawalPattern, _paymentPattern, _transferOutPattern, _purchasePattern]) {
      final m = pattern.firstMatch(body);
      if (m != null) return double.tryParse(m.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  double? _tryExtractIncome(String body) {
    for (final pattern in [_depositPattern, _transferInPattern]) {
      final m = pattern.firstMatch(body);
      if (m != null) return double.tryParse(m.group(1)!.replaceAll(',', ''));
    }
    // fallback to generic extraction
    return SmsParserInterface.extractAmount(body);
  }

  bool _isExpense(String body) {
    final expenseKeywords = RegExp(
      r'\b(withdrawn|paid|sent|purchase|bought|payment|cash out|transfer out)\b',
      caseSensitive: false,
    );
    return expenseKeywords.hasMatch(body);
  }

  String _buildDescription(String body, bool isExpense) {
    // Try to extract merchant / recipient name
    final merchantMatch = RegExp(
      r'(?:to|at|from)\s+([A-Za-z0-9\s]{3,30})(?:\s+(?:for|on|at|\.))',
      caseSensitive: false,
    ).firstMatch(body);

    if (merchantMatch != null) {
      return '${isExpense ? 'Airtel Money' : 'Received from'} ${merchantMatch.group(1)!.trim()}';
    }
    return isExpense ? 'Airtel Money Withdrawal' : 'Airtel Money Deposit';
  }
}
