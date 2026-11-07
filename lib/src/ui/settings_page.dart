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
      barrierColor: _ink.withValues(alpha: 0.16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GlassPanel(
          padding: EdgeInsets.zero,
          radius: 24,
          color: Colors.white.withValues(alpha: 0.62),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21, color: _accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _mutedInk),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right, size: 20, color: _mutedInk),
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
    final healthy = message.contains('已配置') || message.contains('正常');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: healthy ? const Color(0xFFEEF7F1) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            healthy ? Icons.check_circle_outline : Icons.info_outline,
            size: 17,
            color: healthy ? const Color(0xFF3B7D56) : _mutedInk,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _mutedInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemShareRow extends StatelessWidget {
  const _SystemShareRow();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.transparent,
      child: ExpansionTile(
        leading: Icon(Icons.ios_share, color: _accent),
        title: Text('系统分享入口'),
        subtitle: Text('iOS 与 Android 分享面板'),
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
