/// Represents a parsed transaction extracted from an SMS or notification
class ParsedTransaction {
  final double amount;
  final String transactionType; // 'income' | 'expense'
  final String description;
  final String? referenceNumber;
  final String? sender;
  final String category; // default category before rules engine
  final String rawMessage;

  const ParsedTransaction({
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.rawMessage,
    this.referenceNumber,
    this.sender,
    this.category = 'Other',
  });
}

/// Contract all SMS parsers must implement
abstract class SmsParserInterface {
  /// Unique name for this parser
  String get parserName;

  /// Regex pattern to match sender address
  RegExp get senderPattern;

  /// Try to parse an SMS message. Returns null if the message doesn't match.
  ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  });

  /// Whether this parser can handle the given sender
  bool canHandle(String sender) => senderPattern.hasMatch(sender.toUpperCase());

  // --- Shared helper: extract amount ---
  static double? extractAmount(String text) {
    // Match patterns like: MWK 50,000 | MK50000 | 50,000.00 | 50000
    final patterns = [
      RegExp(r'MWK\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'MK\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'K([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*MWK', caseSensitive: false),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*MK', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        return double.tryParse(raw);
      }
    }
    return null;
  }

  // --- Shared helper: extract reference ---
  static String? extractReference(String text) {
    final patterns = [
      RegExp(r'Ref(?:erence)?[:\s#]*([A-Z0-9]{6,20})', caseSensitive: false),
      RegExp(r'TID[:\s]*([A-Z0-9]{6,20})', caseSensitive: false),
      RegExp(r'Transaction ID[:\s]*([A-Z0-9]{6,20})', caseSensitive: false),
      RegExp(r'#([A-Z0-9]{8,20})', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1);
    }
    return null;
  }
}
