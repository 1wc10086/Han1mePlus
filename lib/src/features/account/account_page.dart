import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
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
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.baseUrl ?? 'https://hanimeone.me';
    return Scaffold(appBar: AppBar(title: Text(title)), body: InAppWebView(initialUrlRequest: URLRequest(url: WebUri('$baseUrl$url')), initialSettings: InAppWebViewSettings(javaScriptEnabled: true, domStorageEnabled: true, thirdPartyCookiesEnabled: true)));
  }
}

class _LoginPageState extends ConsumerState<LoginPage> {
  var _saving = false;

  Future<void> _saveCookies() async {
    final settings = await ref.read(settingsProvider.future);
    final cookies = await CookieManager.instance().getCookies(url: WebUri(settings.baseUrl));
    final cookie = cookies.map((item) => '${item.name}=${item.value}').join('; ');
    if (cookie.isEmpty || !mounted) return;
    setState(() => _saving = true);
    await ref.read(accountProvider.notifier).saveCookie(cookie);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.baseUrl ?? 'https://hanimeone.me';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.login),
        actions: [IconButton(onPressed: _saving ? null : _saveCookies, icon: const Icon(Icons.check), tooltip: AppLocalizations.of(context)!.finishLogin)],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('$baseUrl/login')),
            initialSettings: InAppWebViewSettings(javaScriptEnabled: true, domStorageEnabled: true, thirdPartyCookiesEnabled: true),
            onLoadStop: (_, url) {
              if (url?.path == '/') _saveCookies();
            },
          ),
          if (_saving) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
