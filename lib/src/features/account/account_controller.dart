import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../data/han1me_repository.dart';
import '../../data/local/account_store.dart';
import '../../domain/models/account.dart';
import '../settings/settings_controller.dart';

final accountStoreProvider = Provider((_) => AccountStore());
final accountProvider = AsyncNotifierProvider<AccountController, Account?>(AccountController.new);

class AccountController extends AsyncNotifier<Account?> {
  @override
  Future<Account?> build() async {
    final cloudflareCookie = await ref.read(accountStoreProvider).readCloudflareCookie();
    if (cloudflareCookie?.isNotEmpty == true) ref.read(han1meRepositoryProvider).setCloudflareCookie(cloudflareCookie!);
    final account = await ref.read(accountStoreProvider).read();
    if (account == null || account.cookie.isEmpty) return null;
    ref.read(han1meRepositoryProvider).setCookie(account.cookie);
    return _refresh(account);
  }

  Future<void> saveCloudflareCookie(String cookie) async {
    ref.read(han1meRepositoryProvider).setCloudflareCookie(cookie);
    await ref.read(accountStoreProvider).writeCloudflareCookie(cookie);
  }

  Future<void> saveCookie(String cookie) async {
    final account = Account(cookie: cookie);
    ref.read(han1meRepositoryProvider).replaceCookie(cookie);
    state = AsyncData(account);
    await ref.read(accountStoreProvider).write(account);
    await _refresh(account);
  }

  Future<void> refresh() async {
    final account = state.valueOrNull;
    if (account != null) await _refresh(account);
  }

  Future<void> logout() async {
    ref.read(han1meRepositoryProvider).replaceCookie('');
    final cloudflareCookie = await ref.read(accountStoreProvider).readCloudflareCookie();
    if (cloudflareCookie?.isNotEmpty == true) ref.read(han1meRepositoryProvider).setCloudflareCookie(cloudflareCookie!);
    state = const AsyncData(null);
    await ref.read(accountStoreProvider).clear();
    await CookieManager.instance().deleteAllCookies();
  }

  Future<void> updateProfile(String name, String email) async {
    final account = state.valueOrNull;
    if (account?.id == null || account?.csrfToken == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).updateProfile(settings.baseUrl, account!.id!, account.csrfToken!, name, email);
    await refresh();
  }

  Future<void> updatePassword(String oldPassword, String password, String confirmation) async {
    final account = state.valueOrNull;
    if (account?.id == null || account?.csrfToken == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).updatePassword(settings.baseUrl, account!.id!, account.csrfToken!, oldPassword, password, confirmation);
  }

  Future<Account> _refresh(Account account) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      final profile = await ref.read(han1meRepositoryProvider).account(settings.baseUrl);
      final next = account.copyWith(id: profile.id, name: profile.name, email: profile.email, avatarUrl: profile.avatarUrl, csrfToken: profile.csrfToken, joinedLabel: profile.joinedLabel, subscriberCount: profile.subscriberCount, videoCount: profile.videoCount);
      state = AsyncData(next);
      await ref.read(accountStoreProvider).write(next);
      return next;
    } catch (_) {
      state = AsyncData(account);
      return account;
    }
  }
}
