import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_log.dart';
import '../../data/remote/ech_static_client.dart';

/// 调试日志页：点击“关于”页版本号 5 次进入。
/// 汇总全局请求日志 + ECH 引擎日志，可复制 / 分享 / 清空。
class DebugLogPage extends ConsumerStatefulWidget {
  const DebugLogPage({super.key});

  @override
  ConsumerState<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends ConsumerState<DebugLogPage> {
  List<String> _echLogs = const [];

  @override
  void initState() {
    super.initState();
    _echLogs = EchStaticClient.instance?.logs ?? const [];
  }

  String _buildText() {
    final ech = EchStaticClient.instance?.logs;
    return AppLog.export(echLogs: ech);
  }

  void _refresh() {
    setState(() {
      _echLogs = EchStaticClient.instance?.logs ?? const [];
    });
  }

  Future<void> _share() async {
    final text = _buildText();
    await SharePlus.instance.share(ShareParams(text: text, subject: 'Han1me+ 诊断日志'));
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _buildText()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('日志已复制')));
    }
  }

  void _clear() {
    AppLog.clear();
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('日志已清空')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = AppLog.entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('诊断日志'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '清空',
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('请求日志 ${entries.length} 条  ECH 日志 ${_echLogs.length} 条',
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('复制'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('分享'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: SelectableText(
                      _entryLine(entry),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                if (_echLogs.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('--- ECH 引擎日志 ---',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  for (final line in _echLogs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SelectableText(
                        line,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _entryLine(AppLogEntry entry) {
    final time = entry.timestamp;
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
    return '$stamp ${entry.message}';
  }
}
