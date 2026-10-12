import 'package:flutter/material.dart';
import 'package:card_settings_ui/list/settings_list.dart';
import 'package:card_settings_ui/section/settings_section.dart';
import 'package:card_settings_ui/tile/settings_tile.dart';

import 'settings_surface.dart';

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
            SettingsSurface(
              child: SettingsList(
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
    this.labelBuilder,
  }) : super(title: title, subtitle: subtitle, leading: leading);

  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;
  final String Function(double value)? labelBuilder;

  @override
  SettingsTile get tile => _SettingsSliderTile(
        text: title,
        subtitle: subtitle,
        leading: leading,
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
        labelBuilder: labelBuilder,
      );
}

class _SettingsSliderTile extends SettingsTile<dynamic> {
  _SettingsSliderTile({
    required String text,
    String? subtitle,
    Widget? leading,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    String Function(double value)? labelBuilder,
  })  : _subtitle = subtitle,
        _value = value,
        _min = min,
        _max = max,
        _divisions = divisions,
        _label = label,
        _onChanged = onChanged,
        _labelBuilder = labelBuilder,
        super(title: Text(text), leading: leading);

  final String? _subtitle;
  final double _value;
  final double _min;
  final double _max;
  final int _divisions;
  final String _label;
  final ValueChanged<double> _onChanged;
  final String Function(double value)? _labelBuilder;

  @override
  Widget build(BuildContext context) => _SettingsSliderContent(
        title: title,
        subtitle: _subtitle,
        leading: leading,
        value: _value,
        min: _min,
        max: _max,
        divisions: _divisions,
        label: _label,
        onChanged: _onChanged,
        labelBuilder: _labelBuilder,
      );
}

class _SettingsSliderContent extends StatefulWidget {
  const _SettingsSliderContent({
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
    this.labelBuilder,
  });

  final Widget title;
  final String? subtitle;
  final Widget? leading;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;
  final String Function(double value)? labelBuilder;

  @override
  State<_SettingsSliderContent> createState() => _SettingsSliderContentState();
}

class _SettingsSliderContentState extends State<_SettingsSliderContent> {
  late double _value = widget.value;

  @override
  void didUpdateWidget(covariant _SettingsSliderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _value) {
      if (!mounted) return;
      setState(() => _value = widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelBuilder = widget.labelBuilder;
    final labelText = labelBuilder != null ? labelBuilder(_value) : widget.label;
    final subtitleText = (labelBuilder != null && widget.subtitle != null && widget.subtitle == widget.label)
        ? labelBuilder(_value)
        : widget.subtitle;
    return SettingsTile(
      leading: widget.leading,
      title: widget.title,
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitleText != null) Text(subtitleText!),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: labelText,
            onChanged: (value) {
              if (!mounted) return;
              setState(() => _value = value);
            },
            onChangeEnd: (value) {
              if (!mounted) return;
              setState(() => _value = value);
              widget.onChanged(value);
            },
          ),
        ],
      ),
      trailing: Text(labelText),
    );
  }
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