import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/json_node.dart';
import 'json_node_tile.dart';

/// 递归渲染 JSON 树，支持节点折叠/展开、全部展开/折叠、
/// 文本选中复制（SelectionArea）与 Ctrl+F 搜索高亮定位。
class JsonTreeView extends StatefulWidget {
  const JsonTreeView({
    super.key,
    required this.rootNode,
    this.searchVisible = false,
    this.searchQuery,
    this.searchController,
    this.searchFocusNode,
    this.onQueryChanged,
    this.onSearchClosed,
    this.onSearchOpen,
  });

  final JsonNode rootNode;

  /// 是否显示搜索栏。
  final bool searchVisible;

  /// 当前搜索关键字；null 或空表示未搜索。
  final String? searchQuery;

  /// 搜索输入框控制器（由外部持有，重新解析 JSON 时输入内容不丢）。
  final TextEditingController? searchController;

  /// 搜索输入框焦点。
  final FocusNode? searchFocusNode;

  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onSearchClosed;
  final VoidCallback? onSearchOpen;

  @override
  State<JsonTreeView> createState() => _JsonTreeViewState();
}

class _JsonTreeViewState extends State<JsonTreeView> {
  /// 当前命中项与其他命中项的高亮色。
  static const _currentMatchColor = Color(0xFFFFAB40);
  static const _matchColor = Color(0xFFFFF176);

  /// 命中搜索的节点（全树范围，含折叠分支内的）。
  List<JsonNode> _matches = const [];
  final Set<JsonNode> _matchSet = {};
  int _currentIndex = 0;

  /// 可见节点对应的 GlobalKey，用于搜索命中时滚动定位。
  final Map<JsonNode, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _refreshMatches();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCurrentVisible());
  }

  @override
  void didUpdateWidget(covariant JsonTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootNode != widget.rootNode) _itemKeys.clear();
    if (oldWidget.rootNode != widget.rootNode ||
        oldWidget.searchQuery != widget.searchQuery) {
      _refreshMatches();
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCurrentVisible());
    }
  }

  // ── 搜索 ────────────────────────────────────────────────────

  void _refreshMatches() {
    final query = (widget.searchQuery ?? '').trim().toLowerCase();
    final matches = <JsonNode>[];
    if (query.isNotEmpty) {
      void walk(JsonNode node) {
        if (_matchesQuery(node, query)) matches.add(node);
        for (final child in node.children ?? const <JsonNode>[]) {
          walk(child);
        }
      }

      walk(widget.rootNode);
    }
    // 展开命中节点所在分支，使其可见。
    for (final match in matches) {
      for (JsonNode? p = match.parent; p != null; p = p.parent) {
        p.isExpanded = true;
      }
    }
    _matches = matches;
    _matchSet
      ..clear()
      ..addAll(matches);
    _currentIndex = 0;
  }

  /// 键名或原始值（字符串取完整内容，不受显示截断影响）是否包含关键字。
  bool _matchesQuery(JsonNode node, String query) {
    if (node.key?.toLowerCase().contains(query) ?? false) return true;
    if (node.isContainer) return false;
    final raw = node.value?.toString() ?? 'null';
    return raw.toLowerCase().contains(query);
  }

  void _goTo(int delta) {
    if (_matches.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + delta) % _matches.length;
      // 若命中项所在分支已被手动折叠，重新展开。
      for (JsonNode? p = _matches[_currentIndex].parent; p != null; p = p.parent) {
        p.isExpanded = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCurrentVisible());
    widget.searchFocusNode?.requestFocus();
  }

  void _ensureCurrentVisible() {
    if (_matches.isEmpty) return;
    final itemContext = _itemKeys[_matches[_currentIndex]]?.currentContext;
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 120),
        alignment: 0.15,
      );
    }
  }

  Color? _highlightFor(JsonNode node) {
    if (_matchSet.isEmpty) return null;
    if (identical(_matches[_currentIndex], node)) return _currentMatchColor;
    if (_matchSet.contains(node)) return _matchColor;
    return null;
  }

  // ── 树操作 ──────────────────────────────────────────────────

  /// 将可见节点（考虑折叠状态）扁平化为一列。
  List<JsonNode> _flatten(JsonNode node) {
    final result = <JsonNode>[node];
    if (node.isExpanded && node.children != null) {
      for (final child in node.children!) {
        result.addAll(_flatten(child));
      }
    }
    return result;
  }

  void _toggle(JsonNode node) {
    setState(() => node.isExpanded = !node.isExpanded);
  }

  void _setAllExpanded(JsonNode node, bool expanded) {
    node.isExpanded = expanded;
    for (final child in node.children ?? const <JsonNode>[]) {
      _setAllExpanded(child, expanded);
    }
  }

  // ── 界面构建 ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nodes = _flatten(widget.rootNode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.searchVisible ? _buildSearchBar() : _buildToolbar(),
        Expanded(
          child: SelectionArea(
            child: Scrollbar(
              child: SingleChildScrollView(
                primary: true,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final node in nodes)
                      JsonNodeTile(
                        key: _itemKeys.putIfAbsent(node, () => GlobalKey()),
                        node: node,
                        onToggle: () => _toggle(node),
                        highlightColor: _highlightFor(node),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _setAllExpanded(widget.rootNode, true)),
            icon: const Icon(Icons.unfold_more, size: 15),
            label: const Text('全部展开', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F1F1F),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () => setState(() => _setAllExpanded(widget.rootNode, false)),
            icon: const Icon(Icons.unfold_less, size: 15),
            label: const Text('全部折叠', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F1F1F),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          _searchBtn(Icons.search, '搜索 (Ctrl+F)', widget.onSearchOpen),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final query = widget.searchQuery ?? '';
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.escape): () => widget.onSearchClosed?.call(),
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search, size: 15, color: Color(0xFF9E9E9E)),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: widget.searchController,
                focusNode: widget.searchFocusNode,
                autofocus: true,
                onChanged: widget.onQueryChanged,
                onSubmitted: (_) => _goTo(1),
                style: const TextStyle(fontSize: 12, color: Color(0xFF1F1F1F)),
                cursorColor: Colors.black54,
                keyboardAppearance: Brightness.light,
                decoration: InputDecoration(
                  hintText: '搜索键名或值…',
                  hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  constraints: const BoxConstraints(minHeight: 40),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                ),
              ),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                _matches.isEmpty ? '无结果' : '${_currentIndex + 1}/${_matches.length}',
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
              ),
            ],
            _searchBtn(Icons.keyboard_arrow_up, '上一个 (Shift 结果回退)', () => _goTo(-1)),
            _searchBtn(Icons.keyboard_arrow_down, '下一个 (Enter)', () => _goTo(1)),
            _searchBtn(Icons.close, '关闭 (Esc)', () => widget.onSearchClosed?.call()),
          ],
        ),
      ),
    );
  }

  Widget _searchBtn(IconData icon, String tooltip, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: const Color(0xFF616161)),
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
    );
  }
}
