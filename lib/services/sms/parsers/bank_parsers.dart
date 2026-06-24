import 'sms_parser_interface.dart';

/// Parser for National Bank of Malawi
class NationalBankParser implements SmsParserInterface {
  @override
  String get parserName => 'National Bank';

  @override
  RegExp get senderPattern =>
      RegExp(r'(NATIONAL\s*BANK|NBM|NATBANK)', caseSensitive: false);

  static final _debitPattern = RegExp(
    r'(?:Debit|DR|Deducted|Withdrawn|Purchase|Payment)[:\s]+(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _creditPattern = RegExp(
    r'(?:Credit|CR|Credited|Deposited|Received)[:\s]+(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _atm = RegExp(
    r'ATM\s+(?:withdrawal|cash)\s+(?:of\s+)?(?:MWK|MK)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  @override
  ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  }) {
    // ATM withdrawal
    final atmMatch = _atm.firstMatch(body);
    if (atmMatch != null) {
      final amount = double.tryParse(atmMatch.group(1)!.replaceAll(',', ''));
      if (amount != null) {
        return ParsedTransaction(
          amount: amount,
          transactionType: 'expense',
          description: 'National Bank ATM Withdrawal',
          referenceNumber: SmsParserInterface.extractReference(body),
          sender: 'National Bank',
          category: 'Other',
          rawMessage: body,
        );
      }
    }

    // Debit
    final debitMatch = _debitPattern.firstMatch(body);
    if (debitMatch != null) {
      final amount = double.tryParse(debitMatch.group(1)!.replaceAll(',', ''));
      if (amount != null) {
        return ParsedTransaction(
          amount: amount,
          transactionType: 'expense',
          description: _extractDescription(body, 'National Bank Debit'),
          referenceNumber: SmsParserInterface.extractReference(body),
          sender: 'National Bank',
          category: 'Other',
          rawMessage: body,
        );
      }
    }

    // Credit
    final creditMatch = _creditPattern.firstMatch(body);
    if (creditMatch != null) {
      final amount = double.tryParse(creditMatch.group(1)!.replaceAll(',', ''));
      if (amount != null) {
        return ParsedTransaction(
          amount: amount,
          transactionType: 'income',
          description: _extractDescription(body, 'National Bank Credit'),
          referenceNumber: SmsParserInterface.extractReference(body),
          sender: 'National Bank',
          category: 'Salary',
          rawMessage: body,
        );
      }
    }

    // Generic fallback
    final amount = SmsParserInterface.extractAmount(body);
    if (amount != null) {
      final isDebit = RegExp(r'\b(debit|dr|deducted|paid|withdrawn|purchase)\b', caseSensitive: false).hasMatch(body);
      return ParsedTransaction(
        amount: amount,
        transactionType: isDebit ? 'expense' : 'income',
        description: isDebit ? 'National Bank Transaction' : 'National Bank Deposit',
        referenceNumber: SmsParserInterface.extractReference(body),
        sender: 'National Bank',
        category: isDebit ? 'Other' : 'Salary',
        rawMessage: body,
      );
    }

    return null;
  }

  String _extractDescription(String body, String fallback) {
    // Look for "at <merchant>" or "from <name>"
    final m = RegExp(
      r'(?:at|from|to)\s+([A-Za-z0-9\s]{3,40}?)(?:\.|,|$)',
      caseSensitive: false,
    ).firstMatch(body);
    return m != null ? m.group(1)!.trim() : fallback;
  }
}

/// Parser for NBS Bank
class NbsBankParser implements SmsParserInterface {
  @override
  String get parserName => 'NBS Bank';

  @override
  RegExp get senderPattern => RegExp(r'(NBS|NBS\s*BANK)', caseSensitive: false);

