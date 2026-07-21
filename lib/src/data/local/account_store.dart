import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/account.dart';

class AccountStore {
  static const _key = 'account_v1';
  static const _cloudflareKey = 'cloudflare_cookie_v1';
  final _preferences = SharedPreferencesAsync();

  Future<Account?> read() async {
    final value = await _preferences.getString(_key);
    if (value == null) return null;
    try {
      return Account.fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Account account) => _preferences.setString(_key, jsonEncode(account.toJson()));
  Future<void> clear() => _preferences.remove(_key);
  Future<String?> readCloudflareCookie() => _preferences.getString(_cloudflareKey);
  Future<void> writeCloudflareCookie(String value) => _preferences.setString(_cloudflareKey, value);
}
