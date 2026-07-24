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

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.controller, required this.item});

  final ShareController controller;
  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassIconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icons.arrow_back_rounded,
          size: 46,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '详情',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GlassIconButton(
          tooltip: '刷新原文',
          onPressed: () => controller.refreshContent(item, force: true),
          icon: Icons.sync_rounded,
          size: 46,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: '更多操作',
          color: Colors.white.withValues(alpha: 0.97),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(46),
            backgroundColor: Colors.white.withValues(alpha: 0.58),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.94)),
          ),
          icon: const Icon(Icons.more_horiz_rounded, color: _ink),
          onSelected: (value) async {
            if (value == 'edit') {
              await showEditItemSheet(context, controller, item);
            } else if (value == 'delete') {
              if (!await _confirmDeleteItem(context, item) ||
                  !context.mounted) {
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
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('编辑分类与关键词')),
            PopupMenuItem(
              value: 'favorite',
              child: Text(item.status == 'favorite' ? '取消重要' : '标为重要'),
            ),
            PopupMenuItem(
              value: item.status == 'archived' ? 'active' : 'archived',
              child: Text(item.status == 'archived' ? '移回资料库' : '归档'),
            ),
            const PopupMenuItem(value: 'reanalyze', child: Text('重新生成 AI 分析')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ],
    );
  }
}

class _DetailArticle extends StatelessWidget {
  const _DetailArticle({required this.controller, required this.item});

  final ShareController controller;
  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    final style = platformStyle(item.platform);
    final imageUrl = resolveBackendMediaUrl(
      controller.api.baseUrl,
      item.imageUrl?.trim() ?? '',
    );
    final visibleEntities = _visibleEntities(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassPanel(
          padding: EdgeInsets.zero,
          radius: 24,
          color: Colors.white.withValues(alpha: 0.63),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                _DetailCover(
                  imageUrl: imageUrl,
                  item: item,
                  style: style,
                  onError: () => controller.refreshCover(item, force: true),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 17, 18, 19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PlatformBrandMark(
                          platform: item.platform,
                          size: 28,
                          flat: true,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          style.label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: style.color,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (item.category.trim().isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '·',
                              style: TextStyle(color: _mutedInk),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: _mutedInk),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        _ImportancePill(score: item.importanceScore),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: _ink,
                            fontWeight: FontWeight.w900,
                            height: 1.24,
                          ),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        if ((item.author ?? '').trim().isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              item.author!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: _ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 9),
                        ],
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: _mutedInk),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: '摘要',
          child: Text(
            item.summary,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: _ink, height: 1.6),
          ),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: '关键词',
          trailing: TextButton.icon(
            onPressed: () => showEditItemSheet(context, controller, item),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('编辑'),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final keyword in item.keywords)
                SoftTag(label: keyword, icon: Icons.tag, color: style.color),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (visibleEntities.isNotEmpty) ...[
          _DetailSection(
            title: '提到的对象',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entity in visibleEntities)
                  SoftTag(
                    label: entity,
                    icon: Icons.hub_outlined,
                    color: _accent,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        _DetailSection(
          title: '原文',
          child: OriginalContentView(
            item: item,
            backendUrl: controller.api.baseUrl,
          ),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: '来源快照',
          child: SourceSnapshotView(item: item),
        ),
        if (item.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _DetailSection(
            title: '分析备注',
            child: Text(
              item.notes,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _mutedInk, height: 1.5),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailCover extends StatelessWidget {
  const _DetailCover({
    required this.imageUrl,
    required this.item,
    required this.style,
    required this.onError,
  });

  final String imageUrl;
  final LinkItem item;
  final PlatformStyle style;
  final VoidCallback onError;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) => onError());
                return ColoredBox(
                  color: style.softColor,
                  child: Icon(style.icon, size: 38, color: style.color),
                );
              },
            ),
            if (_isVideoItem(item))
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.66),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 19),
      radius: 22,
      color: Colors.white.withValues(alpha: 0.61),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({required this.item});

  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.96)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(item.finalUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new, size: 19),
              label: const Text('打开原链接'),
            ),
          ),
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
