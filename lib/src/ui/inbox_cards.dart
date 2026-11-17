part of '../../main.dart';

// ─── 卡片类型分发 ────────────────────────────────────────────────────────────

enum _CardType { video, article, social }

bool _isVideoItem(LinkItem item) {
  final type = item.contentType.toLowerCase();
  return type.contains('video') ||
      type.contains('视频') ||
      const {'哔哩哔哩', 'YouTube', '抖音', 'TikTok', '快手'}.contains(item.platform);
}

bool _isSocialItem(LinkItem item) =>
    const {'小红书', '微博', 'Instagram', 'X', 'Twitter', '抖音'}.contains(
      item.platform,
    );

_CardType _cardTypeFor(LinkItem item) {
  if (_isVideoItem(item)) return _CardType.video;
  if (_isSocialItem(item)) return _CardType.social;
  return _CardType.article;
}

// ─── 路由入口：根据内容类型分发到对应卡片 ─────────────────────────────────────

class LibraryCard extends StatelessWidget {
  const LibraryCard({
    super.key,
    required this.item,
    required this.controller,
  });

  final LinkItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return switch (_cardTypeFor(item)) {
      _CardType.video => _VideoCard(item: item, controller: controller),
      _CardType.article => _ArticleCard(item: item, controller: controller),
      _CardType.social => _SocialCard(item: item, controller: controller),
    };
  }
}

// ─── 视频大图卡 ───────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.item, required this.controller});

  final LinkItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final url = _coverUrl(controller, item);
    final style = platformStyle(item.platform);
    final meta = [
      style.label,
      if (item.category.trim().isNotEmpty) item.category.trim(),
    ].join(' · ');

    return GestureDetector(
      onTap: () => _openDetail(context, controller, item),
      onLongPress: () => _showItemActions(context, controller, item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: url.isEmpty
                  ? ColoredBox(
                      color: style.softColor,
                      child: Center(
                        child: PlatformBrandMark(
                          platform: item.platform,
                          size: 48,
                        ),
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: style.softColor,
                        child: Center(
                          child: PlatformBrandMark(
                            platform: item.platform,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
            ),
            // 底部渐变遮罩 + 文字
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC000000)],
                    stops: [0.0, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          PlatformBrandMark(
                            platform: item.platform,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          // 播放图标
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 收藏星标
            if (item.status == 'favorite')
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFE0A100),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 文章宽行卡 ───────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.item, required this.controller});

  final LinkItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = _coverUrl(controller, item);
    final style = platformStyle(item.platform);
    final hasCover = url.isNotEmpty;
    final meta = [
      style.label,
      if (item.category.trim().isNotEmpty) item.category.trim(),
    ].join(' · ');

    return GestureDetector(
      onTap: () => _openDetail(context, controller, item),
      onLongPress: () => _showItemActions(context, controller, item),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.glassFill.withValues(alpha: t.glassFillAlpha),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.glassRim, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 来源行
                    Row(
                      children: [
                        PlatformBrandMark(
                          platform: item.platform,
                          size: 15,
                          flat: true,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.mutedInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.status == 'favorite') ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFE0A100),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 标题
                    Text(
                      item.title,
                      maxLines: hasCover ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        letterSpacing: -0.3,
                      ),
                    ),
                    // 摘要（无封面时显示）
                    if (!hasCover && item.summary.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.summary.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.mutedInk,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (item.analysisPending) ...[
                      const SizedBox(height: 8),
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
                            style: TextStyle(color: t.mutedInk, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (hasCover) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: style.softColor,
                        child: Center(
                          child: PlatformBrandMark(
                            platform: item.platform,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 社交紧凑卡（半宽，两列并排）─────────────────────────────────────────────

class _SocialCard extends StatelessWidget {
  const _SocialCard({required this.item, required this.controller});

  final LinkItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = _coverUrl(controller, item);
    final style = platformStyle(item.platform);
    final hasCover = url.isNotEmpty;

    return GestureDetector(
      onTap: () => _openDetail(context, controller, item),
      onLongPress: () => _showItemActions(context, controller, item),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.glassFill.withValues(alpha: t.glassFillAlpha),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.glassRim, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 封面图（3:4 比例）
            if (hasCover)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    cacheWidth: 400,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: style.softColor,
                      child: Center(
                        child: PlatformBrandMark(
                          platform: item.platform,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: ColoredBox(
                    color: style.softColor,
                    child: Center(
                      child: PlatformBrandMark(
                        platform: item.platform,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            // 文字区域
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PlatformBrandMark(
                        platform: item.platform,
                        size: 13,
                        flat: true,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          style.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.mutedInk,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.status == 'favorite') ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Color(0xFFE0A100),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
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
