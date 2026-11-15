part of '../../main.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key, required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    final digest = controller.digest;
    final folders = [...?stats?.categories]
      ..sort((a, b) => b.count.compareTo(a.count));
    return RefreshIndicator(
      color: _accent,
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('全部收藏 · 截至今天', style: _eyebrowStyle(context)),
                            const SizedBox(height: 2),
                            Text('洞察', style: _largeTitleStyle(context)),
                          ],
                        ),
                      ),
                      GlassIconButton(
                        tooltip: '刷新洞察',
                        icon: Icons.refresh_rounded,
                        onPressed: controller.loading
                            ? null
                            : controller.refresh,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PlatformRingCard(stats: stats),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _TopFolderCard(
                          folder: folders.isEmpty ? null : folders.first,
                          total: stats?.total ?? 0,
                          onOpen: controller.openCategory,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RecentCoversCard(controller: controller),
                      ),
                    ],
                  ),
                ),
                if (digest != null &&
                    digest.focusSummary.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DigestCard(digest: digest),
                ],
                if (folders.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ChipCard(
                    title: '收藏夹',
                    buckets: folders.take(12).toList(),
                    onTap: controller.openCategory,
                  ),
                ],
                if ((stats?.keywords ?? []).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ChipCard(
                    title: '高频标签',
                    buckets: stats!.keywords.take(12).toList(),
                    onTap: (tag) {
                      controller.setQuery(tag);
                      controller.openSearch();
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformRingCard extends StatelessWidget {
  const _PlatformRingCard({required this.stats});

  final CollectionStats? stats;

  @override
  Widget build(BuildContext context) {
    final buckets = [...?stats?.platforms]
      ..sort((a, b) => b.count.compareTo(a.count));
    final shown = buckets.take(4).toList();
    final rest = buckets
        .skip(4)
        .fold<int>(0, (sum, bucket) => sum + bucket.count);
    // Ranked chart colours: brand colours collide (小红书 and 头条 are both
    // red), so the legend carries the platform and the ring stays legible.
    const palette = [
      Color(0xFF0A64D8),
      Color(0xFFE8590C),
      Color(0xFF0F9D8A),
      Color(0xFF7C3AED),
    ];
    final segments = [
      for (var index = 0; index < shown.length; index++)
        (shown[index].label, shown[index].count, palette[index]),
      if (rest > 0) ('其他', rest, const Color(0xFFB8BEC4)),
    ];
    final total = stats?.total ?? 0;
    return LiquidGlass(
      radius: 30,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Semantics(
            label: [
              for (final segment in segments) '${segment.$1} ${segment.$2} 条',
            ].join('，'),
            child: SizedBox.square(
              dimension: 128,
              child: CustomPaint(
                painter: _RingPainter(segments: segments),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '条收藏',
                        style: TextStyle(
                          color: _mutedInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: segments.isEmpty
                ? const Text('还没有收藏', style: TextStyle(color: _mutedInk))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final segment in segments)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.5),
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: segment.$3,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  platformStyle(segment.$1).label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${segment.$2}',
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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

class _RingPainter extends CustomPainter {
  _RingPainter({required this.segments});

  final List<(String, int, Color)> segments;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.$2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (total == 0) {
      canvas.drawArc(
        arcRect,
        0,
        6.283,
        false,
        paint..color = _ink.withValues(alpha: 0.08),
      );
      return;
    }
    const gap = 0.035;
    var start = -1.5708;
    for (final segment in segments) {
      final sweep = segment.$2 / total * 6.2832;
      canvas.drawArc(
        arcRect,
        start + gap / 2,
        (sweep - gap).clamp(0.01, 6.2832),
        false,
        paint..color = segment.$3,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.segments.toString() != segments.toString();
}

class _TopFolderCard extends StatelessWidget {
  const _TopFolderCard({
    required this.folder,
    required this.total,
    required this.onOpen,
  });

  final CountBucket? folder;
  final int total;
  final void Function(String) onOpen;

  @override
  Widget build(BuildContext context) {
    final current = folder;
    final share = current == null || total == 0 ? 0.0 : current.count / total;
    return LiquidGlass(
      radius: 26,
      padding: const EdgeInsets.all(16),
      onTap: current == null ? null : () => onOpen(current.label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最大收藏夹',
            style: TextStyle(
              color: _mutedInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            current?.label ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _accent,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              color: _accent,
              backgroundColor: _ink.withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            current == null ? '暂无' : '${current.count} / $total 条',
            style: const TextStyle(color: _mutedInk, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RecentCoversCard extends StatelessWidget {
  const _RecentCoversCard({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final recent = [...controller.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final withCovers = recent
        .where((item) => _coverUrl(controller, item).isNotEmpty)
        .take(4)
        .toList();
    final categories = <String>{
      for (final item in recent.take(6))
        if (item.category.trim().isNotEmpty) item.category.trim(),
    }.take(4).join('、');
    return LiquidGlass(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近收藏',
            style: TextStyle(
              color: _mutedInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: Stack(
              children: [
                for (var index = 0; index < withCovers.length; index++)
                  Positioned(
                    left: index * 30.0,
                    child: GestureDetector(
                      onTap: () =>
                          _openDetail(context, controller, withCovers[index]),
                      child: Container(
                        width: 44,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _glassShadow.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _coverUrl(controller, withCovers[index]),
                            fit: BoxFit.cover,
                            cacheWidth: 160,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: platformStyle(
                                withCovers[index].platform,
                              ).softColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            categories.isEmpty ? '暂无' : categories,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _mutedInk, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DigestCard extends StatelessWidget {
  const _DigestCard({required this.digest});

  final CollectionDigest digest;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 16, color: _accent),
              const SizedBox(width: 6),
              const Text(
                'AI 总结',
                style: TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MM-dd HH:mm').format(digest.generatedAt),
                style: const TextStyle(color: _mutedInk, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            digest.focusSummary,
            style: const TextStyle(color: _ink, fontSize: 15, height: 1.55),
          ),
          for (final suggestion in digest.suggestions.take(2)) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: SizedBox.square(
                    dimension: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      color: _mutedInk,
                      fontSize: 14,
                      height: 1.45,
                    ),
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

class _ChipCard extends StatelessWidget {
  const _ChipCard({
    required this.title,
    required this.buckets,
    required this.onTap,
  });

  final String title;
  final List<CountBucket> buckets;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final bucket in buckets)
                Material(
                  color: Colors.white.withValues(alpha: 0.72),
                  shape: StadiumBorder(
                    side: BorderSide(color: _glassRim, width: 0.8),
                  ),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onTap(bucket.label),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bucket.label,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${bucket.count}',
                            style: const TextStyle(
                              color: _mutedInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
