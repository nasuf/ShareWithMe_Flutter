part of '../../main.dart';

const _ink = Color(0xFF263038);
const _mutedInk = Color(0xFF7B7468);
const _mint = Color(0xFF6F927D);
const _creamSurface = Color(0xFFFFF8E9);
const _warmShadow = Color(0xFFB99D76);

class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF7EAD4),
            Color(0xFFF4E2C5),
            Color(0xFFECD7B5),
            Color(0xFFF9EEDC),
          ],
          stops: [0, 0.42, 0.72, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.88, -0.92),
                  radius: 1.15,
                  colors: [
                    const Color(0xFFD8E5CF).withValues(alpha: 0.64),
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.86, 0.82),
                  radius: 1.1,
                  colors: [
                    const Color(0xFFF3B49A).withValues(alpha: 0.36),
                    const Color(0xFFFFE8C6).withValues(alpha: 0.24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
    this.color,
    this.borderColor,
    this.onTap,
    this.blurSigma = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final panel = ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? _creamSurface.withValues(alpha: 0.9),
            borderRadius: shape,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.78),
            ),
            boxShadow: [
              BoxShadow(
                color: _warmShadow.withValues(alpha: 0.22),
                blurRadius: 32,
                spreadRadius: -8,
                offset: const Offset(10, 18),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.78),
                blurRadius: 16,
                spreadRadius: -8,
                offset: const Offset(-8, -10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) {
      return panel;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: shape, onTap: onTap, child: panel),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      radius: 28,
      color: Colors.white.withValues(alpha: 0.54),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _mint,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _mutedInk,
                    height: 1.32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: icon),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BucketSection extends StatelessWidget {
  const _BucketSection({
    required this.title,
    required this.icon,
    required this.buckets,
  });

  final String title;
  final IconData icon;
  final List<CountBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final max = buckets.isEmpty ? 1 : buckets.first.count;
    final visibleBuckets = buckets.take(5).toList();
    final hiddenCount = buckets.length - visibleBuckets.length;
    return _Section(
      title: title,
      icon: icon,
      child: buckets.isEmpty
          ? const Text('暂无数据')
          : Column(
              children: [
                for (final bucket in visibleBuckets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bucket.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: _ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${bucket.count}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: _mutedInk,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: bucket.count / max,
                            minHeight: 9,
                            color: _mint.withValues(alpha: 0.78),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.68,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hiddenCount > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SoftTag(
                      label: '还有 $hiddenCount 个',
                      icon: Icons.more_horiz,
                      color: _mutedInk,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, this.color = _mint});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class SoftTag extends StatelessWidget {
  const SoftTag({
    super.key,
    required this.label,
    this.icon,
    this.color = _mint,
    this.onDeleted,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: EdgeInsets.only(
        left: icon == null ? 12 : 10,
        right: onDeleted == null ? 12 : 8,
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: _creamSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: _warmShadow.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(4, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(Icons.close, size: 15, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportancePill extends StatelessWidget {
  const _ImportancePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: score >= 75 ? const Color(0xFFDDF4E7) : const Color(0xFFF0F2EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '重要度 $score',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(
            Icons.move_to_inbox,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text('还没有收集内容', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('从其他 App 分享链接过来，或点击右下角添加。'),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++) ...[
          const Card(
            child: SizedBox(
              height: 126,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
