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
    return RefreshIndicator(
      color: _accent,
      onRefresh: controller.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _ContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                child: Column(
                  children: [
                    _LibraryTitleBar(
                      controller: controller,
                      total: controller.stats?.total ?? controller.items.length,
                      onFilter: () => _showFilters(context),
                    ),
                    const SizedBox(height: 13),
                    _LibrarySearchBar(
                      controller: controller,
                      textController: searchController,
                      focusNode: searchFocus,
                    ),
                    const SizedBox(height: 12),
                    _PlatformIndexBar(
                      controller: controller,
                      platforms: controller.stats?.platforms ?? const [],
                      onFilter: () => _showFilters(context),
                    ),
                    const SizedBox(height: 12),
                    if (controller.error != null &&
                        controller.items.isNotEmpty) ...[
                      _ServiceUnavailableBanner(onRetry: controller.refresh),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (controller.loading)
            const SliverToBoxAdapter(
              child: _ContentWidth(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 128),
                  child: _LoadingList(),
                ),
              ),
            )
          else if (controller.items.isEmpty && controller.error != null)
            SliverToBoxAdapter(
              child: _ContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 128),
                  child: _ServiceUnavailableState(onRetry: controller.refresh),
                ),
              ),
            )
          else if (controller.items.isEmpty)
            const SliverToBoxAdapter(
              child: _ContentWidth(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 128),
                  child: _EmptyState(),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 146),
              sliver: SliverList.separated(
                itemCount: controller.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 20),
                itemBuilder: (context, index) => _ContentWidth(
                  child: LinkCard(
                    item: controller.items[index],
                    controller: controller,
                    lastInGroup: true,
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
      barrierColor: _ink.withValues(alpha: 0.16),
      isScrollControlled: true,
      useSafeArea: true,
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

class _LibraryTitleBar extends StatelessWidget {
  const _LibraryTitleBar({
    required this.controller,
    required this.total,
    required this.onFilter,
  });

  final ShareController controller;
  final int total;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '资料库',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _ink.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '$total',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '我的收藏链接',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: _mutedInk, fontSize: 16),
              ),
            ],
          ),
        ),
        GlassIconButton(
          tooltip: '刷新资料库',
          icon: Icons.refresh_rounded,
          onPressed: controller.loading ? null : controller.refresh,
        ),
        const SizedBox(width: 10),
        GlassIconButton(
          tooltip: '筛选与排序',
          icon: Icons.format_list_bulleted_rounded,
          active:
              controller.statusFilter != 'active' ||
              controller.sortMode != 'newest' ||
              controller.category.isNotEmpty,
          onPressed: onFilter,
        ),
      ],
    );
  }
}

class _LibrarySearchBar extends StatelessWidget {
  const _LibrarySearchBar({
    required this.controller,
    required this.textController,
    required this.focusNode,
  });

  final ShareController controller;
  final TextEditingController textController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: textController,
      focusNode: focusNode,
      constraints: const BoxConstraints(minHeight: 54, maxHeight: 54),
      hintText: '搜索标题、摘要、关键词',
      hintStyle: const WidgetStatePropertyAll(
        TextStyle(color: _mutedInk, fontSize: 15),
      ),
      leading: const Padding(
        padding: EdgeInsets.only(left: 3),
        child: Icon(Icons.search_rounded, size: 25, color: _ink),
      ),
      trailing: [
        if (controller.query.isNotEmpty)
          IconButton(
            tooltip: '清空搜索',
            onPressed: () {
              textController.clear();
              controller.setQuery('');
            },
            icon: const Icon(Icons.close_rounded, size: 19),
          )
        else
          Container(
            margin: const EdgeInsets.only(right: 2),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: _ink.withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Text(
              '⌘K',
              style: TextStyle(
                color: _mutedInk,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      onChanged: controller.setQuery,
    );
  }
}

class _PlatformIndexBar extends StatelessWidget {
  const _PlatformIndexBar({
    required this.controller,
    required this.platforms,
    required this.onFilter,
  });

  final ShareController controller;
  final List<CountBucket> platforms;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    const corePlatforms = ['小红书', '微博', '今日头条', '微信公众号'];
    final indexedPlatforms = <String>[
      ...corePlatforms,
      for (final bucket in platforms)
        if (!corePlatforms.contains(bucket.label)) bucket.label,
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: indexedPlatforms.length + 2,
        separatorBuilder: (_, _) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PlatformFilterChip(
              label: '全部',
              selected: controller.platform.isEmpty,
              onTap: () {
                if (controller.platform.isNotEmpty) {
                  controller.setPlatform(controller.platform);
                }
              },
            );
          }
          if (index == indexedPlatforms.length + 1) {
            return _PlatformFilterChip(
              label: '筛选',
              icon: Icons.filter_alt_outlined,
              selected: false,
              onTap: onFilter,
            );
          }
          final platform = indexedPlatforms[index - 1];
          return _PlatformFilterChip(
            label: platformStyle(platform).label,
            platform: platform,
            selected: controller.platform == platform,
            onTap: () => controller.setPlatform(platform),
          );
        },
      ),
    );
  }
}

class _PlatformFilterChip extends StatelessWidget {
  const _PlatformFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.platform,
    this.icon,
  });

  final String label;
  final String? platform;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? _accentSoft.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? _accent.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.92),
            ),
          ),
          child: Row(
            children: [
              if (platform != null) ...[
                PlatformBrandMark(platform: platform!, size: 18, flat: true),
                const SizedBox(width: 5),
              ] else if (icon != null) ...[
                Icon(icon, size: 17, color: _ink),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? _accent : _ink,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
