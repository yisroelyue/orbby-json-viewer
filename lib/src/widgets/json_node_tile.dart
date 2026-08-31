import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/json_node.dart';

/// 单个 JSON 树节点的行组件。
class JsonNodeTile extends StatelessWidget {
  const JsonNodeTile({
    super.key,
    required this.node,
    required this.onToggle,
    this.highlightColor,
  });

  final JsonNode node;
  final VoidCallback onToggle;

  /// 搜索命中时的行背景色；null 表示无高亮。
  final Color? highlightColor;

  // JSON 类型配色
  static const _stringColor = Color(0xFF2E7D32); // 绿
  static const _numberColor = Color(0xFF1565C0); // 蓝
  static const _boolColor = Color(0xFFE65100); // 橙
  static const _nullColor = Color(0xFF757575); // 灰
  static const _keyColor = Color(0xFF7B1FA2); // 紫
  static const _containerColor = Color(0xFF616161); // 灰

  /// 节点类型对应的图标。
  static IconData _iconFor(JsonNodeType type) {
    switch (type) {
      case JsonNodeType.object:
        return Icons.data_object;
      case JsonNodeType.array:
        return Icons.data_array;
      case JsonNodeType.string_:
        return Icons.text_fields;
      case JsonNodeType.number_:
        return Icons.tag;
      case JsonNodeType.boolean_:
        return Icons.toggle_on;
      case JsonNodeType.null_:
        return Icons.block;
    }
  }

  /// 节点类型对应的颜色。
  static Color _colorFor(JsonNodeType type) {
    switch (type) {
      case JsonNodeType.object:
        return _boolColor;
      case JsonNodeType.array:
        return _numberColor;
      case JsonNodeType.string_:
        return _stringColor;
      case JsonNodeType.number_:
        return _numberColor;
      case JsonNodeType.boolean_:
        return _boolColor;
      case JsonNodeType.null_:
        return _nullColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isContainer = node.isContainer;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isContainer ? onToggle : null,
        onSecondaryTapUp: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: Container(
          padding: EdgeInsets.only(
            left: node.depth * 20.0,
            right: 8,
            top: 2,
            bottom: 2,
          ),
          color: highlightColor ?? Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: isContainer
                    ? Icon(
                        node.isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 18,
                        color: Colors.black54,
                      )
                    : null,
              ),
              const SizedBox(width: 2),
              Icon(
                _iconFor(node.type),
                size: 15,
                color: _colorFor(node.type),
              ),
              const SizedBox(width: 6),
              if (node.key != null) ...[
                Text(
                  node.key!,
                  style: const TextStyle(
                    color: _keyColor,
                    fontSize: 13,
                    fontFamily: 'Consolas',
                  ),
                ),
                const Text(
                  ': ',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
              Expanded(
                child: _buildValue(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValue() {
    switch (node.type) {
      case JsonNodeType.string_:
        return Text(
          '"${node.displayValue}"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _stringColor, fontSize: 13, fontFamily: 'Consolas'),
        );
      case JsonNodeType.number_:
        return Text(
          node.displayValue,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _numberColor, fontSize: 13, fontFamily: 'Consolas'),
        );
      case JsonNodeType.boolean_:
        return Text(
          node.displayValue,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _boolColor, fontSize: 13, fontFamily: 'Consolas'),
        );
      case JsonNodeType.null_:
        return Text(
          node.displayValue,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _nullColor,
            fontSize: 13,
            fontFamily: 'Consolas',
            fontStyle: FontStyle.italic,
          ),
        );
      case JsonNodeType.object:
      case JsonNodeType.array:
        return Text(
          node.displayValue,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _containerColor,
            fontSize: 13,
            fontFamily: 'Consolas',
          ),
        );
    }
  }

  // ── 右键复制菜单 ────────────────────────────────────────────

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        if (node.key != null) _menuItem('key', '复制键名'),
        _menuItem('value', node.isContainer ? '复制 JSON' : '复制值'),
        _menuItem('path', '复制路径'),
      ],
    );
    if (choice == null || !context.mounted) return;
    final text = switch (choice) {
      'key' => node.key!,
      'path' => node.path,
      _ => node.isContainer
          ? const JsonEncoder.withIndent('  ').convert(node.value)
          : (node.value?.toString() ?? 'null'),
    };
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) _showCopiedSnack(context);
  }

  PopupMenuItem<String> _menuItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 34,
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1F1F1F)),
      ),
    );
  }

  void _showCopiedSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: const Text('已复制到剪贴板',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF333333),
        duration: const Duration(milliseconds: 1500),
      ));
  }
}
