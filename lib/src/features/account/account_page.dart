import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../domain/models/account.dart';
import 'account_controller.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(accountProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mine)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
        children: [
          _AccountCard(account: account, onRefresh: () => ref.read(accountProvider.notifier).refresh()),
          const SizedBox(height: 8),
          _AccountSwitcher(account: account),
          if (account != null) ...[
            const SizedBox(height: 12),
            _ProfilePanels(account: account!),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(l10n.logout), content: Text(l10n.logoutConfirmation), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.logout))]));
                  if (confirmed == true) await ref.read(accountProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.logout),
              ),
            ),
          ],
        ],
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final loggedIn = account != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final router = GoRouter.of(context);
          if (!loggedIn) router.push('/login');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(44),
                onTap: loggedIn
                    ? () async {
                        final router = GoRouter.of(context);
                        await router.push('/account/profile/${account!.id}');
                        onRefresh();
                      }
                    : null,
                child: CircleAvatar(radius: 44, backgroundImage: account?.avatarUrl?.isNotEmpty == true ? CachedNetworkImageProvider(account!.avatarUrl!) : null, child: account?.avatarUrl?.isNotEmpty == true ? null : Icon(loggedIn ? Icons.person : Icons.person_outline, size: 44)),
              ),
              const SizedBox(height: 12),
              Text(account?.name?.isNotEmpty == true ? account!.name! : loggedIn ? l10n.signedIn : l10n.signedOut, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(loggedIn ? '@${account!.id}' : l10n.tapToLogin, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
              if (loggedIn) ...[
                const SizedBox(height: 10),
                Text(l10n.subscriberVideoCount(account!.subscriberCount ?? 0, account!.videoCount ?? 0), textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(l10n.joinedDate(account!.joinedLabel ?? ''), textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
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
                final router = GoRouter.of(context);
                Navigator.pop(context);
                router.push('/login');
              },
            ),
          ],
        ),
      );
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