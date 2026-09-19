import 'package:flutter_riverpod/flutter_riverpod.dart';

class CacheViewState {
  const CacheViewState({
    this.groupId = 'default',
    this.selected = const {},
    this.allExpanded = true,
    this.pinnedExpanded = true,
  });

  final String groupId;
  final Set<String> selected;
  final bool allExpanded;
  final bool pinnedExpanded;

  bool get selecting => selected.isNotEmpty;

  CacheViewState copyWith({String? groupId, Set<String>? selected, bool? allExpanded, bool? pinnedExpanded}) => CacheViewState(
        groupId: groupId ?? this.groupId,
        selected: selected ?? this.selected,
        allExpanded: allExpanded ?? this.allExpanded,
        pinnedExpanded: pinnedExpanded ?? this.pinnedExpanded,
      );
}

final cacheViewProvider = NotifierProvider.autoDispose<CacheViewController, CacheViewState>(CacheViewController.new);

class CacheViewController extends AutoDisposeNotifier<CacheViewState> {
  @override
  CacheViewState build() => const CacheViewState();

  void selectGroup(String id) => state = CacheViewState(groupId: id);

  void toggleSelection(String id) {
    final selected = {...state.selected};
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    state = state.copyWith(selected: selected);
  }

  void selectAll(Iterable<String> ids) {
    final values = ids.toSet();
    state = state.copyWith(selected: values.isNotEmpty && values.every(state.selected.contains) ? {} : values);
  }

  void clearSelection() => state = state.copyWith(selected: {});

  void toggleAllExpanded() => state = state.copyWith(allExpanded: !state.allExpanded);

  void togglePinnedExpanded() => state = state.copyWith(pinnedExpanded: !state.pinnedExpanded);
}
