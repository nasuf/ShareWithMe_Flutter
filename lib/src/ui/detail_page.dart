part of '../../main.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool loadingMissingItem = false;
  bool requestedMissingItem = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ShareScope.of(context);
    if (!requestedMissingItem && controller.itemById(widget.itemId) == null) {
      requestedMissingItem = true;
      loadingMissingItem = true;
      unawaited(_loadMissingItem(controller));
    }
  }

  Future<void> _loadMissingItem(ShareController controller) async {
    await controller.loadItem(widget.itemId);
    if (mounted) {
      setState(() {
        loadingMissingItem = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShareScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final item = controller.itemById(widget.itemId);
        if (item == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: GlassBackground(
              child: Center(
                child: loadingMissingItem
                    ? const CircularProgressIndicator()
                    : const Text('内容已不存在'),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GlassBackground(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  _DetailTopBar(controller: controller, item: item),
                  const SizedBox(height: 16),
                  _DetailHero(controller: controller, item: item),
                  const SizedBox(height: 12),
                  _Section(
                    title: '摘要',
                    icon: Icons.notes,
                    child: Text(
                      item.summary,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.42),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: '关键词',
                    icon: Icons.sell_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final keyword in item.keywords)
                              SoftTag(
                                label: keyword,
                                icon: Icons.sell_outlined,
                                color: platformStyle(item.platform).color,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              showEditItemSheet(context, controller, item),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('编辑关键词'),
                        ),
                      ],
                    ),
                  ),
                  if (item.entities.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Section(
                      title: '提到的对象',
                      icon: Icons.hub_outlined,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entity in item.entities)
                            SoftTag(
                              label: entity,
                              icon: Icons.hub_outlined,
                              color: _mint,
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _Section(
                    title: '原文',
                    icon: Icons.subject,
                    child: SelectableText(
                      _originalTextFor(item),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: '分析备注',
                    icon: Icons.info_outline,
                    child: Text(item.notes),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(item.finalUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('打开原链接'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
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

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.controller, required this.item});

  final ShareController controller;
  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundTopButton(
          tooltip: '返回',
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '卡片详情',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _RoundTopButton(
          tooltip: '编辑整理信息',
          icon: Icons.edit_outlined,
          onTap: () => showEditItemSheet(context, controller, item),
        ),
        const SizedBox(width: 8),
        _RoundTopButton(
          tooltip: '重新分析',
          icon: Icons.auto_fix_high,
          onTap: controller.analyzing ? null : () => controller.reanalyze(item),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          onSelected: (value) async {
            if (value == 'delete') {
              final confirmed = await _confirmDeleteItem(context, item);
              if (!confirmed || !context.mounted) {
                return;
              }
              await controller.deleteItem(item);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            } else {
              await controller.updateStatus(item, value);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'active', child: Text('移回资料库')),
            PopupMenuItem(
              value: 'favorite',
              child: Text(item.status == 'favorite' ? '已标为重要' : '标为重要'),
            ),
            PopupMenuItem(
              value: 'archived',
              child: Text(item.status == 'archived' ? '已归档' : '归档'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ],
    );
  }
}

class _RoundTopButton extends StatelessWidget {
  const _RoundTopButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
          ),
          child: Icon(icon, color: onTap == null ? _mutedInk : _ink),
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.controller, required this.item});

  final ShareController controller;
  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    final style = platformStyle(item.platform);
    final imageUrl = resolveBackendMediaUrl(
      controller.api.baseUrl,
      item.imageUrl?.trim() ?? '',
    );
    final isVideo = _isVideoItem(item);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: _CardAtmosphere(style: style, hasImage: imageUrl.isNotEmpty),
          ),
        ),
        GlassPanel(
          padding: EdgeInsets.zero,
          color: _creamSurface.withValues(alpha: 0.9),
          borderColor: Colors.white.withValues(alpha: 0.74),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned.fill(child: _PlatformGlassTint(style: style)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _PlatformIcon(platform: item.platform),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.platform,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: style.color,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
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
                              height: 1.08,
                            ),
                      ),
                      if ((item.author ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.author!.trim(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: _mutedInk),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SoftTag(
                            label: item.category,
                            icon: Icons.folder,
                            color: style.color,
                          ),
                          SoftTag(
                            label: item.contentType,
                            icon: _contentIcon(item),
                            color: _mutedInk,
                          ),
                          SoftTag(
                            label: DateFormat(
                              'MM-dd HH:mm',
                            ).format(item.createdAt),
                            icon: Icons.schedule,
                            color: _mutedInk,
                          ),
                        ],
                      ),
                      if (imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _BreathingImage(
                                  imageUrl,
                                  onError: () => controller.refreshCover(
                                    item,
                                    force: true,
                                  ),
                                  errorBuilder: (_, _, _) => ColoredBox(
                                    color: style.softColor,
                                    child: Icon(style.icon, color: style.color),
                                  ),
                                ),
                                ColoredBox(
                                  color: style.softColor.withValues(
                                    alpha: 0.06,
                                  ),
                                ),
                                if (isVideo)
                                  Center(
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: _ink.withValues(alpha: 0.74),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.78,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned.fill(
                  child: _GlassSpecularOverlay(style: style, radius: 26),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> _confirmDeleteItem(BuildContext context, LinkItem item) async {
  final title = item.title.trim().isEmpty ? item.sourceUrl : item.title.trim();
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('删除这条内容？'),
          content: Text('删除后会从整理库移除：$title'),
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
