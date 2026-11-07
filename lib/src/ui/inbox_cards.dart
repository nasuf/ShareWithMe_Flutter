part of '../../main.dart';

class LinkCard extends StatefulWidget {
  const LinkCard({
    super.key,
    required this.item,
    required this.controller,
    this.lastInGroup = false,
  });

  final LinkItem item;
  final ShareController controller;
  final bool lastInGroup;

  @override
  State<LinkCard> createState() => _LinkCardState();
}

class _LinkCardState extends State<LinkCard> {
  @override
  void initState() {
    super.initState();
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant LinkCard oldWidget) {
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

  void _openDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareScope(
          controller: widget.controller,
          child: DetailPage(itemId: widget.item.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final style = platformStyle(item.platform);
    final imageUrl = resolveBackendMediaUrl(
      widget.controller.api.baseUrl,
      item.imageUrl?.trim() ?? '',
    );
    final keywords = item.keywords
        .where(
          (keyword) => keyword.trim().isNotEmpty && keyword != item.category,
        )
        .take(2)
        .toList(growable: false);
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: '${item.platform}，${item.title}',
        child: _InsetGalleryCardFrame(
          onTap: _openDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: CardCoverMedia(
                  imageUrl: imageUrl,
                  item: item,
                  style: style,
                  onError: () =>
                      widget.controller.refreshCover(item, force: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: _ink,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.25,
                                ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        _CardMoreMenu(
                          item: item,
                          controller: widget.controller,
                        ),
                      ],
                    ),
                    if (item.analysisPending) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SizedBox(
                            width: 11,
                            height: 11,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              valueColor: AlwaysStoppedAnimation<Color>(_mint),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI 分析中…',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: _mutedInk, fontSize: 12),
                          ),
                        ],
                      ),
                    ] else if (item.summary.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _mutedInk,
                          fontSize: 13,
                          height: 1.36,
                        ),
                      ),
                    ],
                    if (keywords.isNotEmpty || item.category.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (item.category.trim().isNotEmpty)
                            _CardKeyword(label: item.category),
                          for (final keyword in keywords)
                            _CardKeyword(label: keyword),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: _line.withValues(alpha: 0.88),
                    ),
                    const SizedBox(height: 10),
                    _CardFooter(item: item, style: style),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsetGalleryCardFrame extends StatelessWidget {
  const _InsetGalleryCardFrame({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: shape,
        border: Border.all(color: const Color(0xFFDCE3E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF263445).withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: -14,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: const Color(0xFF263445).withValues(alpha: 0.07),
            blurRadius: 8,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.white.withValues(alpha: 0.62),
            child: InkWell(onTap: onTap, child: child),
          ),
        ),
      ),
    );
  }
}

class _CardKeyword extends StatelessWidget {
  const _CardKeyword({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _mutedInk,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.item, required this.style});

  final LinkItem item;
  final PlatformStyle style;

  @override
  Widget build(BuildContext context) {
    final author = (item.author ?? '').trim();
    final authorAndDate =
        '${author.isEmpty ? style.label : author}  ·  '
        '${DateFormat('MM-dd HH:mm').format(item.createdAt)}';
    return Row(
      children: [
        PlatformBrandMark(platform: item.platform, size: 20, flat: true),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            authorAndDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _mutedInk,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.sync_rounded, size: 15, color: _mutedInk),
        const SizedBox(width: 4),
        Text(
          _freshnessLabel(item),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: _mutedInk, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _CardMoreMenu extends StatelessWidget {
  const _CardMoreMenu({required this.item, required this.controller});

  final LinkItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '更多操作',
      padding: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.more_horiz_rounded, color: _mutedInk, size: 20),
      onSelected: (value) async {
        if (value == 'edit') {
          await showEditItemSheet(context, controller, item);
        } else if (value == 'reanalyze') {
          await controller.reanalyze(item);
        } else {
          await controller.updateStatus(item, value);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('编辑收藏夹与关键词')),
        PopupMenuItem(
          value: 'favorite',
          child: Text(item.status == 'favorite' ? '取消重要' : '标为重要'),
        ),
        PopupMenuItem(
          value: item.status == 'archived' ? 'active' : 'archived',
          child: Text(item.status == 'archived' ? '移回资料库' : '归档'),
        ),
        const PopupMenuItem(value: 'reanalyze', child: Text('重新生成 AI 分析')),
      ],
    );
  }
}

String _freshnessLabel(LinkItem item) {
  final checkedAt = item.extraction.fetchedAt ?? item.coverCheckedAt;
  if (checkedAt == null) {
    return '等待更新';
  }
  final elapsed = DateTime.now().difference(checkedAt);
  if (elapsed.isNegative || elapsed.inMinutes < 60) {
    return '刚刚更新';
  }
  if (elapsed.inHours < 24) {
    return '${elapsed.inHours} 小时前更新';
  }
  if (elapsed.inDays < 30) {
    return '${elapsed.inDays} 天前更新';
  }
  return DateFormat('MM-dd').format(checkedAt);
}
