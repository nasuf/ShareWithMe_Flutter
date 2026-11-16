part of '../../main.dart';

bool _isVideoItem(LinkItem item) {
  final type = item.contentType.toLowerCase();
  return type.contains('video') ||
      type.contains('视频') ||
      const {'哔哩哔哩', 'YouTube', '抖音', 'TikTok', '快手'}.contains(item.platform);
}

/// One row of the library's grouped glass list. Rows are drawn without a
/// backdrop blur (the ambient backdrop behind them is already soft), so long
/// lists scroll smoothly.
class LibraryRow extends StatefulWidget {
  const LibraryRow({
    super.key,
    required this.item,
    required this.controller,
    required this.first,
    required this.last,
  });

  final LinkItem item;
  final ShareController controller;
  final bool first;
  final bool last;

  @override
  State<LibraryRow> createState() => _LibraryRowState();
}

class _LibraryRowState extends State<LibraryRow> {
  @override
  void initState() {
    super.initState();
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant LibraryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.extraction.refreshAfter !=
            widget.item.extraction.refreshAfter) {
      _scheduleRefresh();
    }
  }

  void _scheduleRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.controller.ensureFresh(widget.item));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final style = platformStyle(item.platform);
    const corner = Radius.circular(28);
    final shape = BorderRadius.vertical(
      top: widget.first ? corner : Radius.zero,
      bottom: widget.last ? corner : Radius.zero,
    );
    final meta = [
      style.label,
      if (item.category.trim().isNotEmpty) item.category.trim(),
    ].join(' · ');
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: '${style.label}，${item.title}',
        excludeSemantics: true,
        child: Material(
          color: context.tokens.glassFill.withValues(
            alpha: context.tokens.glassFillAlpha,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: shape,
            side: BorderSide(color: context.tokens.glassRim, width: 0.6),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openDetail(context, widget.controller, item),
            onLongPress: () =>
                _showItemActions(context, widget.controller, item),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                widget.first ? 14 : 10,
                12,
                widget.last ? 14 : 10,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RowThumbnail(item: item, controller: widget.controller),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.tokens.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.32,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (item.analysisPending)
                              Row(
                                children: [
                                  SizedBox.square(
                                    dimension: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: context.tokens.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'AI 分析中…',
                                    style: TextStyle(
                                      color: context.tokens.mutedInk,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  PlatformBrandMark(
                                    platform: item.platform,
                                    size: 16,
                                    flat: true,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      meta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.tokens.mutedInk,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (item.status == 'favorite') ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Color(0xFFE0A100),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: context.tokens.mutedInk.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  if (!widget.last)
                    Padding(
                      padding: const EdgeInsets.only(left: 68, top: 10),
                      child: Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: context.tokens.line,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowThumbnail extends StatelessWidget {
  const _RowThumbnail({required this.item, required this.controller});

  final LinkItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final url = _coverUrl(controller, item);
    final style = platformStyle(item.platform);
    final fallback = ColoredBox(
      color: style.softColor,
      child: Center(
        child: PlatformBrandMark(platform: item.platform, size: 26),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(
        dimension: 56,
        child: url.isEmpty
            ? fallback
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                    errorBuilder: (_, _, _) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => controller.refreshCover(item, force: true),
                      );
                      return fallback;
                    },
                  ),
                  if (_isVideoItem(item))
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 22,
                        shadows: [
                          Shadow(color: Color(0x66000000), blurRadius: 6),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

Future<void> _showItemActions(
  BuildContext context,
  ShareController controller,
  LinkItem item,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: context.tokens.ink.withValues(alpha: 0.18),
    builder: (sheetContext) => SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: LiquidGlass(
        radius: 28,
        blur: 30,
        opacity: 0.86,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sheetContext.tokens.mutedInk,
                  fontSize: 13,
                ),
              ),
            ),
            for (final option in [
              ('edit', Icons.edit_outlined, '编辑收藏夹与关键词'),
              (
                item.status == 'favorite' ? 'active' : 'favorite',
                Icons.star_outline_rounded,
                item.status == 'favorite' ? '取消重要' : '标为重要',
              ),
              (
                item.status == 'archived' ? 'active' : 'archived',
                Icons.archive_outlined,
                item.status == 'archived' ? '移回资料库' : '归档',
              ),
              ('reanalyze', Icons.auto_awesome_outlined, '重新生成 AI 分析'),
            ])
              ListTile(
                leading: Icon(option.$2, color: sheetContext.tokens.ink),
                title: Text(
                  option.$3,
                  style: TextStyle(color: sheetContext.tokens.ink),
                ),
                onTap: () => Navigator.of(sheetContext).pop(option.$1),
              ),
          ],
        ),
      ),
    ),
  );
  if (action == null || !context.mounted) {
    return;
  }
  if (action == 'edit') {
    await showEditItemSheet(context, controller, item);
  } else if (action == 'reanalyze') {
    await controller.reanalyze(item);
  } else {
    await controller.updateStatus(item, action);
  }
}
