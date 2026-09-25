/// Helper utility for normalizing Arabic search terms, handling Iraqi dialect
/// variations in automotive parts, and generating flexible PostgREST ILIKE search patterns.
///
/// Solves:
/// - Teh Marbuta (ة) vs Heh (ه) interchangeability (e.g. دعامية vs دعاميه)
/// - Alif forms (أ, إ, آ, ٱ vs ا) (e.g. أصلي vs اصلي)
/// - Yeh vs Alif Maksura (ي vs ى)
/// - Definite article (ال) prefix handling (e.g. جاملغ vs الجاملغ)
/// - Iraqi automotive dialect phonetic variants (e.g. جامرلغ vs جاملغ, دشبول vs دشبور, سبايدر vs سبايلر)
/// - Prefix matching (e.g. "مش" matching "مشط", "مشكل")
/// - Multi-word searches with intervening words (e.g. "دعامية خلفية" matching "دعامية تاهو خلفية")
/// - Word order permutations (e.g. "خلفية دعامية" matching "دعامية خلفية")
/// - Stripping harakat (tashkeel), tatweel, and URL/SQL injection chars
class ArabicSearchHelper {
  ArabicSearchHelper._();

  /// Known Iraqi automotive dialect variations and phonetic equivalents
  static const Map<String, List<String>> _dialectSynonyms = {
    'جاملغ': ['جامرلغ', 'جاملق', 'جامرلق'],
    'جامرلغ': ['جاملغ', 'جامرلق', 'جاملق'],
    'جاملغات': ['جامرلغات'],
    'جامرلغات': ['جاملغات'],
    'دشبول': ['دشبور'],
    'دشبور': ['دشبول'],
    'سبايدر': ['سبايلر', 'جناح'],
    'سبايلر': ['سبايدر', 'جناح'],
    'بلكات': ['بلاكات', 'بواجي', 'شمعات'],
    'بلاكات': ['بلكات', 'بواجي', 'شمعات'],
    'بلك': ['بلاك', 'بوجي'],
    'بلاك': ['بلك', 'بوجي'],
    'راديتر': ['رديتر', 'رادييتر'],
    'رديتر': ['راديتر', 'رادييتر'],
    'رادييتر': ['راديتر', 'رديتر'],
    'فيولبمب': ['فيول بمب', 'طرمبة بنزين'],
    'فيول بمب': ['فيولبمب', 'طرمبة بنزين'],
    'واتربمب': ['واتر بمب', 'طرمبة ماء'],
    'واتر بمب': ['واتربمب', 'طرمبة ماء'],
    'بلبرنغ': ['بلبرينغ', 'بولبرنغ', 'رولمان'],
    'بلبرينغ': ['بلبرنغ', 'بولبرنغ', 'رولمان'],
    'سفايف': ['فحمات', 'بريكات', 'تيل'],
    'فحمات': ['سفايف', 'بريكات', 'تيل'],
    'شاصي': ['شاسي', 'شاسيه'],
    'شاسي': ['شاصي', 'شاسيه'],
    'يدّات': ['يدات', 'يدة', 'قبضة'],
    'يدات': ['يدّات', 'يدة', 'قبضة'],
  };

