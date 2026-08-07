import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import 'src/json_viewer_screen.dart';

class JsonViewerApp extends StatefulWidget {
  const JsonViewerApp({super.key});

  @override
  State<JsonViewerApp> createState() => _JsonViewerAppState();
}

class _JsonViewerAppState extends State<JsonViewerApp> {
  static const _textPrimary = Color(0xFF1F1F1F);

  bool _isMaximized = false;

  Future<void> _toggleMaximize() async {
    final maximized = await windowManager.isMaximized();
    if (maximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    if (!mounted) return;
    setState(() => _isMaximized = !maximized);
  }

  Future<void> _closeWindow() async {
    // 独立应用：关闭窗口即退出进程
    await windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JSON 查看器',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF7C4DFF),
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Microsoft YaHei',
      ),
      home: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: Column(
            children: [
              _buildTitleBar(),
              const Expanded(child: JsonViewerScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(color: Color(0xFFF0F0F0)),
        child: Row(
          children: [
            const SizedBox(width: 4),
            SvgPicture.asset('assets/svg/JSON查看.svg', width: 18, height: 18),
            const SizedBox(width: 8),
            Text(
              'JSON 查看器',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
            const Spacer(),
            _TitleBarBtn(
              icon: Icons.minimize_rounded,
              onTap: () => windowManager.minimize(),
            ),
            const SizedBox(width: 4),
            _TitleBarBtn(
              icon: _isMaximized ? Icons.filter : Icons.filter_none,
              onTap: _toggleMaximize,
            ),
            const SizedBox(width: 4),
            _TitleBarBtn(
              icon: Icons.close_rounded,
              onTap: _closeWindow,
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBarBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TitleBarBtn({required this.icon, required this.onTap});

  @override
  State<_TitleBarBtn> createState() => _TitleBarBtnState();
}

class _TitleBarBtnState extends State<_TitleBarBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(widget.icon, color: Colors.black54, size: 16),
        ),
      ),
    );
  }
}
