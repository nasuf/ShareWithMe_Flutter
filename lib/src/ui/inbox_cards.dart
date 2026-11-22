part of '../../main.dart';

bool _isVideoItem(LinkItem item) {
  final type = item.contentType.toLowerCase();
  return type.contains('video') ||
      type.contains('视频') ||
      const {'哔哩哔哩', 'YouTube', '抖音', 'TikTok', '快手'}.contains(item.platform);
}

/// 封面宽高比（宽/高）。优先用原图尺寸，否则按类型和 id 给出有差异的比例，
/// 让两列卡片高低错落。
double _coverAspect(LinkItem item) {
  final img = item.media
      .where((m) => m.kind == 'image' && (m.width ?? 0) > 0 && (m.height ?? 0) > 0)
      .firstOrNull;
  if (img != null) {
    return (img.width! / img.height!).clamp(0.72, 1.4).toDouble();
  }
  if (_isVideoItem(item)) return 4 / 3;
  const ratios = <double>[0.75, 0.85, 1.0, 0.8];
  return ratios[item.id.hashCode.abs() % ratios.length];
}

/// 瀑布流中的统一卡片：封面按原比例，下方标题与来源。
class LibraryCard extends StatelessWidget {
  const LibraryCard({super.key, required this.item, required this.controller});

  final LinkItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = t.brightness == Brightness.dark;
    final url = _coverUrl(controller, item);
    final style = platformStyle(item.platform);
    final hasCover = url.isNotEmpty;
    final video = _isVideoItem(item);
    final fallback = ColoredBox(
      color: dark ? style.color.withValues(alpha: 0.18) : style.softColor,
      child: Center(child: PlatformBrandMark(platform: item.platform, size: 36)),
    );
    return GestureDetector(
      onTap: () => _openDetail(context, controller, item),
      onLongPress: () => _showItemActions(context, controller, item),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.glassFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.glassRim, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: hasCover ? _coverAspect(item) : 1.25,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCover)
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      cacheWidth: 500,
                      errorBuilder: (_, _, _) => fallback,
                    )
                  else
                    fallback,
                  if (video)
                    const Positioned(
                      right: 8,
                      bottom: 8,
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 26,
                        shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
                      ),
                    ),
                  if (item.status == 'favorite')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFFFC53D),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (item.analysisPending)
                    Row(
                      children: [
                        SizedBox.square(
                          dimension: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: t.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI 分析中…',
                          style: TextStyle(color: t.mutedInk, fontSize: 11.5),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        PlatformBrandMark(
                          platform: item.platform,
                          size: 14,
                          flat: true,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            style.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: t.mutedInk, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 操作菜单 ─────────────────────────────────────────────────────────────────

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