  /// Strips diacritics (harakat), tatweel, and special characters that could break PostgREST
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '') // harakat & tatweel
        .replaceAll(RegExp(r'''['"(),\\;?]'''), ' ') // PostgREST / SQL control chars
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Generates dialect and phonetic variants for a given search query
  static Set<String> getDialectVariants(String text) {
    final variants = <String>{text};

    // Strip leading "ال" (definite article) if word is at least 4 letters
    if (text.startsWith('ال') && text.length >= 4) {
      final withoutAl = text.substring(2);
      variants.add(withoutAl);
      variants.addAll(_expandSubstrings(withoutAl));
    }

    variants.addAll(_expandSubstrings(text));

    // Token-level exact synonyms
    for (final entry in _dialectSynonyms.entries) {
      if (text == entry.key) {
        variants.addAll(entry.value);
      }
    }

    return variants;
  }

  static Set<String> _expandSubstrings(String str) {
    final results = <String>{};
    if (str.contains('جامرلغ')) {
      results.add(str.replaceAll('جامرلغ', 'جاملغ'));
    }
    if (str.contains('جاملغ')) {
      results.add(str.replaceAll('جاملغ', 'جامرلغ'));
    }
    if (str.contains('دشبور')) {
      results.add(str.replaceAll('دشبور', 'دشبول'));
    }
    if (str.contains('دشبول')) {
      results.add(str.replaceAll('دشبول', 'دشبور'));
    }
    if (str.contains('سبايلر')) {
      results.add(str.replaceAll('سبايلر', 'سبايدر'));
    }
    if (str.contains('سبايدر')) {
      results.add(str.replaceAll('سبايدر', 'سبايلر'));
    }
    if (str.contains('بلاكات')) {
      results.add(str.replaceAll('بلاكات', 'بلكات'));
    }
    if (str.contains('بلكات')) {
      results.add(str.replaceAll('بلكات', 'بلاكات'));
    }
    if (str.contains('راديتر')) {
      results.add(str.replaceAll('راديتر', 'رديتر'));
    }
    if (str.contains('رديتر')) {
      results.add(str.replaceAll('رديتر', 'راديتر'));
    }
    return results;
  }

  /// Converts a single Arabic word token into a flexible wildcard pattern:
  /// - Normalizes leading Alif (أ, إ, آ, ٱ, ا) to '_'
  /// - Normalizes trailing Teh Marbuta / Heh (ة, ه) to '_'
  /// - Normalizes trailing Yeh / Alif Maksura (ي, ى) to '_'
  static String normalizeToken(String token) {
    if (token.isEmpty) return token;

    var t = token;

    // Normalize leading Alif if word has at least 3 letters
    if (t.length >= 3 && RegExp(r'^[أإآٱا]').hasMatch(t)) {
      t = '_${t.substring(1)}';
    }

    // Normalize trailing Teh Marbuta or Heh (ة, ه)
    if (t.length >= 2 && RegExp(r'[ةه]$').hasMatch(t)) {
      t = '${t.substring(0, t.length - 1)}_';
    } else if (t.length >= 2 && RegExp(r'[يى]$').hasMatch(t)) {
      // Normalize trailing Yeh or Alif Maksura (ي, ى)
      t = '${t.substring(0, t.length - 1)}_';
    }

    return t;
  }

  /// Builds a PostgREST `or` filter string for products search
  static String buildPostgrestOrClause(String rawQuery) {
    final clean = sanitize(rawQuery);
    if (clean.isEmpty) return '';

    final conditions = <String>{};

    // 1. Literal search on OEM number, English name, and dialect names
    conditions.add('oem_number.ilike.%$clean%');
    conditions.add('name_en.ilike.%$clean%');
    conditions.add('dialect_names.ilike.%$clean%');

    // 2. Generate dialect and phonetic variants
    final allVariants = getDialectVariants(clean);

    for (final variant in allVariants) {
      // Substring & Prefix matches
      conditions.add('name_ar.ilike.%$variant%');
      conditions.add('name_ar.ilike.$variant%');
      conditions.add('dialect_names.ilike.%$variant%');

      final words = variant.split(' ').where((w) => w.isNotEmpty).toList();

      if (words.length == 1) {
        final norm = normalizeToken(words.first);
        if (norm != words.first) {
          conditions.add('name_ar.ilike.%$norm%');
          conditions.add('dialect_names.ilike.%$norm%');
        }
        // Normalize any alef forms inside word
        final alefNorm = words.first.replaceAll(RegExp(r'[أإآٱ]'), '_');
        if (alefNorm != words.first) {
          conditions.add('name_ar.ilike.%$alefNorm%');
          conditions.add('dialect_names.ilike.%$alefNorm%');
        }
      } else if (words.length > 1) {
        // Multi-word tokenized matching: word1%word2
        final normTokens = words.map(normalizeToken).toList();
        final forwardPattern = normTokens.join('%');
        conditions.add('name_ar.ilike.%$forwardPattern%');
        conditions.add('dialect_names.ilike.%$forwardPattern%');

        // Reverse order if 2 words (e.g. "خلفية دعامية" vs "دعامية خلفية")
        if (words.length == 2) {
          final reversePattern = normTokens.reversed.join('%');
          conditions.add('name_ar.ilike.%$reversePattern%');
          conditions.add('dialect_names.ilike.%$reversePattern%');
        }
      }
    }

    return '(${conditions.join(',')})';
  }
}
