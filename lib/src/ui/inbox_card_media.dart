part of '../../main.dart';

bool _isVideoItem(LinkItem item) {
  final type = item.contentType.toLowerCase();
  return type.contains('video') ||
      type.contains('视频') ||
      const {'哔哩哔哩', 'YouTube', '抖音', 'TikTok', '快手'}.contains(item.platform);
}

class CardCoverMedia extends StatefulWidget {
  const CardCoverMedia({
    super.key,
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
  State<CardCoverMedia> createState() => _CardCoverMediaState();
}

class _CardCoverMediaState extends State<CardCoverMedia>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> scale;
  bool reportedImageError = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    );
    scale = Tween<double>(begin: 1, end: 1.025).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
      controller.value = 0;
    } else if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CardCoverMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      reportedImageError = false;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: AspectRatio(
        aspectRatio: 1.62,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(child: _buildImage()),
            Positioned(
              left: 0,
              top: 0,
              child: _CoverPlatformBadge(item: widget.item),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _CoverImportanceBadge(score: widget.item.importanceScore),
            ),
            if (_isVideoItem(widget.item))
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.46),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
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

  Widget _buildImage() {
    if (widget.imageUrl.isEmpty) {
      return ColoredBox(
        color: widget.style.softColor,
        child: Center(
          child: PlatformBrandMark(platform: widget.item.platform, size: 54),
        ),
      );
    }
    return AnimatedBuilder(
      animation: scale,
      builder: (context, child) =>
          Transform.scale(scale: scale.value, child: child),
      child: Image.network(
        widget.imageUrl,
        fit: BoxFit.cover,
        cacheWidth: 1200,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, _) => AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 260),
          child: child,
        ),
        errorBuilder: (context, error, stackTrace) {
          if (!reportedImageError) {
            reportedImageError = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onError();
            });
          }
          return ColoredBox(
            color: widget.style.softColor,
            child: Center(
              child: PlatformBrandMark(
                platform: widget.item.platform,
                size: 54,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoverPlatformBadge extends StatelessWidget {
  const _CoverPlatformBadge({required this.item});

  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    final style = platformStyle(item.platform);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 11, 7),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(17),
          bottomRight: Radius.circular(15),
        ),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.52)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.52)),
        ),
        boxShadow: [
          BoxShadow(
            color: style.color.withValues(alpha: 0.28),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          PlatformBrandMark(platform: item.platform, size: 21, flat: true),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              shadows: const [Shadow(color: Color(0x33000000), blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImportanceBadge extends StatelessWidget {
  const _CoverImportanceBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _ink.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                spreadRadius: -5,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            '重要度 $score',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
