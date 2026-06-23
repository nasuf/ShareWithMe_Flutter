part of '../../main.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key, required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        // ignore: deprecated_member_use
        cacheExtent: 520,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverList.list(
              children: [
                _LibraryHeader(controller: controller, stats: stats),
                const SizedBox(height: 14),
                _ClipboardImportCard(controller: controller),
                const SizedBox(height: 12),
                _FilterDock(controller: controller, stats: stats),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (controller.loading)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 112),
              sliver: SliverToBoxAdapter(child: _LoadingList()),
            )
          else if (controller.items.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 112),
              sliver: SliverToBoxAdapter(child: _EmptyState()),
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.crossAxisExtent > 980;
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 112),
                  sliver: twoColumns
                      ? SliverGrid.builder(
                          itemCount: controller.items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.82,
                              ),
                          itemBuilder: (context, index) {
                            return _AnimatedCardEntry(
                              index: index,
                              child: LinkCard(
                                item: controller.items[index],
                                controller: controller,
                              ),
                            );
                          },
                        )
                      : SliverList.builder(
                          itemCount: controller.items.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AnimatedCardEntry(
                                index: index,
                                child: LinkCard(
                                  item: controller.items[index],
                                  controller: controller,
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AnimatedCardEntry extends StatelessWidget {
  const _AnimatedCardEntry({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + (index % 6) * 35),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.controller, required this.stats});

  final ShareController controller;
  final CollectionStats? stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 2, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ShareWithMe',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _mint,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '资料库',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    height: 0.98,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _HeaderStat(
                      icon: Icons.auto_stories_outlined,
                      text: '${stats?.total ?? controller.items.length} 张卡片',
                    ),
                    _HeaderStat(
                      icon: Icons.public,
                      text: '${stats?.platforms.length ?? 0} 个平台',
                    ),
                    _HeaderStat(
                      icon: Icons.sell_outlined,
                      text: '${stats?.keywords.length ?? 0} 个标签',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HeaderActions(controller: controller),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.66)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: _mutedInk),
              const SizedBox(width: 5),
              Text(
                text,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _mutedInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDock extends StatelessWidget {
  const _FilterDock({required this.controller, required this.stats});

  final ShareController controller;
  final CollectionStats? stats;

  @override
  Widget build(BuildContext context) {
    final hasQuickTags =
        ((stats?.categories ?? []).isNotEmpty) ||
        ((stats?.platforms ?? []).isNotEmpty);
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      radius: 30,
      color: Colors.white.withValues(alpha: 0.48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBar(
            elevation: const WidgetStatePropertyAll(0),
            constraints: const BoxConstraints(minHeight: 50),
            backgroundColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: 0.62),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            hintText: '搜索标题、摘要、关键词',
            leading: const Icon(Icons.search),
            onChanged: controller.setQuery,
          ),
          const SizedBox(height: 10),
          _FilterStrip(child: _StatusFilterBar(controller: controller)),
          const SizedBox(height: 7),
          _FilterStrip(child: _SortBar(controller: controller)),
          if (hasQuickTags) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 6),
                  child: Text(
                    '热词',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _mutedInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: _FilterStrip(
                    padding: EdgeInsets.zero,
                    child: _QuickTagRow(controller: controller, stats: stats),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 1),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      physics: const BouncingScrollPhysics(),
      child: child,
    );
  }
}

class _QuickTagRow extends StatelessWidget {
  const _QuickTagRow({required this.controller, required this.stats});

  final ShareController controller;
  final CollectionStats? stats;

  @override
  Widget build(BuildContext context) {
    final tags = <_QuickFilterTag>[
      for (final bucket in (stats?.categories ?? []).take(4))
        _QuickFilterTag(
          label: bucket.label,
          count: bucket.count,
          icon: Icons.folder_outlined,
          selected: controller.category == bucket.label,
          onTap: () => controller.setCategory(bucket.label),
        ),
      for (final bucket in (stats?.platforms ?? []).take(3))
        _QuickFilterTag(
          label: bucket.label,
          count: bucket.count,
          icon: Icons.public,
          platform: bucket.label,
          selected: controller.platform == bucket.label,
          onTap: () => controller.setPlatform(bucket.label),
        ),
    ];
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        for (var i = 0; i < tags.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          tags[i],
        ],
      ],
    );
  }
}

