part of '../../main.dart';

Future<void> showAddLinkSheet(
  BuildContext context,
  ShareController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddLinkSheet(controller: controller),
  );
}

class _AddLinkSheet extends StatefulWidget {
  const _AddLinkSheet({required this.controller});

  final ShareController controller;

  @override
  State<_AddLinkSheet> createState() => _AddLinkSheetState();
}

class _AddLinkSheetState extends State<_AddLinkSheet> {
  final textController = TextEditingController();
  String? localError;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final errorText = localError ?? widget.controller.error;
        return GlassBackground(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: GlassPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '添加链接',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: '粘贴剪切板',
                        onPressed: widget.controller.analyzing
                            ? null
                            : _pasteClipboard,
                        icon: const Icon(Icons.content_paste),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    enabled: !widget.controller.analyzing,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: '粘贴任意分享文本或链接，例如小红书/今日头条/知乎/B站链接',
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
                    _InlineNotice(
                      icon: Icons.error_outline,
                      text: errorText,
                      color: const Color(0xFFFFF3ED),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.controller.analyzing ? null : _analyze,
                      icon: widget.controller.analyzing
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        widget.controller.analyzing ? '解析中' : '解析并整理',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _analyze() async {
    if (textController.text.trim().isEmpty) {
      setState(() => localError = '请先粘贴分享文本或链接');
      return;
    }
    setState(() => localError = null);
    final items = await widget.controller.analyzeSharedText(
      text: textController.text,
    );
    if (mounted && items.isNotEmpty) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      setState(() => localError = '剪切板里没有可解析文本');
      return;
    }
    setState(() {
      textController.text = text;
      localError = null;
    });
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
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
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
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
