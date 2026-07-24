part of '../../main.dart';

class _ClipboardImportBanner extends StatefulWidget {
  const _ClipboardImportBanner({required this.controller});

  final ShareController controller;

  @override
  State<_ClipboardImportBanner> createState() => _ClipboardImportBannerState();
}

class _ClipboardImportBannerState extends State<_ClipboardImportBanner>
    with WidgetsBindingObserver {
  String? clipboardUrl;
  bool dismissed = false;
  bool inspectionInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_inspectClipboard());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_inspectClipboard());
    }
  }

  Future<void> _inspectClipboard() async {
    if (inspectionInFlight || dismissed || clipboardUrl != null) {
      return;
    }
    inspectionInFlight = true;
    try {
      if (!await Clipboard.hasStrings()) {
        return;
      }
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final url = _firstUrlFromText(data?.text ?? '');
      if (mounted && !dismissed && url != null) {
        setState(() => clipboardUrl = url);
      }
    } on PlatformException catch (exception) {
      debugPrint('Clipboard is temporarily unavailable: $exception');
    } finally {
      inspectionInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = clipboardUrl;
    if (url == null || dismissed) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4F8).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          children: [
            const Icon(Icons.content_paste_search, size: 20, color: _accent),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '剪切板发现链接',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.controller.analyzing
                  ? null
                  : () async {
                      await widget.controller.analyzeSharedText(
                        text: url,
                        sourceApp: 'clipboard',
                      );
                      if (mounted) {
                        setState(() => dismissed = true);
                      }
                    },
              child: Text(widget.controller.analyzing ? '解析中' : '解析'),
            ),
            IconButton(
              tooltip: '忽略',
              onPressed: () => setState(() => dismissed = true),
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryFilterSheet extends StatelessWidget {
  const _LibraryFilterSheet({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.96)),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
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
                            '筛选资料',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (controller.statusFilter != 'active') {
                              controller.setStatusFilter('active');
                            }
                            if (controller.sortMode != 'newest') {
                              controller.setSortMode('newest');
                            }
                            if (controller.category.isNotEmpty) {
                              controller.setCategory(controller.category);
                            }
                          },
                          child: const Text('恢复默认'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _FilterHeading('状态'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final value in const [
                          ('active', '资料库', Icons.menu_book_outlined),
                          ('favorite', '重要', Icons.star_outline),
                          ('archived', '归档', Icons.archive_outlined),
                          ('', '全部', Icons.all_inbox_outlined),
                        ])
                          ChoiceChip(
                            selected: controller.statusFilter == value.$1,
                            showCheckmark: false,
                            avatar: Icon(value.$3, size: 17, color: _accent),
                            label: Text(value.$2),
                            labelStyle: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) =>
                                controller.setStatusFilter(value.$1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _FilterHeading('排序'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final value in const [
                          ('newest', '最新', Icons.schedule),
                          ('oldest', '最早', Icons.history),
                          ('importance', '重要度', Icons.priority_high),
                        ])
                          ChoiceChip(
                            selected: controller.sortMode == value.$1,
                            showCheckmark: false,
                            avatar: Icon(value.$3, size: 17, color: _accent),
                            label: Text(value.$2),
                            labelStyle: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) => controller.setSortMode(value.$1),
                          ),
                      ],
                    ),
                    if ((stats?.categories ?? []).isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const _FilterHeading('主题'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final bucket in stats!.categories.take(10))
                            FilterChip(
                              selected: controller.category == bucket.label,
                              label: Text('${bucket.label} ${bucket.count}'),
                              showCheckmark: false,
                              labelStyle: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (_) =>
                                  controller.setCategory(bucket.label),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('完成'),
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
}

class _FilterHeading extends StatelessWidget {
  const _FilterHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: _ink,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

String? _firstUrlFromText(String text) {
  return RegExp(r'https?://[^\s，。、《》<>"]+').firstMatch(text)?.group(0);
}
