part of '../../main.dart';

class _DetailWidth extends StatelessWidget {
  const _DetailWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: child,
      ),
    );
  }
}

/// The cover photo filling the top of the detail page.
class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.url,
    required this.item,
    required this.onError,
  });

  final String url;
  final LinkItem item;
  final VoidCallback onError;

  @override
  Widget build(BuildContext context) {
    final style = platformStyle(item.platform);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          cacheWidth: 1400,
          frameBuilder: (context, child, frame, _) => AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 260),
            child: child,
          ),
          errorBuilder: (_, _, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onError());
            return ColoredBox(color: style.softColor);
          },
        ),
        // Keeps the floating buttons legible over bright photos.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0, -0.4),
              colors: [Color(0x40000000), Color(0x00000000)],
            ),
          ),
        ),
        if (_isVideoItem(item))
          const Align(alignment: Alignment(0, -0.1), child: _PlayBadge()),
      ],
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.controller,
    required this.item,
    required this.onImage,
  });

  final ShareController controller;
  final LinkItem item;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final glyph = onImage ? Colors.white : _ink;
    return Row(
      children: [
        GlassCircleButton(
          tooltip: '返回',
          icon: Icons.arrow_back_ios_new_rounded,
          onImage: onImage,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        SizedBox(
          height: 44,
          child: LiquidGlass(
            radius: 22,
            blur: 20,
            opacity: onImage ? 0.26 : 0.66,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '刷新原文',
                  onPressed: () => controller.refreshContent(item, force: true),
                  icon: Icon(Icons.refresh_rounded, color: glyph, size: 21),
                ),
                Builder(
                  builder: (anchor) => IconButton(
                    tooltip: '更多操作',
                    icon: Icon(Icons.more_horiz_rounded, color: glyph),
                    onPressed: () async {
                      final archived = item.status == 'archived';
                      final value = await showGlassMenu<String>(
                        anchorContext: anchor,
                        items: [
                          const GlassMenuItem(
                            value: 'edit',
                            label: '编辑收藏夹与关键词',
                            icon: Icons.edit_outlined,
                          ),
                          GlassMenuItem(
                            value: archived ? 'active' : 'archived',
                            label: archived ? '移回资料库' : '归档',
                            icon: archived
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                          ),
                          const GlassMenuItem(
                            value: 'reanalyze',
                            label: '重新生成 AI 分析',
                            icon: Icons.auto_awesome_outlined,
                          ),
                          const GlassMenuItem(
                            value: 'delete',
                            label: '删除',
                            icon: Icons.delete_outline_rounded,
                            destructive: true,
                            groupStart: true,
                          ),
                        ],
                      );
                      if (value != null && context.mounted) {
                        await _handleMenu(context, value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleMenu(BuildContext context, String value) async {
    if (value == 'edit') {
      await showEditItemSheet(context, controller, item);
    } else if (value == 'delete') {
      if (!await _confirmDeleteItem(context, item) || !context.mounted) {
        return;
      }
      await controller.deleteItem(item);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } else if (value == 'reanalyze') {
      await controller.reanalyze(item);
    } else {
      await controller.updateStatus(item, value);
    }
  }
}

/// The glass sheet that carries everything below the cover.
class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.controller,
    required this.item,
    required this.raised,
  });

  final ShareController controller;
  final LinkItem item;

  /// 0 resting under the cover, 1 pulled up to the top. Only the glass
  /// backing widens with it; the content keeps a fixed width so the text
  /// never re-wraps while the sheet is dragged.
  final ValueNotifier<double> raised;

  @override
  Widget build(BuildContext context) {
    final entities = _visibleEntities(item);
    return Stack(
      children: [
        Positioned.fill(
          child: ValueListenableBuilder<double>(
            valueListenable: raised,
            builder: (context, value, glass) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 8 * (1 - value)),
              child: glass,
            ),
            // The sheet can be thousands of pixels tall; a live backdrop blur
            // over it was re-rendered every frame of scrolling and transitions.
            child: const LiquidGlass(
              radius: 36,
              blur: 0,
              opacity: 0.92,
              child: SizedBox.expand(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 10, 26, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _ink.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _DetailByline(item: item),
              const SizedBox(height: 12),
              SelectableText(
                item.title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              _SummaryCard(item: item),
              if (item.keywords.isNotEmpty || entities.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final keyword in item.keywords)
                      _DetailTag(label: keyword),
                    for (final entity in entities)
                      _DetailTag(label: entity, entity: true),
                    _DetailTagButton(
                      onTap: () => showEditItemSheet(context, controller, item),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 26),
              const _SheetHeading('正文'),
              const SizedBox(height: 12),
              OriginalContentView(
                item: item,
                backendUrl: controller.api.baseUrl,
              ),
              if (item.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 28),
                const _SheetHeading('我的备注'),
                const SizedBox(height: 8),
                Text(
                  item.notes,
                  style: const TextStyle(color: _mutedInk, height: 1.5),
                ),
              ],
              const SizedBox(height: 28),
              const _SheetHeading('来源'),
              const SizedBox(height: 10),
              _SourceLinks(item: item),
              const SizedBox(height: 18),
              SourceSnapshotView(item: item),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailByline extends StatelessWidget {
  const _DetailByline({required this.item});

  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    final style = platformStyle(item.platform);
    final author = (item.author ?? '').trim();
    final date = item.publishedAt ?? item.createdAt;
    final chars = item.contentOmitted ? 0 : _originalTextFor(item).length;
    final meta = [
      style.label,
      '${date.month}月${date.day}日',
      if (chars > 0) '$chars 字',
    ].join(' · ');
    return Row(
      children: [
        if (author.isEmpty)
          PlatformBrandMark(platform: item.platform, size: 34)
        else
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.softColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              author.characters.first.toUpperCase(),
              style: TextStyle(
                color: style.color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.isEmpty ? style.label : author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                meta,
                style: const TextStyle(color: _mutedInk, fontSize: 12),
              ),
            ],
          ),
        ),
        if (item.category.trim().isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0A4FA8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: _accent),
              SizedBox(width: 6),
              Text(
                'AI 摘要',
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (item.analysisPending)
            const Text(
              'AI 分析中…',
              style: TextStyle(color: _mutedInk, fontSize: 14),
            )
          else
            SelectableText(
              item.summary,
              style: const TextStyle(
                color: Color(0xFF1E2622),
                fontSize: 14.5,
                height: 1.55,
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  const _DetailTag({required this.label, this.entity = false});

  final String label;
  final bool entity;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: entity
            ? _ink.withValues(alpha: 0.05)
            : _accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: entity ? const Color(0xFF26302B) : const Color(0xFF0A4FA8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailTagButton extends StatelessWidget {
  const _DetailTagButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '编辑关键词',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.edit_outlined, size: 13, color: _mutedInk),
              SizedBox(width: 3),
              Text('编辑', style: TextStyle(color: _mutedInk, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 阅读 (this page) / 原网页 / 存档 as one segmented control.
/// Ways to leave the reader for the source itself. Each row opens its own
/// page, so they are drawn as navigation rows rather than as tabs.
class _SourceLinks extends StatelessWidget {
  const _SourceLinks({required this.item});

  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.finalUrl.trim().isNotEmpty
        ? item.finalUrl
        : item.sourceUrl;
    final host = Uri.tryParse(url)?.host ?? '';
    final archive = item.archive;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line, width: 0.6),
      ),
      child: Column(
        children: [
          _SourceLinkRow(
            leading: PlatformBrandMark(
              platform: item.platform,
              size: 30,
              flat: true,
            ),
            title: '原网页',
            subtitle: host.isEmpty ? platformStyle(item.platform).label : host,
            trailing: Icons.north_east_rounded,
            onTap: () => openSourceWebPage(context, item),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, thickness: 0.6, color: _line),
          ),
          _SourceLinkRow(
            leading: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _accentSoft,
                borderRadius: BorderRadius.circular(8.4),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: _accent,
              ),
            ),
            title: '存档快照',
            subtitle: archive == null
                ? '尚未存档，可生成整页截图'
                : '保存于 ${DateFormat('M月d日 HH:mm').format(archive.capturedAt)}',
            trailing: Icons.chevron_right_rounded,
            onTap: () => openArchiveSnapshot(context, item),
          ),
        ],
      ),
    );
  }
}

class _SourceLinkRow extends StatelessWidget {
  const _SourceLinkRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title，$subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _mutedInk, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(trailing, size: 20, color: _mutedInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeading extends StatelessWidget {
  const _SheetHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({required this.controller, required this.item});

  final ShareController controller;
  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    final favorite = item.status == 'favorite';
    return SizedBox(
      height: 56,
      child: LiquidGlass(
        radius: 28,
        blur: 30,
        opacity: 0.94,
        padding: const EdgeInsets.all(5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '编辑收藏夹与关键词',
              onPressed: () => showEditItemSheet(context, controller, item),
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF26302B)),
            ),
            IconButton(
              tooltip: favorite ? '取消重要' : '标为重要',
              onPressed: () => controller.updateStatus(
                item,
                favorite ? 'active' : 'favorite',
              ),
              icon: Icon(
                favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: favorite
                    ? const Color(0xFFE0A100)
                    : const Color(0xFF26302B),
              ),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: () => openSourceWebPage(context, item),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.north_east_rounded, size: 17),
              label: const Text('打开原文'),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _visibleEntities(LinkItem item) {
  final reserved = {
    item.platform.trim().toLowerCase(),
    item.category.trim().toLowerCase(),
    for (final keyword in item.keywords) keyword.trim().toLowerCase(),
  };
  final visible = <String>[];
  for (final entity in item.entities) {
    final value = entity.trim();
    if (value.isEmpty || reserved.contains(value.toLowerCase())) {
      continue;
    }
    if (!visible.any(
      (existing) => existing.toLowerCase() == value.toLowerCase(),
    )) {
      visible.add(value);
    }
  }
  return visible;
}

String _originalTextFor(LinkItem item) {
  final original = item.originalText.trim();
  if (original.isNotEmpty) {
    return original;
  }
  final content = item.contentText.trim();
  if (content.isNotEmpty) {
    return content;
  }
  return item.description;
}

Future<bool> _confirmDeleteItem(BuildContext context, LinkItem item) async {
  final title = item.title.trim().isEmpty ? item.sourceUrl : item.title.trim();
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('删除这条内容？'),
          content: Text('删除后会从资料库移除：$title'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        ),
      ) ??
      false;
}