  @override
  ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  }) {
    final amount = SmsParserInterface.extractAmount(body);
    if (amount == null) return null;

    final isDebit = RegExp(
      r'\b(debit|dr|deducted|paid|withdrawn|purchase|payment|charged)\b',
      caseSensitive: false,
    ).hasMatch(body);

    return ParsedTransaction(
      amount: amount,
      transactionType: isDebit ? 'expense' : 'income',
      description: isDebit ? 'NBS Bank Debit' : 'NBS Bank Credit',
      referenceNumber: SmsParserInterface.extractReference(body),
      sender: 'NBS Bank',
      category: isDebit ? 'Other' : 'Salary',
      rawMessage: body,
    );
  }
}

/// Parser for FDH Bank
class FdhBankParser implements SmsParserInterface {
  @override
  String get parserName => 'FDH Bank';

  @override
  RegExp get senderPattern => RegExp(r'(FDH|FDH\s*BANK)', caseSensitive: false);

  @override
  ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  }) {
    final amount = SmsParserInterface.extractAmount(body);
    if (amount == null) return null;

    final isDebit = RegExp(
      r'\b(debit|dr|deducted|paid|withdrawn|purchase|payment)\b',
      caseSensitive: false,
    ).hasMatch(body);

    return ParsedTransaction(
      amount: amount,
      transactionType: isDebit ? 'expense' : 'income',
      description: isDebit ? 'FDH Bank Debit' : 'FDH Bank Credit',
      referenceNumber: SmsParserInterface.extractReference(body),
      sender: 'FDH Bank',
      category: isDebit ? 'Other' : 'Salary',
      rawMessage: body,
    );
  }
}

/// Parser for Standard Bank Malawi / Stanbic
class StandardBankParser implements SmsParserInterface {
  @override
  String get parserName => 'Standard Bank';

  @override
  RegExp get senderPattern =>
      RegExp(r'(STANDARD\s*BANK|STANBIC|SBMW)', caseSensitive: false);

  @override
  ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  }) {
    final amount = SmsParserInterface.extractAmount(body);
    if (amount == null) return null;

    final isDebit = RegExp(
      r'\b(debit|dr|deducted|paid|withdrawn|purchase|payment|spend)\b',
      caseSensitive: false,
    ).hasMatch(body);

    final merchantMatch = RegExp(
      r'(?:at|merchant)[:\s]+([A-Za-z0-9\s]{3,40}?)(?:\.|,|$)',
      caseSensitive: false,
    ).firstMatch(body);
    final description = merchantMatch != null
        ? '${isDebit ? "Payment at" : "Credit from"} ${merchantMatch.group(1)!.trim()}'
        : (isDebit ? 'Standard Bank Debit' : 'Standard Bank Credit');

    return ParsedTransaction(
      amount: amount,
      transactionType: isDebit ? 'expense' : 'income',
      description: description,
      referenceNumber: SmsParserInterface.extractReference(body),
      sender: 'Standard Bank',
      category: isDebit ? 'Other' : 'Salary',
      rawMessage: body,
    );
  }
}

/// Parser for FMB Capital Bank
class FmbBankParser implements SmsParserInterface {
  @override
  String get parserName => 'FMB Capital Bank';

  @override
  RegExp get senderPattern =>
      RegExp(r'(FMB|CAPITALL|FMB\s*CAPITAL)', caseSensitive: false);

  @override
  ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  }) {
    final amount = SmsParserInterface.extractAmount(body);
    if (amount == null) return null;

    final isDebit = RegExp(
      r'\b(debit|dr|deducted|paid|withdrawn|purchase|payment)\b',
      caseSensitive: false,
    ).hasMatch(body);

    return ParsedTransaction(
      amount: amount,
      transactionType: isDebit ? 'expense' : 'income',
      description: isDebit ? 'FMB Capital Debit' : 'FMB Capital Credit',
      referenceNumber: SmsParserInterface.extractReference(body),
      sender: 'FMB Capital Bank',
      category: isDebit ? 'Other' : 'Salary',
      rawMessage: body,
    );
  }
}