class _QuickFilterTag extends StatelessWidget {
  const _QuickFilterTag({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.platform,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? platform;

  @override
  Widget build(BuildContext context) {
    return _FrostedFilterPill(
      selected: selected,
      icon: icon,
      label: '$label $count',
      onTap: onTap,
      compact: true,
      platform: platform,
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    const sorts = [
      ('newest', '最新', Icons.schedule),
      ('oldest', '最早', Icons.history),
      ('importance', '重要度', Icons.priority_high),
    ];
    return Row(
      children: [
        for (var i = 0; i < sorts.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _FrostedFilterPill(
            selected: controller.sortMode == sorts[i].$1,
            icon: sorts[i].$3,
            label: sorts[i].$2,
            onTap: () => controller.setSortMode(sorts[i].$1),
            compact: true,
          ),
        ],
      ],
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('active', '资料库', Icons.auto_stories_outlined),
      ('favorite', '重要', Icons.star_border),
      ('archived', '归档', Icons.archive_outlined),
      ('', '全部', Icons.all_inbox_outlined),
    ];
    return Row(
      children: [
        for (var i = 0; i < filters.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _FrostedFilterPill(
            selected: controller.statusFilter == filters[i].$1,
            icon: filters[i].$3,
            label: filters[i].$2,
            onTap: () => controller.setStatusFilter(filters[i].$1),
            compact: true,
          ),
        ],
      ],
    );
  }
}

class _FrostedFilterPill extends StatelessWidget {
  const _FrostedFilterPill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
    this.platform,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;
  final String? platform;

  @override
  Widget build(BuildContext context) {
    final style = platform == null ? null : platformStyle(platform!);
    final foreground = selected ? Colors.white : (style?.color ?? _ink);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 13,
          vertical: compact ? 7 : 10,
        ),
        decoration: BoxDecoration(
          gradient: selected && style != null
              ? _brandGradient(platform!, style)
              : null,
          color: selected
              ? (style == null ? _mint.withValues(alpha: 0.96) : null)
              : _creamSurface.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.78),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: (style?.color ?? _warmShadow).withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 18,
                    offset: const Offset(5, 9),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (platform == null)
              Icon(icon, size: 16, color: foreground)
            else
              PlatformBrandMark(
                platform: platform!,
                size: compact ? 19 : 22,
                flat: selected,
              ),
            const SizedBox(width: 7),
            Text(
              label,
              style:
                  (compact
                          ? Theme.of(context).textTheme.labelMedium
                          : Theme.of(context).textTheme.labelLarge)
                      ?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          tooltip: '刷新',
          icon: Icons.refresh,
          onTap: controller.loading ? null : controller.refresh,
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          tooltip: '添加链接',
          icon: Icons.add_link,
          onTap: controller.analyzing
              ? null
              : () => showAddLinkSheet(context, controller),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.68),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: Icon(icon, color: onTap == null ? _mutedInk : _ink),
        ),
      ),
    );
  }
}

class _ClipboardImportCard extends StatefulWidget {
  const _ClipboardImportCard({required this.controller});

  final ShareController controller;

  @override
  State<_ClipboardImportCard> createState() => _ClipboardImportCardState();
}

class _ClipboardImportCardState extends State<_ClipboardImportCard> {
  String? clipboardUrl;
  bool dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _inspectClipboard());
  }

  Future<void> _inspectClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || dismissed) {
      return;
    }
    final text = data?.text ?? '';
    final url = _firstUrlFromText(text);
    if (url != null) {
      setState(() => clipboardUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = clipboardUrl;
    if (url == null || dismissed) {
      return const SizedBox.shrink();
    }
    return GlassPanel(
      color: const Color(0xFFEAF7EF).withValues(alpha: 0.78),
      child: Row(
        children: [
          const _IconBubble(icon: Icons.content_paste_search, color: _mint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '发现剪切板链接',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _mutedInk),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
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
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

String? _firstUrlFromText(String text) {
  final match = RegExp(r'https?://[^\s，。、《》<>"]+').firstMatch(text);
  return match?.group(0);
}
