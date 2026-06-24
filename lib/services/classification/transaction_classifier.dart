import '../../data/database/app_database.dart';
import '../../data/database/tables/tables.dart';

/// Classifies transactions into categories using user-defined rules and keyword matching
class TransactionClassifier {
  final AppDatabase _db;

  TransactionClassifier({required AppDatabase db}) : _db = db;

  // Default keyword-to-category map
  static final Map<String, List<String>> _keywordMap = {
    'Food': [
      'shoprite', 'food lovers', 'hungry lion', 'kfc', 'mcdonalds', 'pizza',
      'restaurant', 'cafe', 'grocery', 'supermarket', 'market', 'pick n pay',
      'spar', 'metro', 'food', 'eat', 'meal', 'lunch', 'dinner', 'breakfast',
      'takeaway', 'takeout', 'snack', 'beverage', 'drink',
    ],
    'Transport': [
      'fuel', 'petrol', 'diesel', 'bp', 'puma', 'caltex', 'total',
      'taxi', 'bus', 'minibus', 'transport', 'uber', 'bolt', 'ride',
      'parking', 'toll', 'vehicle', 'car', 'auto',
    ],
    'Utilities': [
      'escom', 'electricity', 'water', 'blantyre water', 'nwsc', 'lilongwe water',
      'internet', 'wifi', 'dstv', 'mtn', 'dstv', 'starlink',
      'airtime', 'data bundle', 'bundle',
    ],
    'Rent': [
      'rent', 'house', 'accommodation', 'apartment', 'landlord', 'lease',
      'property', 'tenancy',
    ],
    'Entertainment': [
      'cinema', 'movie', 'theatre', 'concert', 'event', 'ticket',
      'hotel', 'bar', 'club', 'pub', 'lounge', 'casino',
      'subscription', 'netflix', 'spotify', 'youtube',
    ],
    'Shopping': [
      'clothing', 'clothes', 'fashion', 'shoes', 'boots', 'mall',
      'game store', 'hardware', 'appliance', 'furniture', 'online',
      'amazon', 'jumia', 'purchase',
    ],
    'Salary': [
      'salary', 'wage', 'payroll', 'payment from employer', 'payslip',
      'monthly pay', 'advance', 'bonus',
    ],
    'Transfers': [
      'transfer', 'send money', 'sent to', 'received from', 'airtel money',
      'mpamba', 'mobile money', 'bank transfer', 'inter-bank',
    ],
    'Savings': [
      'savings', 'investment', 'fixed deposit', 'treasury', 'shares',
      'mutual fund', 'pension', 'insurance',
    ],
  };

  Future<String> classify({
    required String description,
    required String sender,
    required double amount,
    String defaultCategory = 'Other',
  }) async {
    // 1. Check user-defined rules first (highest priority)
    final rules = await _db.ruleDao.getActiveRules();
    for (final rule in rules) {
      if (_matchesRule(rule, description: description, sender: sender, amount: amount)) {
        return rule.actionCategory;
      }
    }

    // 2. Keyword matching (case-insensitive)
    final haystack = '${description.toLowerCase()} ${sender.toLowerCase()}';
    for (final entry in _keywordMap.entries) {
      for (final keyword in entry.value) {
        if (haystack.contains(keyword)) {
          return entry.key;
        }
      }
    }

    // 3. Return the parser-assigned default
    return defaultCategory;
  }

  bool _matchesRule(
    Rule rule, {
    required String description,
    required String sender,
    required double amount,
  }) {
    final String fieldValue;
    switch (rule.conditionField) {
      case 'sender':
        fieldValue = sender;
        break;
      case 'description':
        fieldValue = description;
        break;
      case 'amount':
        fieldValue = amount.toString();
        break;
      default:
        return false;
    }

    switch (rule.conditionOperator) {
      case 'contains':
        return fieldValue.toLowerCase().contains(rule.conditionValue.toLowerCase());
      case 'equals':
        return fieldValue.toLowerCase() == rule.conditionValue.toLowerCase();
      case 'starts_with':
        return fieldValue.toLowerCase().startsWith(rule.conditionValue.toLowerCase());
      case 'ends_with':
        return fieldValue.toLowerCase().endsWith(rule.conditionValue.toLowerCase());
      case 'gt':
        final num? val = double.tryParse(rule.conditionValue);
        return val != null && amount > val;
      case 'lt':
        final num? val = double.tryParse(rule.conditionValue);
        return val != null && amount < val;
      default:
        return false;
    }
  }
}
