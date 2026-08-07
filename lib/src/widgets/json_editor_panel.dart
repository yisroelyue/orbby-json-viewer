import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 左侧原始报文编辑面板：工具栏 + 可编辑文本框。
class JsonEditorPanel extends StatelessWidget {
  const JsonEditorPanel({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onOpenFile,
    this.onSaveFile,
    this.onFormat,
    this.onCompress,
    this.onCopy,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onOpenFile;
  final VoidCallback? onSaveFile;
  final VoidCallback? onFormat;
  final VoidCallback? onCompress;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): () => onSaveFile?.call(),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                color: Color(0xFF1F1F1F),
                fontSize: 13,
                fontFamily: 'Consolas',
                height: 1.5,
              ),
              cursorColor: Colors.black54,
              keyboardAppearance: Brightness.light,
              decoration: InputDecoration(
                hintText: '在此粘贴或输入 JSON 报文…',
                hintStyle: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 13,
                  fontFamily: 'Consolas',
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding: const EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _toolBtn(Icons.folder_open, '打开文件', onOpenFile),
          const SizedBox(width: 6),
          _toolBtn(Icons.save, '保存 (Ctrl+S)', onSaveFile),
          const SizedBox(width: 6),
          _toolBtn(Icons.unfold_more, '展开', onFormat),
          const SizedBox(width: 6),
          _toolBtn(Icons.compress, '压缩', onCompress),
          const Spacer(),
          _toolBtn(Icons.copy, '复制到剪贴板', onCopy),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String tooltip, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 17, color: Color(0xFF616161)),
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
