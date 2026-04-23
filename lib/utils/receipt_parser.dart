class ReceiptData {
  String merchant;
  double amount;
  String category;
  DateTime? date;

  ReceiptData({
    required this.merchant,
    required this.amount,
    required this.category,
    this.date,
  });
}

class ReceiptParser {
  static ReceiptData parseReceiptText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final merchant = _extractMerchant(lines);
    final amount = _extractAmount(text);
    final date = _extractDate(text);
    final category = _categorizeMerchant(merchant);

    return ReceiptData(
      merchant: merchant,
      amount: amount,
      category: category,
      date: date,
    );
  }

  static String _extractMerchant(List<String> lines) {
    final merchantIndicators = [
      'restaurant',
      'cafe',
      'shop',
      'store',
      'market',
      'mall',
      'supermarket',
      'hotel',
      'hospital',
      'pharmacy',
      'salon',
      'gas',
      'petrol',
      'terminal',
      'airport',
      'cinema',
      'theater',
      'gym',
      'bank',
      'payment',
      'grocery',
      'retail',
      'department',
      'convenience',
    ];

    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (merchantIndicators.any(
        (indicator) => lowerLine.contains(indicator),
      )) {
        return line;
      }
    }

    for (final line in lines) {
      if (line.length > 5 && !RegExp(r'^\d').hasMatch(line)) {
        return line;
      }
    }

    return 'Receipt';
  }

  static double _extractAmount(String text) {
    final patterns = [
      RegExp(r'(\$|Rs\.?|₹|€|¥|£)\s*(\d+(?:,\d{3})*\.?\d{0,2})'),
      RegExp(
        r'(?:Total|Amount|Price|Cost|Subtotal|Grand Total|Balance|Due)[\s:]*[:\-]*\s*(\$|Rs\.?|₹|€|¥|£)?\s*(\d+(?:,\d{3})*\.?\d{0,2})',
        caseSensitive: false,
      ),
      RegExp(r'(\d+(?:,\d{3})*\.\d{2})(?:\s*(?:USD|INR|EUR|GBP|CAD|AUD))?'),
      RegExp(r'((?<!\d)\d{3,}(?:,\d{3})*\.\d{2}(?!\d))'),
      RegExp(r'((?<!\d)\d+\.\d{2}(?!\d))'),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        for (int i = match.groupCount; i > 0; i--) {
          final amountStr = match.group(i);
          if (amountStr == null || amountStr.isEmpty) {
            continue;
          }

          final normalized = amountStr.replaceAll(',', '');
          final parsed = double.tryParse(normalized);
          if (parsed != null) {
            return parsed;
          }
        }
      }
    }

    return 0.0;
  }

  static DateTime? _extractDate(String text) {
    final patterns = [
      RegExp(r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b'),
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b'),
      RegExp(
        r'(?:Date|DATE)[\s:]*(\d{1,2})[/-](\d{1,2})[/-](\d{4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2}),?\s+(\d{4})',
        caseSensitive: false,
      ),
    ];

    final monthNames = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) {
        continue;
      }

      try {
        final first = match.group(1);
        final second = match.group(2);
        final third = match.group(3);

        if (first == null || second == null || third == null) {
          continue;
        }

        if (first.length == 4) {
          return DateTime(
            int.parse(first),
            int.parse(second),
            int.parse(third),
          );
        }

        if (int.tryParse(first) == null) {
          final month = monthNames[first.toLowerCase().substring(0, 3)];
          if (month == null) {
            continue;
          }
          return DateTime(int.parse(third), month, int.parse(second));
        }

        final part1 = int.parse(first);
        final part2 = int.parse(second);
        final year = int.parse(third);

        if (part1 > 12) {
          return DateTime(year, part2, part1);
        }

        return DateTime(year, part1, part2);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static String _categorizeMerchant(String merchant) {
    final merchantLower = merchant.toLowerCase();

    if (merchantLower.contains(
      RegExp(
        r'(restaurant|cafe|coffee|pizza|burger|food|bakery|bistro|dining|bar|kebab|noodle|sushi|biryani)',
      ),
    )) {
      return 'Food';
    }

    if (merchantLower.contains(
      RegExp(
        r'(uber|ola|taxi|auto|bus|train|metro|petrol|gas|fuel|parking|flight|airline)',
      ),
    )) {
      return 'Transport';
    }

    if (merchantLower.contains(
      RegExp(
        r'(cinema|movie|theater|theatre|game|arcade|park|concert|show|netflix|spotify)',
      ),
    )) {
      return 'Entertainment';
    }

    if (merchantLower.contains(
      RegExp(
        r'(electricity|water|gas|internet|phone|bill|utility|provider|telecom)',
      ),
    )) {
      return 'Bills';
    }

    if (merchantLower.contains(
      RegExp(
        r'(shop|store|mall|market|supermarket|clothing|boutique|amazon|ebay|retail)',
      ),
    )) {
      return 'Shopping';
    }

    if (merchantLower.contains(
      RegExp(
        r'(hospital|clinic|pharmacy|doctor|medical|health|drug|medicine|dental)',
      ),
    )) {
      return 'Health';
    }

    if (merchantLower.contains(
      RegExp(
        r'(school|college|university|course|training|tuition|book|library)',
      ),
    )) {
      return 'Education';
    }

    if (merchantLower.contains(
      RegExp(r'(hotel|resort|hostel|airbnb|booking|travel|tour|vacation)'),
    )) {
      return 'Travel';
    }

    return 'Other';
  }
}
