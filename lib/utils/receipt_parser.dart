import '../models/category.dart';

class ReceiptData {
  String merchant;
  double amount;
  String category;
  DateTime? date; // Made optional since date extraction might fail

  ReceiptData({
    required this.merchant,
    required this.amount,
    required this.category,
    this.date,
  });
}

class ReceiptParser {
  static ReceiptData parseReceiptText(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    // Extract merchant (usually first non-empty line or line with business name keywords)
    String merchant = _extractMerchant(lines);
    
    // Extract amount
    double amount = _extractAmount(text);
    
    // Extract date
    DateTime? date = _extractDate(text);
    
    // Suggest category based on merchant
    String category = _categorizeMerchant(merchant);
    
    return ReceiptData(
      merchant: merchant,
      amount: amount,
      category: category,
      date: date,
    );
  }

  static String _extractMerchant(List<String> lines) {
    // Common merchant keywords
    final merchantIndicators = [
      'restaurant', 'cafe', 'shop', 'store', 'market', 'mall', 'supermarket',
      'hotel', 'hospital', 'pharmacy', 'salon', 'gas', 'petrol', 'terminal',
      'airport', 'cinema', 'theater', 'gym', 'bank', 'payment', 'grocery',
      'supermarket', 'retail', 'department', 'convenience'
    ];

    // Look for lines that contain merchant name keywords
    for (final line in lines) {
      final lowerLine = line.toLowerCase().trim();
      for (final indicator in merchantIndicators) {
        if (lowerLine.contains(indicator) && line.length > 3) {
          return line.trim();
        }
      }
    }

    // Look for lines that look like business names (title case, no numbers)
    for (final line in lines) {
      if (line.length > 5 && 
          !line.contains(RegExp(r'^\d')) && 
          line.contains(RegExp(r'[A-Z][a-z]+'))) {
        return line.trim();
      }
    }

    // If no keyword match, return first meaningful line
    for (final line in lines) {
      if (line.length > 5 && !line.contains(RegExp(r'^\d'))) {
        return line.trim();
      }
    }

    return 'Receipt';
  }

  static double _extractAmount(String text) {
    // Look for currency symbols or amount patterns
    final patterns = [
      RegExp(r'(\$|Rs\.?|€|¥|£)\s*(\d+(?:,\d{3})*\.?\d{0,2})'),
      RegExp(r'(?:Total|Amount|Price|Cost|Subtotal|Grand Total|Balance|Due)[\s:]*[:\-]*\s*(\$|Rs\.?|€|¥|£)?\s*(\d+(?:,\d{3})*\.?\d{0,2})', caseSensitive: false),
      RegExp(r'(\d+(?:,\d{3})*\.\d{2})(?:\s*(?:USD|INR|EUR|GBP|CAD|AUD))?'),
      RegExp(r'((?<!\d)\d{3,}(?:,\d{3})*\.\d{2}(?!\d))'), // Large numbers with decimals
      RegExp(r'((?<!\d)\d+\.\d{2}(?!\d))'), // Any number with 2 decimals
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        try {
          // Get the amount part (usually the last group)
          String? amountStr;
          for (int i = match.groupCount; i > 0; i--) {
            amountStr = match.group(i);
            if (amountStr != null && amountStr.isNotEmpty && double.tryParse(amountStr.replaceAll(',', '')) != null) {
              return double.parse(amountStr.replaceAll(',', ''));
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return 0.0;
  }

  static DateTime? _extractDate(String text) {
    // Common date patterns
    final patterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'), // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'), // YYYY/MM/DD
      RegExp(r'(?:Date|DATE)[\s:]*(\d{1,2})[/-](\d{1,2})[/-](\d{4})', caseSensitive: false),
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})', caseSensitive: false),
      RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2}),?\s+(\d{4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 3) {
        try {
          int year, month, day;
          if (pattern.pattern.contains('YYYY')) {
            // YYYY/MM/DD
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else if (pattern.pattern.contains('Month')) {
            // Month DD, YYYY
            final monthNames = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
            final monthStr = match.group(1)!.toLowerCase();
            month = monthNames.indexOf(monthStr.substring(0, 3)) + 1;
            day = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
          } else {
            // Assume MM/DD/YYYY or DD/MM/YYYY - try both
            final part1 = int.parse(match.group(1)!);
            final part2 = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
            
            // If first part > 12, likely DD/MM/YYYY
            if (part1 > 12) {
              day = part1;
              month = part2;
            } else {
              month = part1;
              day = part2;
            }
          }
          
          return DateTime(year, month, day);
        } catch (e) {
          continue;
        }
      }
    }

    return null; // Return null if no date found
  }

  static String _categorizeMerchant(String merchant) {
    final merchantLower = merchant.toLowerCase();

    // Food & Restaurants
    if (merchantLower.contains(RegExp(r'(restaurant|cafe|coffee|pizza|burger|food|bakery|bistro|dining|bar|kebab|noodle|sushi|biryani)'))) {
      return 'Food';
    }
    
    // Transport
    if (merchantLower.contains(RegExp(r'(uber|ola|taxi|auto|bus|train|metro|petrol|gas|fuel|parking|flight|airline)'))) {
      return 'Transport';
    }
    
    // Entertainment
    if (merchantLower.contains(RegExp(r'(cinema|movie|theater|theatre|game|arcade|park|concert|show|netflix|spotify)'))) {
      return 'Entertainment';
    }
    
    // Bills & Utilities
    if (merchantLower.contains(RegExp(r'(electricity|water|gas|internet|phone|bill|utility|provider|telecom)'))) {
      return 'Bills';
    }
    
    // Shopping
    if (merchantLower.contains(RegExp(r'(shop|store|mall|market|supermarket|clothing|boutique|amazon|ebay|retail)'))) {
      return 'Shopping';
    }
    
    // Health
    if (merchantLower.contains(RegExp(r'(hospital|clinic|pharmacy|doctor|medical|health|drug|medicine|dental)'))) {
      return 'Health';
    }
    
    // Education
    if (merchantLower.contains(RegExp(r'(school|college|university|course|training|tuition|book|library)'))) {
      return 'Education';
    }
    
    // Travel
    if (merchantLower.contains(RegExp(r'(hotel|resort|hostel|airbnb|booking|travel|tour|vacation)'))) {
      return 'Travel';
    }

    return 'Other';
  }
}
