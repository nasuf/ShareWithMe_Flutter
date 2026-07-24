part of '../../main.dart';

Future<void> showAddLinkSheet(
  BuildContext context,
  ShareController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: _ink.withValues(alpha: 0.16),
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
  final focusNode = FocusNode();
  String? localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    textController.dispose();
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.79),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.96)),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 22,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9CDD3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '收集链接',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: '从剪切板粘贴',
                          onPressed: widget.controller.analyzing
                              ? null
                              : _pasteClipboard,
                          icon: const Icon(Icons.content_paste),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _SupportedPlatformStrip(),
                    const SizedBox(height: 18),
                    TextField(
                      controller: textController,
                      focusNode: focusNode,
                      enabled: !widget.controller.analyzing,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: '粘贴分享文本或链接',
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
                        color: const Color(0xFFFFF1F0),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.controller.analyzing
                            ? null
                            : _analyze,
                        icon: widget.controller.analyzing
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 19),
                        label: Text(
                          widget.controller.analyzing ? '解析中' : '解析并收集',
                        ),
                      ),
                    ),
                  ],
                ),
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

class _SupportedPlatformStrip extends StatelessWidget {
  const _SupportedPlatformStrip();

  @override
  Widget build(BuildContext context) {
    const platforms = ['小红书', '今日头条', '哔哩哔哩', '知乎', '微博', '抖音', 'YouTube', 'X'];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: platforms.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) => Tooltip(
          message: platforms[index],
          child: PlatformBrandMark(
            platform: platforms[index],
            size: 30,
            flat: true,
          ),
        ),
      ),
    );
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
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0D7D4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB33A3A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
