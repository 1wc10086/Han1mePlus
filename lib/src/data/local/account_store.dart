import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/account.dart';

class AccountStore {
  static const _accountsKey = 'accounts_v2';
  static const _activeAccountKey = 'active_account_v2';
  static const _cloudflareKey = 'cloudflare_cookie_v2';
  final _preferences = SharedPreferencesAsync();

  Future<Account?> read(String baseUrl) async {
    final accounts = await readAll(baseUrl);
    if (accounts.isEmpty) return null;
    final activeId = await _preferences.getString('$_activeAccountKey:${_host(baseUrl)}');
    if (activeId == null) {
      await activate(baseUrl, accounts.first.id!);
      return accounts.first;
    }
    for (final account in accounts) {
      if (account.id == activeId) return account;
    }
    return null;
  }

  Future<List<Account>> readAll(String baseUrl) async {
    final value = await _preferences.getString('$_accountsKey:${_host(baseUrl)}');
    if (value == null) {
      if (_host(baseUrl) != 'hanimeone.me') return const [];
      final legacy = await _preferences.getString('account_v1');
      if (legacy == null) return const [];
      try {
        final account = Account.fromJson(Map<String, dynamic>.from(jsonDecode(legacy) as Map));
        return account.id == null || account.cookie.isEmpty ? const [] : [account];
      } catch (_) {
        return const [];
      }
    }
    try {
      return (jsonDecode(value) as List)
          .map((item) => Account.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((account) => account.id != null && account.cookie.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> write(String baseUrl, Account account) async {
    if (account.id == null) return;
    final accounts = await readAll(baseUrl);
    final next = [account, ...accounts.where((item) => item.id != account.id)];
    await _preferences.setString('$_accountsKey:${_host(baseUrl)}', jsonEncode(next.map((item) => item.toJson()).toList()));
    await _preferences.setString('$_activeAccountKey:${_host(baseUrl)}', account.id!);
  }

  Future<void> activate(String baseUrl, String accountId) => _preferences.setString('$_activeAccountKey:${_host(baseUrl)}', accountId);

  Future<void> remove(String baseUrl, String accountId) async {
    final accounts = await readAll(baseUrl);
    await _preferences.setString('$_accountsKey:${_host(baseUrl)}', jsonEncode(accounts.where((account) => account.id != accountId).map((account) => account.toJson()).toList()));
    if (await _preferences.getString('$_activeAccountKey:${_host(baseUrl)}') == accountId) {
      await _preferences.remove('$_activeAccountKey:${_host(baseUrl)}');
    }
  }

  Future<String?> readCloudflareCookie(String baseUrl) async {
    final value = await _preferences.getString('$_cloudflareKey:${_host(baseUrl)}');
    if (value != null || _host(baseUrl) != 'hanimeone.me') return value;
    return _preferences.getString('cloudflare_cookie_v1');
  }
  Future<void> writeCloudflareCookie(String baseUrl, String value) => _preferences.setString('$_cloudflareKey:${_host(baseUrl)}', value);

  String _host(String baseUrl) => Uri.parse(baseUrl).host;
}
