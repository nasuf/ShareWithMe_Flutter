part of '../../main.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key, required this.controller});

  final ShareController controller;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  late final TextEditingController searchController;
  late final FocusNode searchFocus;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(text: widget.controller.query);
    searchFocus = FocusNode();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final searching = controller.searchOpen || controller.query.isNotEmpty;
    final filtered =
        controller.query.isNotEmpty ||
        controller.category.isNotEmpty ||
        controller.platform.isNotEmpty;
    final featured = filtered ? null : _featuredItem(controller);
    final rows = [
      for (final item in controller.items)
        if (item.id != featured?.id) item,
    ];
    return RefreshIndicator(
      color: context.tokens.accent,
      onRefresh: controller.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _ContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LibraryHeader(
                      controller: controller,
                      onFilter: () => _showFilters(context),
                    ),
                    if (searching) ...[
                      const SizedBox(height: 14),
                      _LibrarySearchField(
                        controller: controller,
                        textController: searchController,
                        focusNode: searchFocus,
                      ),
                    ],
                    if (controller.error != null &&
                        controller.items.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ServiceUnavailableBanner(onRetry: controller.refresh),
                    ],
                    if (featured != null) ...[
                      const SizedBox(height: 16),
                      _FeaturedCard(item: featured, controller: controller),
                    ],
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedFolderBar(controller: controller),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          if (controller.loading && controller.items.isEmpty)
            const SliverToBoxAdapter(
              child: _ContentWidth(child: _LoadingList()),
            )
          else if (controller.items.isEmpty && controller.error != null)
            SliverToBoxAdapter(
              child: _ContentWidth(
                child: _ServiceUnavailableState(onRetry: controller.refresh),
              ),
            )
          else if (controller.items.isEmpty)
            const SliverToBoxAdapter(child: _ContentWidth(child: _EmptyState()))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) => _ContentWidth(
                  child: LibraryRow(
                    item: rows[index],
                    controller: controller,
                    first: index == 0,
                    last: index == rows.length - 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: context.tokens.ink.withValues(alpha: 0.16),
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      builder: (_) => ShareScope(
        controller: widget.controller,
        child: _LibraryFilterSheet(controller: widget.controller),
      ),
    );
  }
}

class _ContentWidth extends StatelessWidget {
  const _ContentWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.controller, required this.onFilter});

  final ShareController controller;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final filtersActive =
        controller.statusFilter != 'active' ||
        controller.sortMode != 'newest' ||
        controller.platform.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _chineseDateLabel(DateTime.now()),
                  style: _eyebrowStyle(context),
                ),
                const SizedBox(height: 2),
                Text('资料库', style: _largeTitleStyle(context)),
              ],
            ),
          ),
          GlassIconButton(
            tooltip: '筛选与排序',
            icon: Icons.tune_rounded,
            active: filtersActive,
            onPressed: onFilter,
          ),
          const SizedBox(width: 10),
          controller.analyzing
              ? const SizedBox.square(
                  dimension: 44,
                  child: LiquidGlass(
                    radius: 22,
                    blur: 20,
                    child: Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : GlassIconButton(
                  tooltip: '收集链接',
                  icon: Icons.add_rounded,
                  onPressed: () => showAddLinkSheet(context, controller),
                ),
        ],
      ),
    );
  }
}

class _LibrarySearchField extends StatelessWidget {
  const _LibrarySearchField({
    required this.controller,
    required this.textController,
    required this.focusNode,
  });

  final ShareController controller;
  final TextEditingController textController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 48,
      child: LiquidGlass(
        radius: 24,
        blur: 20,
        opacity: 0.7,
        padding: const EdgeInsets.only(left: 14, right: 4),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20, color: t.mutedInk),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
                autofocus: controller.searchOpen && controller.query.isEmpty,
                textInputAction: TextInputAction.search,
                onChanged: controller.setQuery,
                style: TextStyle(color: t.ink, fontSize: 16),
                decoration: InputDecoration(
                  hintText: '搜索标题、摘要、关键词',
                  hintStyle: TextStyle(color: t.mutedInk, fontSize: 16),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: '关闭搜索',
              onPressed: () {
                textController.clear();
                focusNode.unfocus();
                controller.closeSearch();
              },
              icon: Icon(Icons.close_rounded, size: 20, color: t.mutedInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.controller});

