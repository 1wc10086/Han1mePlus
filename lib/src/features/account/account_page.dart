import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/han1me_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../../domain/models/account.dart';
import '../settings/settings_controller.dart';
import 'account_controller.dart';

class AccountDrawer extends ConsumerWidget {
  const AccountDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider).valueOrNull;
    return Drawer(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.account, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _AccountCard(account: account, onRefresh: () => ref.read(accountProvider.notifier).refresh()),
              const SizedBox(height: 8),
              _AccountSwitcher(account: account),
              if (account != null) ...[
                const SizedBox(height: 12),
                const SizedBox(height: 8),
                _ProfilePanels(account: account!),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () async {
                    final l10n = AppLocalizations.of(context)!;
                    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(l10n.logout), content: Text(l10n.logoutConfirmation), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.logout))]));
                    if (confirmed == true) await ref.read(accountProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(AppLocalizations.of(context)!.logout),
                ),
              ],
            ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountSwitcher extends ConsumerWidget {
  const _AccountSwitcher({this.account});

  final Account? account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.switch_account_outlined),
      title: Text(l10n.accountManage),
      subtitle: Text(accounts.isEmpty ? l10n.accountManageSubtitleEmpty : l10n.accountManageSubtitleCount(accounts.length)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => _AccountSheet(accounts: accounts, active: account),
      ),
    );
  }
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet({required this.accounts, this.active});

  final List<Account> accounts;
  final Account? active;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), child: Text(AppLocalizations.of(context)!.accountManage)),
            ...accounts.map(
              (item) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: item.avatarUrl?.isNotEmpty == true ? CachedNetworkImageProvider(item.avatarUrl!) : null,
                  child: item.avatarUrl?.isNotEmpty == true ? null : const Icon(Icons.person_outline),
                ),
                title: Text(item.name?.isNotEmpty == true ? item.name! : item.id ?? ''),
                subtitle: Text(item.email ?? item.id ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.id == active?.id) const Icon(Icons.check_circle),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: AppLocalizations.of(context)!.removeAccount,
                      onPressed: () async {
                        if (item.id == null) return;
                        await ref.read(accountProvider.notifier).remove(item);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                onTap: item.id == active?.id
                    ? null
                    : () async {
                        await ref.read(accountProvider.notifier).activate(item);
                        if (context.mounted) Navigator.pop(context);
                      },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: Text(AppLocalizations.of(context)!.addAccount),
              onTap: () {
                final navigator = Navigator.of(context, rootNavigator: true);
                navigator.pop();
                navigator.push(MaterialPageRoute<void>(builder: (_) => const LoginPage()));
              },
            ),
          ],
        ),
      );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({this.account, required this.onRefresh});
  final Account? account;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final loggedIn = account != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          if (!loggedIn) Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginPage()));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: loggedIn ? () async { await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AccountWebPage(url: '/user/${account!.id}/edit', title: AppLocalizations.of(context)!.accountProfile))); onRefresh(); } : null,
                child: CircleAvatar(radius: 28, backgroundImage: account?.avatarUrl?.isNotEmpty == true ? CachedNetworkImageProvider(account!.avatarUrl!) : null, child: account?.avatarUrl?.isNotEmpty == true ? null : Icon(loggedIn ? Icons.person : Icons.person_outline, size: 30)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account?.name?.isNotEmpty == true ? account!.name! : loggedIn ? AppLocalizations.of(context)!.signedIn : AppLocalizations.of(context)!.signedOut, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(loggedIn ? AppLocalizations.of(context)!.accountSummary(account?.id ?? '', account?.subscriberCount ?? 0, account?.videoCount ?? 0, account?.joinedLabel ?? '') : AppLocalizations.of(context)!.tapToLogin, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(loggedIn ? Icons.verified_user_outlined : Icons.login),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePanels extends ConsumerWidget {
  const _ProfilePanels({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        children: [
          ExpansionTile(title: Text(AppLocalizations.of(context)!.editProfile), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: [_ProfileForm(account: account)]),
          ExpansionTile(title: Text(AppLocalizations.of(context)!.changePassword), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: const [_PasswordForm()]),
        ],
      );
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.account});
  final Account account;
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final _name = TextEditingController(text: widget.account.name);
  late final _email = TextEditingController(text: widget.account.email);
  @override
  void dispose() { _name.dispose(); _email.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [TextField(controller: _name, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.username)), TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.email)), const SizedBox(height: 12), FilledButton(onPressed: () => ref.read(accountProvider.notifier).updateProfile(_name.text.trim(), _email.text.trim()), child: Text(AppLocalizations.of(context)!.saveProfile))]);
}

class _PasswordForm extends ConsumerStatefulWidget {
  const _PasswordForm();
  @override
  ConsumerState<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends ConsumerState<_PasswordForm> {
  final _old = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  @override
  void dispose() { _old.dispose(); _password.dispose(); _confirmation.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [TextField(controller: _old, obscureText: true, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.oldPassword)), TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.newPassword)), TextField(controller: _confirmation, obscureText: true, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.confirmNewPassword)), const SizedBox(height: 12), FilledButton(onPressed: () => ref.read(accountProvider.notifier).updatePassword(_old.text, _password.text, _confirmation.text), child: Text(AppLocalizations.of(context)!.changePassword))]);
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class AccountWebPage extends ConsumerWidget {
  const AccountWebPage({super.key, required this.url, required this.title});
  final String url;
  final String title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.resolvedBaseUrl ?? 'https://hanime1.com';
    return Scaffold(appBar: AppBar(title: Text(title)), body: InAppWebView(initialUrlRequest: URLRequest(url: WebUri('$baseUrl$url')), initialSettings: InAppWebViewSettings(javaScriptEnabled: true, domStorageEnabled: true, thirdPartyCookiesEnabled: true, userAgent: Han1meApi.userAgent)));
  }
}

class _LoginPageState extends ConsumerState<LoginPage> {
  var _saving = false;
  Object? _error;

  Future<void> _saveCookies() async {
    if (_saving) return;
    final settings = await ref.read(settingsProvider.future);
    final cookie = await ref.read(han1meHttpClientProvider).webViewCookies(settings.resolvedBaseUrl);
    if (cookie.isEmpty || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(accountProvider.notifier).saveCookie(cookie);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.resolvedBaseUrl ?? 'https://hanime1.com';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.login),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(javaScriptEnabled: true, domStorageEnabled: true, thirdPartyCookiesEnabled: true, userAgent: Han1meApi.userAgent),
            onWebViewCreated: (controller) async {
              await ref.read(han1meHttpClientProvider).clearWebViewCookies();
              await controller.loadUrl(urlRequest: URLRequest(url: WebUri('$baseUrl/login')));
            },
            onLoadStop: (_, url) {
              final loginUrl = Uri.parse('$baseUrl/login');
              if (url != null && url.host == loginUrl.host && url.path != loginUrl.path) _saveCookies();
            },
          ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: MaterialBanner(
                content: Text('$_error'),
                actions: [TextButton(onPressed: () => setState(() => _error = null), child: Text(AppLocalizations.of(context)!.close))],
              ),
            ),
          if (_saving) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
