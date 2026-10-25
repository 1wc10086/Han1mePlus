import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/platform_paths.dart';

Future<String?> showDownloadPathDialog(BuildContext context, {required String initialPath}) =>
    showDialog<String>(context: context, builder: (_) => _DownloadPathDialog(initialPath: initialPath));

class _DownloadPathDialog extends StatefulWidget {
  const _DownloadPathDialog({required this.initialPath});

  final String initialPath;

  @override
  State<_DownloadPathDialog> createState() => _DownloadPathDialogState();
}

class _DownloadPathDialogState extends State<_DownloadPathDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialPath);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _browse() async {
    final selected = await FilePicker.platform.getDirectoryPath(
      dialogTitle: AppLocalizations.of(context)!.downloadPath,
      initialDirectory: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
    );
    if (selected != null) setState(() => _controller.text = selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.downloadPath),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.downloadPath,
                hintText: platformDownloadPathHint(l10n.defaultDownloadPath),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(tooltip: l10n.chooseFolder, onPressed: _browse, icon: const Icon(Icons.folder_open_outlined)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: Text(l10n.save)),
      ],
    );
  }
}