  final LinkItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final style = platformStyle(item.platform);
    final t = context.tokens;
    final byline = [
      style.label,
      if (item.category.trim().isNotEmpty) item.category.trim(),
      if ((item.author ?? '').trim().isNotEmpty) item.author!.trim(),
    ].join(' · ');
    return Semantics(
      button: true,
      label: '本周精选，${item.title}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _openDetail(context, controller, item),
        onLongPress: () => _showItemActions(context, controller, item),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: t.glassShadow.withValues(alpha: 0.28),
                blurRadius: 40,
                spreadRadius: -14,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SizedBox(
              height: 244,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _coverUrl(controller, item),
                    fit: BoxFit.cover,
                    cacheWidth: 1000,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: style.softColor),
                  ),
                  const Positioned(
                    left: 14,
                    top: 14,
                    child: _ImageGlassLabel(label: '本周精选'),
                  ),
                  if (_isVideoItem(item)) const Center(child: _PlayBadge()),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: LiquidGlass(
                      radius: 22,
                      blur: 22,
                      opacity: 0.22,
                      dark: false,
                      shadow: false,
                      padding: const EdgeInsets.fromLTRB(15, 12, 15, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            byline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              height: 1.28,
                              letterSpacing: -0.2,
                              shadows: [
                                Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class _ImageGlassLabel extends StatelessWidget {
  const _ImageGlassLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      radius: 14,
      blur: 16,
      opacity: 0.2,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 52,
      child: LiquidGlass(
        radius: 26,
        blur: 16,
        opacity: 0.24,
        shadow: false,
        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _FolderChips extends StatelessWidget {
  const _FolderChips({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final folders = [...?controller.stats?.categories]
      ..sort((a, b) => b.count.compareTo(a.count));
    final total = controller.stats?.total ?? controller.items.length;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        children: [
          _FolderChip(
            label: '全部',
            count: total,
            selected: controller.category.isEmpty,
            onTap: () {
              if (controller.category.isNotEmpty) {
                controller.setCategory(controller.category);
              }
            },
          ),
          if (controller.platform.isNotEmpty)
            _FolderChip(
              label: platformStyle(controller.platform).label,
              selected: true,
              removable: true,
              onTap: () => controller.setPlatform(controller.platform),
            ),
          for (final folder in folders.take(10))
            _FolderChip(
              label: folder.label,
              count: folder.count,
              selected: controller.category == folder.label,
              onTap: () => controller.setCategory(folder.label),
            ),
        ],
      ),
    );
  }
}

/// The folder chips, pinned under the status bar once the header scrolls
/// away. While pinned, a frosted strip fades in behind them so the list rows
/// scrolling underneath stay out of the way.
class _PinnedFolderBar extends SliverPersistentHeaderDelegate {
  _PinnedFolderBar({required this.controller});

  final ShareController controller;

  static const double _height = 56;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // `overlapsContent` only reports overlap with other pinned headers, so
    // use how far the bar has scrolled into its pinned position instead.
    final pinned = (shrinkOffset / 12).clamp(0.0, 1.0);
    final notifier = controller.libraryBarPinned;
    if (notifier.value != pinned) {
      // Can't notify listeners mid-build; hand it to the shell after layout.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.value = pinned;
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FrostedStrip(progress: pinned, divider: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
          child: _ContentWidth(child: _FolderChips(controller: controller)),
        ),
      ],
    );
  }

  // Rebuilt with fresh controller state on every library build.
  @override
  bool shouldRebuild(_PinnedFolderBar oldDelegate) => true;
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.removable = false,
  });

  final String label;
  final int? count;
  final bool selected;
  final bool removable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final foreground = selected ? Colors.white : t.ink;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: foreground.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (removable) ...[
          const SizedBox(width: 4),
          Icon(Icons.close_rounded, size: 15, color: foreground),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: selected
            ? Material(
                color: t.ink,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(child: content),
                  ),
                ),
              )
            : LiquidGlass(
                radius: 18,
                blur: 0,
                opacity: 0.62,
                shadow: false,
                onTap: onTap,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(widthFactor: 1, child: content),
              ),
      ),
    );
  }
}

void _openDetail(
  BuildContext context,
  ShareController controller,
  LinkItem item,
) {
  Navigator.of(context).push(
    _DetailRoute<void>(
      builder: (_) => ShareScope(
        controller: controller,
        child: DetailPage(itemId: item.id),
      ),
    ),
  );
}
