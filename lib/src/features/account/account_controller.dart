import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../data/han1me_repository.dart';
import '../../data/local/account_store.dart';
import '../../domain/models/account.dart';
import '../settings/settings_controller.dart';
import '../../data/local/library_repository.dart';

final accountStoreProvider = Provider((_) => AccountStore());
final accountProvider = AsyncNotifierProvider<AccountController, Account?>(AccountController.new);
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return ref.read(accountStoreProvider).readAll(settings.resolvedBaseUrl);
});

class AccountController extends AsyncNotifier<Account?> {
  @override
  Future<Account?> build() async {
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.valueOrNull?.resolvedBaseUrl != null && previous?.valueOrNull?.resolvedBaseUrl != next.valueOrNull?.resolvedBaseUrl) ref.invalidateSelf();
    });
    final settings = await ref.watch(settingsProvider.future);
    final store = ref.read(accountStoreProvider);
    final http = ref.read(han1meHttpClientProvider);
    ref.read(han1meRepositoryProvider).replaceCookie('');
    final cloudflareCookie = await store.readCloudflareCookie(settings.resolvedBaseUrl);
    if (cloudflareCookie?.isNotEmpty == true) {
      ref.read(han1meRepositoryProvider).setCloudflareCookie(cloudflareCookie!);
      if (!await http.hasCookie(settings.resolvedBaseUrl, 'cf_clearance')) {
        await http.saveCookies(cloudflareCookie!, url: settings.resolvedBaseUrl);
      }
    }
    final account = await store.read(settings.resolvedBaseUrl);
    if (account == null || account.cookie.isEmpty) return null;
    final cookie = _withoutCloudflareCookie(account.cookie);
    final sanitizedAccount = account.copyWith(cookie: cookie);
    if (cookie != account.cookie) await store.write(settings.resolvedBaseUrl, sanitizedAccount);
    ref.read(han1meRepositoryProvider).setCookie(cookie);
    await http.saveCookies(cookie, url: settings.resolvedBaseUrl);
    return _refresh(sanitizedAccount);
  }

  Future<void> saveCloudflareCookie(String cookie) async {
    final settings = await ref.read(settingsProvider.future);
    ref.read(han1meRepositoryProvider).setCloudflareCookie(cookie);
    await ref.read(han1meHttpClientProvider).saveCookies(cookie, url: settings.resolvedBaseUrl);
    await ref.read(accountStoreProvider).writeCloudflareCookie(settings.resolvedBaseUrl, cookie);
  }

  Future<void> saveCookie(String cookie) async {
    final cloudflareCookie = _cloudflareCookie(cookie);
    final account = Account(cookie: _withoutCloudflareCookie(cookie));
    final http = ref.read(han1meHttpClientProvider);
    final settings = await ref.read(settingsProvider.future);
    ref.read(han1meRepositoryProvider).replaceCookie(account.cookie);
    if (cloudflareCookie.isNotEmpty) {
      ref.read(han1meRepositoryProvider).setCloudflareCookie(cloudflareCookie);
      await http.saveCookies(cloudflareCookie, url: settings.resolvedBaseUrl);
      await ref.read(accountStoreProvider).writeCloudflareCookie(settings.resolvedBaseUrl, cloudflareCookie);
    }
    await http.saveCookies(account.cookie, url: settings.resolvedBaseUrl);
    final profile = await ref.read(han1meRepositoryProvider).account(settings.resolvedBaseUrl);
    final next = account.copyWith(id: profile.id, name: profile.name, email: profile.email, avatarUrl: profile.avatarUrl, csrfToken: profile.csrfToken, joinedLabel: profile.joinedLabel, subscriberCount: profile.subscriberCount, videoCount: profile.videoCount);
    state = AsyncData(next);
    await ref.read(accountStoreProvider).write(settings.resolvedBaseUrl, next);
    ref.invalidate(accountsProvider);
  }

  Future<void> activate(Account account) async {
    if (account.id == null) return;
    final settings = await ref.read(settingsProvider.future);
    final http = ref.read(han1meHttpClientProvider);
    await http.clearCookies(url: settings.resolvedBaseUrl);
    ref.read(han1meRepositoryProvider).replaceCookie('');
    final cloudflareCookie = await ref.read(accountStoreProvider).readCloudflareCookie(settings.resolvedBaseUrl);
    if (cloudflareCookie?.isNotEmpty == true) {
      ref.read(han1meRepositoryProvider).setCloudflareCookie(cloudflareCookie!);
      await http.saveCookies(cloudflareCookie!, url: settings.resolvedBaseUrl);
    }
    ref.read(han1meRepositoryProvider).setCookie(account.cookie);
    await http.saveCookies(account.cookie, url: settings.resolvedBaseUrl);
    await ref.read(accountStoreProvider).activate(settings.resolvedBaseUrl, account.id!);
    state = AsyncData(account);
    ref.invalidate(accountsProvider);
  }

  Future<void> remove(Account account) async {
    if (account.id == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(accountStoreProvider).remove(settings.resolvedBaseUrl, account.id!);
    if (account.id == state.valueOrNull?.id) {
      ref.read(han1meRepositoryProvider).replaceCookie('');
      await ref.read(han1meHttpClientProvider).clearCookies(url: settings.resolvedBaseUrl);
      final cloudflareCookie = await ref.read(accountStoreProvider).readCloudflareCookie(settings.resolvedBaseUrl);
      if (cloudflareCookie?.isNotEmpty == true) {
        ref.read(han1meRepositoryProvider).setCloudflareCookie(cloudflareCookie!);
        await ref.read(han1meHttpClientProvider).saveCookies(cloudflareCookie!, url: settings.resolvedBaseUrl);
      }
      state = const AsyncData(null);
    }
    ref.invalidate(accountsProvider);
  }

  Future<void> refresh() async {
    final account = state.valueOrNull;
    if (account != null) await _refresh(account);
  }

  Future<void> logout() async {
    ref.read(han1meRepositoryProvider).replaceCookie('');
    final settings = await ref.read(settingsProvider.future);
    final active = state.valueOrNull;
    final cloudflareCookie = await ref.read(accountStoreProvider).readCloudflareCookie(settings.resolvedBaseUrl);
    if (cloudflareCookie?.isNotEmpty == true) ref.read(han1meRepositoryProvider).setCloudflareCookie(cloudflareCookie!);
    state = const AsyncData(null);
    if (active?.id != null) await ref.read(accountStoreProvider).remove(settings.resolvedBaseUrl, active!.id!);
    await ref.read(han1meHttpClientProvider).clearCookies(url: settings.resolvedBaseUrl);
    if (cloudflareCookie?.isNotEmpty == true) await ref.read(han1meHttpClientProvider).saveCookies(cloudflareCookie!, url: settings.resolvedBaseUrl);
    await CookieManager.instance().deleteAllCookies();
    ref.invalidate(accountsProvider);
  }

  Future<void> updateProfile(String name, String email) async {
    final account = state.valueOrNull;
    if (account?.id == null || account?.csrfToken == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).updateProfile(settings.resolvedBaseUrl, account!.id!, account.csrfToken!, name, email);
    await refresh();
  }

  Future<void> updatePassword(String oldPassword, String password, String confirmation) async {
    final account = state.valueOrNull;
    if (account?.id == null || account?.csrfToken == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).updatePassword(settings.resolvedBaseUrl, account!.id!, account.csrfToken!, oldPassword, password, confirmation);
  }

  Future<Account> _refresh(Account account) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      final profile = await ref.read(han1meRepositoryProvider).account(settings.resolvedBaseUrl);
      final next = account.copyWith(id: profile.id, name: profile.name, email: profile.email, avatarUrl: profile.avatarUrl, csrfToken: profile.csrfToken, joinedLabel: profile.joinedLabel, subscriberCount: profile.subscriberCount, videoCount: profile.videoCount);
      state = AsyncData(next);
      await ref.read(accountStoreProvider).write(settings.resolvedBaseUrl, next);
      if (next.id != null) {
        try {
          final library = await ref.read(han1meRepositoryProvider).library(settings.resolvedBaseUrl, next.id!);
          await ref.read(libraryProvider.notifier).cacheRemote(library);
        } catch (_) {}
      }
      ref.invalidate(accountsProvider);
      return next;
    } catch (_) {
      state = AsyncData(account);
      return account;
    }
  }

  String _withoutCloudflareCookie(String cookies) => cookies
      .split(';')
      .where((cookie) => cookie.trim().toLowerCase().split('=').first != 'cf_clearance')
      .join(';')
      .trim();

  String _cloudflareCookie(String cookies) => cookies
      .split(';')
      .where((cookie) => cookie.trim().toLowerCase().split('=').first == 'cf_clearance')
      .join(';')
      .trim();
}
