int parseVideoViewCount(String? text) {
  if (text == null || text.isEmpty) return 0;
  final normalized = _normalizeDigits(text).replaceAll(',', '');
  final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(normalized);
  if (match == null) return 0;
  final numeric = double.tryParse(match.group(1)!);
  if (numeric == null) return 0;
  final unitMatch =
      RegExp(r'(?<=[0-9.])([\u4e07\u842c\u4ebf\u5104KkMmWw])').firstMatch(normalized);
  return (numeric * _unitMultiplier(unitMatch?.group(1))).round();
}

bool meetsMinimumVideoViews(String? text, int minimumInTenThousands) {
  if (minimumInTenThousands <= 0) return true;
  return parseVideoViewCount(text) >= minimumInTenThousands * 10000;
}

int _unitMultiplier(String? unit) {
  if (unit == '\u4e07' || unit == '\u842c' || unit == 'w' || unit == 'W') {
    return 10000;
  }
  if (unit == '\u4ebf' || unit == '\u5104') return 100000000;
  if (unit == 'k' || unit == 'K') return 1000;
  if (unit == 'm' || unit == 'M') return 1000000;
  return 1;
}

String _normalizeDigits(String text) {
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    if (code >= 0xFF10 && code <= 0xFF19) {
      buffer.writeCharCode(code - 0xFEE0);
    } else {
      buffer.writeCharCode(code);
    }
  }
  return buffer.toString();
}