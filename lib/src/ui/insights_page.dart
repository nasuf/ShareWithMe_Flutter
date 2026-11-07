part of '../../main.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key, required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    final digest = controller.digest;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 128),
        children: [
          _ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  eyebrow: '',
                  title: '洞察',
                  subtitle: '按收藏夹、来源和高频标签梳理你的近期收藏。',
                  trailing: GlassIconButton(
                    tooltip: '刷新洞察',
                    onPressed: controller.loading ? null : controller.refresh,
                    icon: Icons.refresh_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                _InsightMetricsBar(stats: stats),
                const SizedBox(height: 18),
                _DigestStory(digest: digest),
                const SizedBox(height: 18),
                _DistributionPanel(stats: stats, controller: controller),
                if ((digest?.recentItems ?? []).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    '最近进入资料库',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in digest!.recentItems.take(5))
                    _InsightRecentRow(item: item, controller: controller),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightMetricsBar extends StatelessWidget {
  const _InsightMetricsBar({required this.stats});

  final CollectionStats? stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('资料', '${stats?.total ?? 0}'),
      ('平台', '${stats?.platforms.length ?? 0}'),
      ('收藏夹', '${stats?.categories.length ?? 0}'),
      ('标签', '${stats?.keywords.length ?? 0}'),
    ];
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
      radius: 24,
      color: Colors.white.withValues(alpha: 0.62),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index > 0)
              const SizedBox(
                height: 34,
                child: VerticalDivider(width: 1, color: _line),
              ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    metrics[index].$2,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    metrics[index].$1,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: _mutedInk),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DigestStory extends StatelessWidget {
  const _DigestStory({required this.digest});

  final CollectionDigest? digest;

  @override
  Widget build(BuildContext context) {
    final current = digest;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      radius: 24,
      color: Colors.white.withValues(alpha: 0.64),
      child: current == null
          ? const SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '聚合摘要',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MM-dd HH:mm').format(current.generatedAt),
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: _mutedInk),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  current.focusSummary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: _ink, height: 1.55),
                ),
                if (current.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: _line),
                  const SizedBox(height: 14),
                  for (final suggestion in current.suggestions.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: SizedBox(
                              width: 5,
                              height: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: _mutedInk, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _DistributionPanel extends StatelessWidget {
  const _DistributionPanel({required this.stats, required this.controller});

  final CollectionStats? stats;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      radius: 24,
      color: Colors.white.withValues(alpha: 0.61),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '内容分布',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 17),
          _DistributionList(
            title: '收藏夹',
            icon: Icons.folder_outlined,
            buckets: stats?.categories ?? const [],
            onSelect: controller.openCategory,
          ),
          const Divider(height: 28, color: _line),
          _DistributionList(
            title: '平台',
            icon: Icons.public,
            buckets: stats?.platforms ?? const [],
            platforms: true,
          ),
          const Divider(height: 28, color: _line),
          _DistributionList(
            title: '标签',
            icon: Icons.tag,
            buckets: stats?.keywords ?? const [],
          ),
        ],
      ),
    );
  }
}

class _DistributionList extends StatelessWidget {
  const _DistributionList({
    required this.title,
    required this.icon,
    required this.buckets,
    this.platforms = false,
    this.onSelect,
  });

  final String title;
  final IconData icon;
  final List<CountBucket> buckets;
  final bool platforms;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final visible = buckets.take(5).toList(growable: false);
    final max = visible.isEmpty ? 1 : visible.first.count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: _accent),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        if (visible.isEmpty)
          Text(
            '暂无数据',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _mutedInk),
          )
        else
          for (var index = 0; index < visible.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == visible.length - 1
                    ? 0
                    : (onSelect == null ? 11 : 4),
              ),
              child: _DistributionRow(
                bucket: visible[index],
                max: max,
                platform: platforms ? visible[index].label : null,
                onTap: onSelect == null
                    ? null
                    : () => onSelect!(visible[index].label),
              ),
            ),
      ],
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.bucket,
    required this.max,
    this.platform,
    this.onTap,
  });

  final CountBucket bucket;
  final int max;
  final String? platform;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = platform == null ? null : platformStyle(platform!);
    final color = style?.color ?? _accent;
    final row = Row(
      children: [
        if (platform != null) ...[
          PlatformBrandMark(platform: platform!, size: 20, flat: true),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: platform == null ? 92 : 75,
          child: Text(
            bucket.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: bucket.count / max,
              minHeight: 5,
              color: color,
              backgroundColor: color.withValues(alpha: 0.1),
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '${bucket.count}',
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: _mutedInk),
          ),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_right_rounded, size: 17, color: _mutedInk),
      ],
    );
    if (onTap == null) {
      return row;
    }
    return Semantics(
      button: true,
      label: '打开收藏夹 ${bucket.label}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: row,
          ),
        ),
      ),
    );
  }
}

class _InsightRecentRow extends StatelessWidget {
  const _InsightRecentRow({required this.item, required this.controller});

  final DigestItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        radius: 20,
        color: Colors.white.withValues(alpha: 0.58),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShareScope(
              controller: controller,
              child: DetailPage(itemId: item.id),
            ),
          ),
        ),
        child: Row(
          children: [
            PlatformBrandMark(platform: item.platform, size: 32, flat: true),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.category} · ${DateFormat('MM-dd HH:mm').format(item.createdAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: _mutedInk),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 19, color: _mutedInk),
          ],
        ),
      ),
    );
  }
}
