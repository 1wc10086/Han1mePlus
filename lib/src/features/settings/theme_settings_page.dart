import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import 'settings_controller.dart';
import 'settings_card_list.dart';

class ThemeSettingsPage extends ConsumerStatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  ConsumerState<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends ConsumerState<ThemeSettingsPage> {
  var _useWallpaperColors = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final dynamicScheme = Theme.of(context).brightness == Brightness.dark
            ? darkDynamic
            : lightDynamic;
        final palettes = _useWallpaperColors
            ? _wallpaperPalettes(dynamicScheme)
            : _basicPalettes;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.themeAndColor)),
          body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _ToggleGroup(
            actions: [
              M3EToggleButtonGroupAction(label: Text(l10n.wallpaperColors), semanticLabel: l10n.wallpaperColors),
              M3EToggleButtonGroupAction(label: Text(l10n.basicColors), semanticLabel: l10n.basicColors),
            ],
               selectedIndex: _useWallpaperColors ? 0 : 1,
               onSelectedIndexChanged: (value) {
                 if (value != null) setState(() => _useWallpaperColors = value == 0);
               },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 88,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: palettes.length + (_useWallpaperColors ? 0 : 1),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == palettes.length) {
                  return _CustomPaletteButton(
                    selected: settings.themeColor == AppThemeColor.custom,
                    color: _colorFromHex(settings.customThemeColor),
                    onTap: () => _setCustomColor(settings),
                  );
                }
                final palette = palettes[index];
                return _MiniPalette(
                  selected: _useWallpaperColors ? settings.useMonetColors && index == 0 : !settings.useMonetColors && settings.themeColor == palette.color,
                  colors: palette.colors,
                  onTap: () => controller.saveChanges((current) => _useWallpaperColors ? current.copyWith(useMonetColors: true) : current.copyWith(useMonetColors: false, themeColor: palette.color)),
                );
              },
            ),
          ),
          const Divider(),
          _ToggleGroup(
            actions: [
              M3EToggleButtonGroupAction(icon: const Icon(Icons.brightness_auto_outlined), semanticLabel: l10n.followSystem),
              M3EToggleButtonGroupAction(icon: const Icon(Icons.light_mode_outlined), semanticLabel: l10n.light),
              M3EToggleButtonGroupAction(icon: const Icon(Icons.dark_mode_outlined), semanticLabel: l10n.dark),
            ],
               selectedIndex: settings.themeMode.index,
               onSelectedIndexChanged: (value) {
                 if (value != null) controller.saveChanges((current) => current.copyWith(themeMode: AppThemeMode.values[value]));
               },
          ),
          const SizedBox(height: 8),
            SettingsCardList(children: [
              SettingsCardItem(
                title: l10n.amoledMode,
                subtitle: l10n.amoledModeDescription,
                leading: const Icon(Icons.contrast_outlined),
                trailing: Switch(value: settings.amoledMode, onChanged: (value) => controller.saveChanges((current) => current.copyWith(amoledMode: value))),
              ),
              SettingsSliderItem(
               title: l10n.textSize,
               value: settings.textScale,
               min: .8,
               max: 1.4,
               divisions: 6,
               label: '${(settings.textScale * 100).round()}%',
               onChanged: (value) => controller.saveChanges((current) => current.copyWith(textScale: value)),
             ),
           ]),
          ],
        ),
      );
      },
    );
  }

  Future<void> _setCustomColor(AppSettings settings) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _CustomColorDialog(initialColor: settings.customThemeColor),
    );
    if (value != null) await ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(useMonetColors: false, themeColor: AppThemeColor.custom, customThemeColor: value));
  }
}

class _ToggleGroup extends StatelessWidget {
  const _ToggleGroup({required this.actions, required this.selectedIndex, required this.onSelectedIndexChanged});

