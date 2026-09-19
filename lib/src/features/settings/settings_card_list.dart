import 'package:flutter/material.dart';
import 'package:card_settings_ui/list/settings_list.dart';
import 'package:card_settings_ui/section/settings_section.dart';
import 'package:card_settings_ui/tile/settings_tile.dart';

class SettingsCardList extends StatelessWidget {
  const SettingsCardList({super.key, required this.children, this.title, this.padding = EdgeInsets.zero});

  final List<Widget> children;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tiles = children.whereType<SettingsCardItem>().toList();
    final content = children.where((child) => child is! SettingsCardItem).toList();
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tiles.isNotEmpty)
            SettingsList(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              contentPadding: EdgeInsets.zero,
              sections: [
                SettingsSection(
                  title: title == null ? null : Text(title!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  tiles: tiles.map((item) => item.tile).toList(),
                ),
              ],
            ),
          for (final child in content)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class SettingsCardItem extends StatelessWidget {
  const SettingsCardItem({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap, this.enabled = true});

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  SettingsTile get tile {
    if (trailing case final Switch toggle) {
      return SettingsTile.switchTile(
        initialValue: toggle.value,
        onToggle: (value) {
          toggle.onChanged?.call(value ?? !toggle.value);
        },
        leading: leading,
        title: Text(title),
        description: subtitle == null ? null : Text(subtitle!),
        enabled: enabled && toggle.onChanged != null,
      );
    }
    return SettingsTile.navigation(
      onPressed: onTap == null ? null : (_) => onTap!(),
      leading: leading,
      title: Text(title),
      description: subtitle == null ? null : Text(subtitle!),
      value: trailing,
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) => tile;
}

class SettingsSliderItem extends SettingsCardItem {
  SettingsSliderItem({
    required String title,
    String? subtitle,
    Widget? leading,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  }) : super(title: title, subtitle: subtitle, leading: leading);

  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  SettingsTile get tile => SettingsTile(
        leading: leading,
        title: Text(title),
        description: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) Text(subtitle!),
            Slider(value: value, min: min, max: max, divisions: divisions, label: label, onChanged: onChanged),
          ],
        ),
        trailing: Text(label),
      );
}

class SettingsMenuItem<T> extends SettingsCardItem {
  SettingsMenuItem({
    required String title,
    String? subtitle,
    Widget? leading,
    required this.value,
    required this.options,
    required this.label,
    required this.onSelected,
    this.enabled = true,
  }) : super(title: title, subtitle: subtitle, leading: leading);

  final T value;
  final List<T> options;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;
  final bool enabled;

  Future<void> _showMenu(BuildContext context) async {
    final renderBox = context.findRenderObject()! as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final selected = await showMenu<T>(
      context: context,
      initialValue: value,
      position: RelativeRect.fromRect(position, Offset.zero & MediaQuery.sizeOf(context)),
      items: [for (final option in options) PopupMenuItem(value: option, child: Text(label(option)))],
    );
    if (selected != null) onSelected(selected);
  }

  @override
  SettingsTile get tile => SettingsTile.navigation(
        onPressed: _showMenu,
        leading: leading,
        title: Text(title),
        description: subtitle == null ? null : Text(subtitle!),
        value: Builder(
          builder: (context) => PopupMenuButton<T>(
            initialValue: value,
            onSelected: onSelected,
            itemBuilder: (context) => [for (final option in options) PopupMenuItem(value: option, child: Text(label(option)))],
          ),
        ),
        enabled: enabled,
      );
}
