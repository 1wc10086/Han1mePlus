class CloudflareSession {
  CloudflareSession._();

  static const _maxRetryAge = Duration(minutes: 30);

  static DateTime? _verifiedAt;

  static bool get recentlyVerified {
    final value = _verifiedAt;
    return value != null && DateTime.now().difference(value) < _maxRetryAge;
  }

  static void markVerified() => _verifiedAt = DateTime.now();

  static void reset() => _verifiedAt = null;

}
