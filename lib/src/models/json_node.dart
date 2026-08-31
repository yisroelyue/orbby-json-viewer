/// JSON 节点类型。
enum JsonNodeType {
  object,
  array,
  string_,
  number_,
  boolean_,
  null_,
}

/// JSON 树节点模型，由 [JsonNode.fromValue] 递归构建。
class JsonNode {
  JsonNode({
    this.key,
    required this.value,
    required this.type,
    this.depth = 0,
    this.isExpanded = true,
    this.children,
    this.parent,
  });

  /// 键名。null 表示根节点或数组元素。
  final String? key;

  /// 父节点。根节点为 null。
  final JsonNode? parent;

  /// 原始 JSON 值。
  final dynamic value;

  /// 节点类型。
  final JsonNodeType type;

  /// 嵌套深度，用于缩进计算。
  final int depth;

  /// 对象/数组是否展开。
  bool isExpanded;

  /// 对象/数组的子节点；基础类型节点为 null。
  final List<JsonNode>? children;

  /// 子节点数量。
  int get childCount => children?.length ?? 0;

  /// 是否可折叠（对象/数组）。
  bool get isContainer => children != null;

  /// 值展示文本（不包含引号包裹，由调用方决定样式）。
  /// 字符串不截断，超宽由界面用省略号收起，保证选中复制时内容完整。
  String get displayValue {
    switch (type) {
      case JsonNodeType.string_:
        return value as String? ?? '';
      case JsonNodeType.number_:
        return value.toString();
      case JsonNodeType.boolean_:
        return value.toString();
      case JsonNodeType.null_:
        return 'null';
      case JsonNodeType.object:
        return '{$childCount keys}';
      case JsonNodeType.array:
        return '[$childCount items]';
    }
  }

  /// 类型标签文本。
  String get typeLabel {
    switch (type) {
      case JsonNodeType.object:
        return 'object';
      case JsonNodeType.array:
        return 'array';
      case JsonNodeType.string_:
        return 'string';
      case JsonNodeType.number_:
        return 'number';
      case JsonNodeType.boolean_:
        return 'boolean';
      case JsonNodeType.null_:
        return 'null';
    }
  }

  /// JSONPath 风格路径，如 `$.user.items[0]`。
  String get path {
    final p = parent;
    if (p == null) return r'$';
    if (p.type == JsonNodeType.array) {
      final index = p.children!.indexOf(this);
      return '${p.path}[$index]';
    }
    return '${p.path}.${key ?? ''}';
  }

  /// 从任意 JSON 值递归构建树。
  factory JsonNode.fromValue(
    dynamic value, {
    String? key,
    int depth = 0,
    JsonNode? parent,
  }) {
    if (value is Map) {
      final node = JsonNode(
        key: key,
        value: value,
        type: JsonNodeType.object,
        depth: depth,
        parent: parent,
        children: <JsonNode>[],
      );
      node.children!.addAll([
        for (final entry in value.entries)
          JsonNode.fromValue(
            entry.value,
            key: entry.key.toString(),
            depth: depth + 1,
            parent: node,
          ),
      ]);
      return node;
    }
    if (value is List) {
      final node = JsonNode(
        key: key,
        value: value,
        type: JsonNodeType.array,
        depth: depth,
        parent: parent,
        children: <JsonNode>[],
      );
      node.children!.addAll([
        for (int i = 0; i < value.length; i++)
          JsonNode.fromValue(value[i], key: null, depth: depth + 1, parent: node),
      ]);
      return node;
    }
    final type = value is String
        ? JsonNodeType.string_
        : value is num
            ? JsonNodeType.number_
            : value is bool
                ? JsonNodeType.boolean_
                : JsonNodeType.null_;
    return JsonNode(
      key: key,
      value: value,
      type: type,
      depth: depth,
    );
  }
}
