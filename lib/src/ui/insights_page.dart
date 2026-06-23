part of '../../main.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key, required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    final digest = controller.digest;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
      children: [
        _InsightsHeader(stats: stats),
        const SizedBox(height: 14),
        _InsightMetricsBar(stats: stats),
        const SizedBox(height: 12),
        _DigestPanel(digest: digest, controller: controller),
        const SizedBox(height: 12),
        _InsightDistributionGrid(stats: stats),
      ],
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader({required this.stats});

  final CollectionStats? stats;

  @override
  Widget build(BuildContext context) {
    final topTopic = (stats?.categories ?? []).isEmpty
        ? '等待收集'
        : stats!.categories.first.label;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 2, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insights',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _mint,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '洞察',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    height: 0.98,
                  ),
                ),
              ],
            ),
          ),
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            radius: 22,
            color: Colors.white.withValues(alpha: 0.42),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.center_focus_strong, size: 16, color: _mint),
                const SizedBox(width: 6),
                Text(
                  topTopic,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
      _InsightMetricData(
        label: '资料卡',
        value: '${stats?.total ?? 0}',
        icon: Icons.auto_stories_outlined,
      ),
      _InsightMetricData(
        label: '平台',
        value: '${stats?.platforms.length ?? 0}',
        icon: Icons.public,
      ),
      _InsightMetricData(
        label: '标签',
        value: '${stats?.keywords.length ?? 0}',
        icon: Icons.sell_outlined,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _InsightMetricTile(data: metrics[i])),
        ],
      ],
    );
  }
}

class _InsightMetricData {
  const _InsightMetricData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _InsightMetricTile extends StatelessWidget {
  const _InsightMetricTile({required this.data});

  final _InsightMetricData data;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      radius: 24,
      color: Colors.white.withValues(alpha: 0.46),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: data.icon),
          const SizedBox(height: 10),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _mutedInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightDistributionGrid extends StatelessWidget {
  const _InsightDistributionGrid({required this.stats});

  final CollectionStats? stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BucketSection(
          title: '主题分布',
          icon: Icons.folder,
          buckets: stats?.categories ?? [],
        ),
        const SizedBox(height: 12),
        _BucketSection(
          title: '平台分布',
          icon: Icons.public,
          buckets: stats?.platforms ?? [],
        ),
        const SizedBox(height: 12),
        _BucketSection(
          title: '标签热度',
          icon: Icons.sell_outlined,
          buckets: stats?.keywords ?? [],
        ),
      ],
    );
  }
}

class _DigestPanel extends StatelessWidget {
  const _DigestPanel({required this.digest, required this.controller});

  final CollectionDigest? digest;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final current = digest;
    if (current == null) {
      return const _Section(
        title: '聚合摘要',
        icon: Icons.auto_awesome,
        child: Text('正在生成汇总'),
      );
    }
    return _Section(
      title: '聚合摘要',
      icon: Icons.auto_awesome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current.focusSummary,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          if (current.suggestions.isNotEmpty) ...[
            Text('整理建议', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final suggestion in current.suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(suggestion)),
                  ],
                ),
              ),
          ],
          if (current.recentItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('最近资料', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final item in current.recentItems.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InsightRecentRow(item: item, controller: controller),
              ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '生成于 ${DateFormat('MM-dd HH:mm').format(current.generatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
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
    final style = platformStyle(item.platform);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShareScope(
              controller: controller,
              child: DetailPage(itemId: item.id),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            _PlatformIcon(platform: item.platform),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.category} · ${DateFormat('MM-dd HH:mm').format(item.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _mutedInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(style.icon, color: style.color, size: 18),
          ],
        ),
      ),
    );
  }
}
