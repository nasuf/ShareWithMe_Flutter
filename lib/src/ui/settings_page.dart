part of '../../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final ShareController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController backendController;

  @override
  void initState() {
    super.initState();
    backendController = TextEditingController(
      text: widget.controller.api.baseUrl,
    );
  }

  @override
  void dispose() {
    backendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 112),
      children: [
        const PageHeader(
          eyebrow: 'Settings',
          title: '设置',
          subtitle: '管理后端、AI 解析、分享入口和资料备份。',
        ),
        const SizedBox(height: 6),
        _Section(
          title: '资料备份',
          icon: Icons.download_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  widget.controller.api.exportMarkdownUri(),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.description_outlined),
                label: const Text('导出 Markdown'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  widget.controller.api.exportJsonUri(),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.data_object),
                label: const Text('导出 JSON 备份'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showImportJsonSheet(context),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('导入 JSON 备份'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: '后端连接',
          icon: Icons.dns_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: backendController,
                decoration: const InputDecoration(
                  labelText: 'Backend URL',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _saveBackendUrl(context),
                    icon: const Icon(Icons.check),
                    label: const Text('保存并测试'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _resetBackendUrl(context),
                    icon: const Icon(Icons.restore),
                    label: const Text('恢复默认'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.controller.healthMessage ?? '等待连接'),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: widget.controller.checkingAnalyzer
                    ? null
                    : widget.controller.checkAnalyzer,
                icon: widget.controller.checkingAnalyzer
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology_alt_outlined),
                label: const Text('检测 DeepSeek'),
              ),
              if (widget.controller.analyzerStatus != null) ...[
                const SizedBox(height: 8),
                _AnalyzerStatusBanner(
                  status: widget.controller.analyzerStatus!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _Section(
          title: '系统分享入口',
          icon: Icons.ios_share,
          child: Text(
            'Android 已声明文本、URL、图片、视频和文件分享入口；iOS 已包含 Share Extension target。真机运行时需要 Apple Developer App Group 能力匹配。',
          ),
        ),
      ],
    );
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

class _ImportJsonSheet extends StatefulWidget {
  const _ImportJsonSheet({required this.controller});

  final ShareController controller;

  @override
  State<_ImportJsonSheet> createState() => _ImportJsonSheetState();
}

class _ImportJsonSheetState extends State<_ImportJsonSheet> {
  final jsonController = TextEditingController();
  String? localError;

  @override
  void dispose() {
    jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final errorText = localError ?? widget.controller.error;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '导入 JSON 备份',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jsonController,
                  enabled: !widget.controller.importingBackup,
                  minLines: 6,
                  maxLines: 12,
                  decoration: InputDecoration(
                    hintText: '粘贴 share-with-me-export.json 内容',
                    alignLabelWithHint: true,
                    errorText: localError,
                  ),
                  onChanged: (_) {
                    if (localError != null) {
                      setState(() => localError = null);
                    }
                  },
                ),
                if (errorText != null && localError == null) ...[
                  const SizedBox(height: 10),
                  _SettingsInlineNotice(
                    icon: Icons.error_outline,
                    text: errorText,
                    color: const Color(0xFFFFF3ED),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.controller.importingBackup
                        ? null
                        : _importBackup,
                    icon: widget.controller.importingBackup
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(
                      widget.controller.importingBackup ? '导入中' : '导入',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _importBackup() async {
    if (jsonController.text.trim().isEmpty) {
      setState(() => localError = '请先粘贴 JSON 备份内容');
      return;
    }
    setState(() => localError = null);
    final result = await widget.controller.importJsonBackup(
      jsonController.text,
    );
    if (!mounted || result == null) {
      return;
    }
    Navigator.of(context).pop(result);
  }
}

class _SettingsInlineNotice extends StatelessWidget {
  const _SettingsInlineNotice({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3DD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _AnalyzerStatusBanner extends StatelessWidget {
  const _AnalyzerStatusBanner({required this.status});

  final AnalyzerStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.ok ? const Color(0xFFEAF7EF) : const Color(0xFFFFF3ED);
    final icon = status.ok
        ? Icons.check_circle_outline
        : Icons.warning_amber_outlined;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3DD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${status.provider} · ${status.model}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(status.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
