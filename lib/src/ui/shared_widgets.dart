part of '../../main.dart';

// Design D tokens: near-black ink, a 7:1 secondary grey and iOS system blue.
const _ink = Color(0xFF0E1110);
const _mutedInk = Color(0xFF4D5651);
const _accent = Color(0xFF0A64D8);
const _mint = Color(0xFF3D8AE8);
const _accentSoft = Color(0xFFE3EDFB);
const _line = Color(0x1F141E19);
const _surface = Color(0xFFF2F5F3);

class GlassBackground extends StatelessWidget {
  const GlassBackground({
    super.key,
    required this.child,
    this.imageUrls = const [],
  });

  final Widget child;
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return AmbientBackdrop(imageUrls: imageUrls, child: child);
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.color,
    this.borderColor,
    this.onTap,
    this.blurSigma = 26,
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
    return LiquidGlass(
      radius: radius,
      padding: padding,
      blur: blurSigma,
      opacity: color?.a ?? 0.66,
      onTap: onTap,
      child: child,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow.trim().isNotEmpty) ...[
                  Text(
                    eyebrow,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(title, style: _largeTitleStyle(context)),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _mutedInk,
                    fontSize: 15,
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 14), trailing!],
        ],
      ),
    );
  }
}

class SoftTag extends StatelessWidget {
  const SoftTag({
    super.key,
    required this.label,
    this.icon,
    this.color = _accent,
    this.onDeleted,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: EdgeInsets.fromLTRB(icon == null ? 12 : 10, 7, 11, 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 5),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(Icons.close, size: 14, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.size = 44,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GlassCircleButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: onPressed,
      size: size,
      foreground: active ? _accent : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 32),
      child: Column(
        children: [
          const Icon(Icons.bookmarks_outlined, size: 42, color: _accent),
          const SizedBox(height: 14),
          Text(
            '资料库还是空的',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '从其他 App 分享链接，或点击底部“收集”。',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _mutedInk, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 90),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _ServiceUnavailableBanner extends StatelessWidget {
  const _ServiceUnavailableBanner({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0DFC0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 19,
            color: Color(0xFF956A22),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              '资料服务暂时离线，正在显示上次加载的内容',
              style: TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: '重新连接',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 19),
          ),
        ],
      ),
    );
  }
}

class _ServiceUnavailableState extends StatelessWidget {
  const _ServiceUnavailableState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 28),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF3F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_outlined, color: _accent),
          ),
          const SizedBox(height: 16),
          Text(
            '暂时无法连接资料服务',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '界面已经正常启动。请检查网络或服务器状态后重试。',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _mutedInk, height: 1.45),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新连接'),
          ),
        ],
      ),
    );
  }
}
