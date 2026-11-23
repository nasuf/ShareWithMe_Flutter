part of '../../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final ShareController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController backendController;
  late final FocusNode backendFocusNode;

  @override
  void initState() {
    super.initState();
    backendController = TextEditingController(
      text: widget.controller.api.baseUrl,
    );
    backendFocusNode = FocusNode();
  }

  @override
  void dispose() {
    backendFocusNode.dispose();
    backendController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentBaseUrl = widget.controller.api.baseUrl;
    if (!backendFocusNode.hasFocus &&
        backendController.text != currentBaseUrl) {
      backendController.text = currentBaseUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 128),
      children: [
        _ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                eyebrow: '',
                title: '设置',
                subtitle: '连接、备份与系统分享入口。',
              ),
              const SizedBox(height: 10),
              _SettingsGroup(
                title: '外观',
                children: [
                  _ThemeModeRow(controller: widget.controller),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsGroup(
                title: '资料管理',
                children: [
                  _SettingsActionRow(
                    icon: Icons.description_outlined,
                    title: '复制 Markdown',
                    subtitle: '适合阅读与迁移到笔记软件',
                    onTap: () => _copyExport(context, json: false),
                  ),
                  _SettingsActionRow(
                    icon: Icons.data_object,
                    title: '复制 JSON 备份',
                    subtitle: '保留完整结构化内容',
                    onTap: () => _copyExport(context, json: true),
                  ),
                  _SettingsActionRow(
                    icon: Icons.upload_file_outlined,
                    title: '导入 JSON 备份',
                    subtitle: '合并已有资料与标签',
                    onTap: () => _showImportJsonSheet(context),
                    last: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsGroup(
                title: '服务连接',
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: TextField(
                      controller: backendController,
                      focusNode: backendFocusNode,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Backend URL',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _saveBackendUrl(context),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('保存并测试'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: '恢复默认地址',
                          onPressed: () => _resetBackendUrl(context),
                          icon: const Icon(Icons.restore),
                        ),
                      ],
                    ),
                  ),
                  _ConnectionStatusRow(
                    message: widget.controller.healthMessage ?? '等待连接',
                  ),
                  _SettingsActionRow(
                    icon: Icons.psychology_alt_outlined,
                    title: '检测 AI 分析服务',
                    subtitle: '验证摘要、收藏夹与关键词能力',
                    onTap: widget.controller.checkingAnalyzer
                        ? null
                        : widget.controller.checkAnalyzer,
                    loading: widget.controller.checkingAnalyzer,
                    last: widget.controller.analyzerStatus == null,
                  ),
                  if (widget.controller.analyzerStatus != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _AnalyzerStatusBanner(
                        status: widget.controller.analyzerStatus!,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const _SettingsGroup(
                title: '系统能力',
                children: [_SystemShareRow()],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copyExport(BuildContext context, {required bool json}) async {
    try {
      final content = json
          ? await widget.controller.api.exportJson()
          : await widget.controller.api.exportMarkdown();
      await Clipboard.setData(ClipboardData(text: content));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json ? 'JSON 备份已复制' : 'Markdown 已复制')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败：$error')));
      }
    }
  }

  Future<void> _saveBackendUrl(BuildContext context) async {
    try {
      await widget.controller.setBackendUrl(backendController.text);
      backendController.text = widget.controller.api.baseUrl;
    } on FormatException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _resetBackendUrl(BuildContext context) async {
    backendController.text = defaultBackendUrl();
    await _saveBackendUrl(context);
  }

  Future<void> _showImportJsonSheet(BuildContext context) async {
    final result = await showModalBottomSheet<JsonImportResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.tokens.ink.withValues(alpha: 0.16),
      builder: (_) => _ImportJsonSheet(controller: widget.controller),
    );
    if (!context.mounted || result == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '导入完成：新增 ${result.createdCount}，合并 ${result.mergedCount}',
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: t.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GlassPanel(
          padding: EdgeInsets.zero,
          radius: 24,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool last;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: t.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21, color: t.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: t.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: t.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: t.mutedInk),
          ],
        ),
      ),
    );
  }
}

class _ConnectionStatusRow extends StatelessWidget {
  const _ConnectionStatusRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = t.brightness == Brightness.dark;
    final healthy = message.contains('已配置') || message.contains('正常');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: healthy
            ? (dark ? const Color(0xFF143020) : const Color(0xFFEEF7F1))
            : (dark ? const Color(0xFF1F2330) : const Color(0xFFF2F4F7)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            healthy ? Icons.check_circle_outline : Icons.info_outline,
            size: 17,
            color: healthy ? const Color(0xFF3B7D56) : t.mutedInk,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: t.mutedInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 21, color: t.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主题',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: t.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '切换浅色、深色或跟随系统',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: t.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GlassSegmented<AppThemeMode>(
            options: const [
              (AppThemeMode.system, Icons.brightness_auto_outlined, '跟随系统'),
              (AppThemeMode.light, Icons.light_mode_outlined, '浅色'),
              (AppThemeMode.dark, Icons.dark_mode_outlined, '深色'),
            ],
            value: controller.themeMode,
            onChanged: controller.setThemeMode,
          ),
        ],
      ),
    );
  }
}

