import 'package:flutter_test/flutter_test.dart';
import 'package:mytra/services/sms/parsers/airtel_money_parser.dart';

void main() {
  late AirtelMoneyParser parser;

  setUp(() {
    parser = AirtelMoneyParser();
  });

  group('AirtelMoneyParser', () {
    test('canParse returns true for Airtel Money senders', () {
      expect(parser.canParse('AirtelMoney'), isTrue);
      expect(parser.canParse('airtelmoney'), isTrue);
      expect(parser.canParse('NotAirtel'), isFalse);
    });

    test('parses expense transaction correctly', () {
      const sms = "Trans. ID: CI210922.0911. You have sent MK 5,000.00 to JOHN DOE. Your new balance is MK 12,000.00";
      final result = parser.parse(sms);

      expect(result, isNotNull);
      expect(result!.amount, 5000.0);
      expect(result.type, 'expense');
      expect(result.description, contains('JOHN DOE'));
      expect(result.reference, 'CI210922.0911');
    });

    test('parses income transaction correctly', () {
      const sms = "Trans. ID: PP2345. You have received MK 15,000.50 from JANE SMITH. Your new balance is MK 27,000.50";
      final result = parser.parse(sms);

      expect(result, isNotNull);
      expect(result!.amount, 15000.5);
      expect(result.type, 'income');
      expect(result.description, contains('JANE SMITH'));
      expect(result.reference, 'PP2345');
    });

    test('parses payment transaction correctly', () {
      const sms = "Trans. ID: PAY123. Payment of MK 2,500.00 to ESCOM was successful. Your balance is MK 9,500.00";
      final result = parser.parse(sms);

      expect(result, isNotNull);
      expect(result!.amount, 2500.0);
      expect(result.type, 'expense');
      expect(result.description, contains('ESCOM'));
      expect(result.reference, 'PAY123');
    });

    test('returns null for invalid sms', () {
      const sms = "Your airtime balance is MK 200.00";
      final result = parser.parse(sms);

      expect(result, isNull);
    });
  });
}
