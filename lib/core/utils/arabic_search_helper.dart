/// Helper utility for normalizing Arabic search terms and generating
/// flexible PostgREST ILIKE search patterns.
///
/// Solves:
/// - Teh Marbuta (ة) vs Heh (ه) interchangeability (e.g. دعامية vs دعاميه)
/// - Alif forms (أ, إ, آ, ٱ vs ا) (e.g. أصلي vs اصلي)
/// - Yeh vs Alif Maksura (ي vs ى)
/// - Multi-word searches with intervening words (e.g. "دعامية خلفية" matching "دعامية تاهو خلفية")
/// - Word order permutations (e.g. "خلفية دعامية" matching "دعامية خلفية")
/// - Stripping harakat (tashkeel), tatweel, and URL/SQL injection chars
class ArabicSearchHelper {
  ArabicSearchHelper._();

  /// Strips diacritics (harakat), tatweel, and special characters that could break PostgREST
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '') // harakat & tatweel
        .replaceAll(RegExp(r'''['"(),\\;?]'''), ' ') // PostgREST / SQL control chars
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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

    final words = clean.split(' ').where((w) => w.isNotEmpty).toList();
    final conditions = <String>{};

    // 1. Literal search on OEM number & English name
    conditions.add('oem_number.ilike.%$clean%');
    conditions.add('name_en.ilike.%$clean%');
    conditions.add('name_ar.ilike.%$clean%');

    if (words.length == 1) {
      final norm = normalizeToken(words.first);
      if (norm != words.first) {
        conditions.add('name_ar.ilike.%$norm%');
      }
    } else if (words.length > 1) {
      // Tokenized matching:
      // Pattern 1: word1%word2 (preserves order with anything in between)
      final normTokens = words.map(normalizeToken).toList();
      final forwardPattern = normTokens.join('%');
      conditions.add('name_ar.ilike.%$forwardPattern%');

      // Pattern 2: reverse order if 2 words (e.g. "خلفية دعامية" vs "دعامية خلفية")
      if (words.length == 2) {
        final reversePattern = normTokens.reversed.join('%');
        conditions.add('name_ar.ilike.%$reversePattern%');
      }
    }

    return '(${conditions.join(',')})';
  }
}