  final List<M3EToggleButtonGroupAction> actions;
  final int? selectedIndex;
  final ValueChanged<int?> onSelectedIndexChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 32) / actions.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: M3EToggleButtonGroup(
              type: M3EButtonGroupType.connected,
              overflow: M3EButtonGroupOverflow.scroll,
              selectedIndex: selectedIndex,
              onSelectedIndexChanged: onSelectedIndexChanged,
              actions: [for (final action in actions) M3EToggleButtonGroupAction(icon: action.icon, checkedIcon: action.checkedIcon, label: action.label, checkedLabel: action.checkedLabel, semanticLabel: action.semanticLabel, width: width)],
            ),
          );
        },
      );
}

class _Palette {
  const _Palette(this.color, this.colors);
  final AppThemeColor color;
  final List<Color> colors;
}

const _basicPalettes = [
  _Palette(AppThemeColor.rose, [Color(0xffd35c87), Color(0xffffd9e4), Color(0xffffb0c7)]),
  _Palette(AppThemeColor.blue, [Color(0xff2775b5), Color(0xffd5e7ff), Color(0xff9ccaff)]),
  _Palette(AppThemeColor.teal, [Color(0xff1e8073), Color(0xffb9f1e5), Color(0xff7ed6c7)]),
  _Palette(AppThemeColor.amber, [Color(0xffae7500), Color(0xffffe9b5), Color(0xffffce6e)]),
  _Palette(AppThemeColor.green, [Color(0xff4c8529), Color(0xffd0f6b4), Color(0xffa5de82)]),
  _Palette(AppThemeColor.orange, [Color(0xffbc5700), Color(0xffffddb9), Color(0xffffb77c)]),
  _Palette(AppThemeColor.indigo, [Color(0xff687cbf), Color(0xffdce2ff), Color(0xffbdc7ff)]),
  _Palette(AppThemeColor.pink, [Color(0xffc04d80), Color(0xffffd9e6), Color(0xffffaec9)]),
  _Palette(AppThemeColor.purple, [Color(0xff8c5ab0), Color(0xfff0d8ff), Color(0xffdfb5ff)]),
];

List<_Palette> _wallpaperPalettes(ColorScheme? scheme) {
  if (scheme == null) return const [];
  return [
    _Palette(
      AppThemeColor.purple,
      [scheme.primary, scheme.secondaryContainer, scheme.tertiaryContainer],
    ),
    _Palette(
      AppThemeColor.purple,
      [scheme.secondary, scheme.tertiaryContainer, scheme.primaryContainer],
    ),
    _Palette(
      AppThemeColor.purple,
      [scheme.tertiary, scheme.primaryContainer, scheme.secondaryContainer],
    ),
  ];
}

class _MiniPalette extends StatelessWidget {
  const _MiniPalette({required this.selected, required this.colors, required this.onTap});
  final bool selected;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? scheme.primary : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox.square(
          dimension: 74,
          child: Center(
            child: ClipOval(
              child: SizedBox.square(
                dimension: 50,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: colors[0]),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: FractionallySizedBox(
                        widthFactor: .58,
                        heightFactor: .5,
                        child: ColoredBox(color: colors[1]),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: FractionallySizedBox(
                        widthFactor: .58,
                        heightFactor: .5,
                        child: ColoredBox(color: colors[2]),
                      ),
                    ),
                    if (selected)
                      Center(
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          child: const Icon(Icons.check, size: 18),
                        ),
                      ),
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

class _CustomPaletteButton extends StatelessWidget {
  const _CustomPaletteButton({required this.selected, required this.color, required this.onTap});
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _MiniPalette(selected: selected, colors: [color, color.withValues(alpha: .55), color.withValues(alpha: .75)], onTap: onTap);
}

Color _colorFromHex(String value) => Color(int.parse('ff$value', radix: 16));

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({required this.initialColor});
  final String initialColor;

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late final _controller = TextEditingController(text: widget.initialColor);
  var _isValid = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.customAccentColor),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 6,
        textCapitalization: TextCapitalization.characters,
        onChanged: (_) => setState(() => _isValid = true),
        decoration: InputDecoration(
          hintText: '62539F',
          errorText: _isValid ? null : l10n.invalidColor,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim().replaceFirst('#', '');
            if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value)) {
              setState(() => _isValid = false);
              return;
            }
            Navigator.pop(context, value.toUpperCase());
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
