part of '../../main.dart';

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
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.82),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
              ),
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