/// Glass segmented control with the tab bar's behaviour: a soft pill rests
/// under the selected option; pressing lifts it into a magnifying glass
/// droplet that follows the finger across options and springs into place.
class _GlassSegmented<T> extends StatefulWidget {
  const _GlassSegmented({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T, IconData, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  State<_GlassSegmented<T>> createState() => _GlassSegmentedState<T>();
}

class _GlassSegmentedState<T> extends State<_GlassSegmented<T>>
    with TickerProviderStateMixin {
  static const _height = 48.0;
  static const _inset = 4.0;
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 30,
  );

  int get _index => widget.options
      .indexWhere((option) => option.$1 == widget.value)
      .clamp(0, widget.options.length - 1);

  late final AnimationController position = AnimationController.unbounded(
    vsync: this,
    value: _index.toDouble(),
  );
  late final AnimationController lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 320),
  );
  bool interacting = false;
  double slotWidth = 1;

  @override
  void dispose() {
    position.dispose();
    lift.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GlassSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!interacting && oldWidget.value != widget.value) {
      _settleTo(_index.toDouble(), 0);
    }
  }

  double _slotAt(double dx) => ((dx - _inset) / slotWidth - 0.5).clamp(
    0.0,
    widget.options.length - 1.0,
  );

  void _settleTo(double target, double velocity) {
    position.animateWith(
      SpringSimulation(_spring, position.value, target, velocity),
    );
  }

  void _press(double dx) {
    interacting = true;
    position.stop();
    lift.forward();
    HapticFeedback.selectionClick();
  }

  void _drag(double dx) {
    final slot = _slotAt(dx);
    if (slot.round() != position.value.round()) {
      HapticFeedback.selectionClick();
    }
    position.value = slot;
  }

  void _release({double? toSlot, double velocity = 0}) {
    final target = (toSlot ?? position.value).round().clamp(
      0,
      widget.options.length - 1,
    );
    interacting = false;
    _settleTo(target.toDouble(), velocity);
    lift.reverse();
    if (target != _index) {
      widget.onChanged(widget.options[target].$1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          slotWidth =
              (constraints.maxWidth - _inset * 2) / widget.options.length;
          return Semantics(
            container: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _press(d.localPosition.dx),
              onTapUp: (d) => _release(toSlot: _slotAt(d.localPosition.dx)),
              onTapCancel: () {
                if (interacting) _release();
              },
              onHorizontalDragStart: (d) {
                if (!interacting) _press(d.localPosition.dx);
                _drag(d.localPosition.dx);
              },
              onHorizontalDragUpdate: (d) => _drag(d.localPosition.dx),
              onHorizontalDragEnd: (d) => _release(
                velocity: d.velocity.pixelsPerSecond.dx / slotWidth,
              ),
              onHorizontalDragCancel: () => _release(),
              child: AnimatedBuilder(
                animation: Listenable.merge([position, lift]),
                builder: (context, _) => Transform.scale(
                  scale: 1 - 0.03 * Curves.easeOut.transform(lift.value),
                  child: _buildTrack(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrack(BuildContext context) {
    final t = context.tokens;
    final pos = position.value;
    final lifted = Curves.easeOut.transform(lift.value);
    final active = pos.round();
    final centerX = _inset + slotWidth * (pos + 0.5);
    final pillWidth = slotWidth;
    const pillHeight = _height - _inset * 2;
    final dropWidth = pillWidth * (1 + 0.14 * lifted);
    final dropHeight = pillHeight * (1 + 0.3 * lifted);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: LiquidGlass(
            radius: _height / 2,
            blur: 12,
            opacity: 0.55,
            shadow: false,
            child: Stack(
              children: [
                Positioned(
                  left: centerX - pillWidth / 2,
                  top: _inset,
                  width: pillWidth,
                  height: pillHeight,
                  child: Opacity(
                    opacity: 1 - lifted,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.brightness == Brightness.dark
                            ? t.ink.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(pillHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: t.glassShadow.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(_inset),
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.options.length; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: i == active,
                            label: widget.options[i].$3,
                            excludeSemantics: true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.options[i].$2,
                                  size: 17,
                                  color: i == active ? t.accent : t.mutedInk,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    widget.options[i].$3,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: i == active ? t.accent : t.ink,
                                      fontSize: 13.5,
                                      fontWeight: i == active
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (lifted > 0.01)
          Positioned(
            left: centerX - dropWidth / 2,
            top: _height / 2 - dropHeight / 2,
            width: dropWidth,
            height: dropHeight,
            child: IgnorePointer(child: _GlassDroplet(lift: lifted)),
          ),
      ],
    );
  }
}

class _SystemShareRow extends StatelessWidget {
  const _SystemShareRow();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        leading: Icon(Icons.ios_share, color: t.accent),
        title: Text(
          '系统分享入口',
          style: TextStyle(color: t.ink),
        ),
        subtitle: Text(
          'iOS 与 Android 分享面板',
          style: TextStyle(color: t.mutedInk),
        ),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '支持从其他 App 分享文本与链接；iOS 使用 Share Extension，真机签名需要匹配 Apple Developer App Group。',
          ),
        ],
      ),
    );
  }
}
