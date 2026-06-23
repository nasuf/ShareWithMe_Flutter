part of '../../main.dart';

class _CardMediaHeader extends StatelessWidget {
  const _CardMediaHeader({
    required this.imageUrl,
    required this.item,
    required this.style,
    required this.showPlay,
    required this.contentIcon,
    required this.onImageError,
  });

  final String imageUrl;
  final LinkItem item;
  final PlatformStyle style;
  final bool showPlay;
  final IconData contentIcon;
  final VoidCallback onImageError;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _BreathingImage(
            imageUrl,
            onError: onImageError,
            errorBuilder: (_, _, _) => ColoredBox(
              color: style.softColor,
              child: Icon(style.icon, color: style.color),
            ),
          ),
          ColoredBox(color: style.softColor.withValues(alpha: 0.06)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  style.color.withValues(alpha: 0.08),
                  _ink.withValues(alpha: 0.04),
                  style.color.withValues(alpha: 0.04),
                  _ink.withValues(alpha: 0.38),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            right: 14,
            child: Row(
              children: [
                _CardPlatformBadge(item: item, style: style, onMedia: true),
                const SizedBox(width: 8),
                _CardTypeBadge(
                  label: item.contentType,
                  icon: contentIcon,
                  color: style.color,
                  onMedia: true,
                ),
                const Spacer(),
                _ScorePill(
                  score: item.importanceScore,
                  color: style.color,
                  onMedia: true,
                ),
              ],
            ),
          ),
          if (showPlay)
            Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _ink.withValues(alpha: 0.68),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _ink.withValues(alpha: 0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BreathingImage extends StatefulWidget {
  const _BreathingImage(this.url, {this.onError, required this.errorBuilder});

  final String url;
  final VoidCallback? onError;
  final ImageErrorWidgetBuilder errorBuilder;

  @override
  State<_BreathingImage> createState() => _BreathingImageState();
}

class _BreathingImageState extends State<_BreathingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  String? _reportedErrorUrl;
  bool _imageReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _scale = Tween<double>(begin: 1, end: 1.028).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didUpdateWidget(covariant _BreathingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _reportedErrorUrl = null;
      _imageReady = false;
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (width * dpr).clamp(420, 1200).round();
    final image = Image.network(
      widget.url,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        final ready = wasSynchronouslyLoaded || frame != null;
        if (ready && !_imageReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _imageReady) {
              return;
            }
            setState(() {
              _imageReady = true;
            });
            if (!(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
              _controller.repeat(reverse: true);
            }
          });
        }
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
        _controller.stop();
        if (_reportedErrorUrl != widget.url) {
          _reportedErrorUrl = widget.url;
          final onError = widget.onError;
          if (onError != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                onError();
              }
            });
          }
        }
        return widget.errorBuilder(context, error, stackTrace);
      },
    );
    if (!_imageReady ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      return image;
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scale,
        child: image,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
      ),
    );
  }
}

class _GeneratedCardBanner extends StatelessWidget {
  const _GeneratedCardBanner({
    required this.item,
    required this.style,
    required this.contentIcon,
  });

  final LinkItem item;
  final PlatformStyle style;
  final IconData contentIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _creamSurface.withValues(alpha: 0.88),
                  const Color(0xFFFFE5C4).withValues(alpha: 0.48),
                  style.softColor.withValues(alpha: 0.28),
                  Colors.white.withValues(alpha: 0.22),
                ],
                stops: const [0, 0.44, 0.76, 1],
              ),
            ),
          ),
          Positioned(
            right: -26,
            top: -30,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFECA88E).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 14,
            child: Icon(
              style.icon,
              size: 50,
              color: style.color.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            right: 14,
            child: Row(
              children: [
                _CardPlatformBadge(item: item, style: style),
                const SizedBox(width: 8),
                _CardTypeBadge(
                  label: item.contentType,
                  icon: contentIcon,
                  color: style.color,
                ),
                const Spacer(),
                _ScorePill(score: item.importanceScore, color: style.color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPlatformBadge extends StatelessWidget {
  const _CardPlatformBadge({
    required this.item,
    required this.style,
    this.onMedia = false,
  });

  final LinkItem item;
  final PlatformStyle style;
  final bool onMedia;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 156),
      padding: const EdgeInsets.fromLTRB(6, 5, 11, 5),
      decoration: BoxDecoration(
        gradient: _platformBadgeGradient(item.platform, style, onMedia),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onMedia
              ? Colors.white.withValues(alpha: 0.62)
              : style.color.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: style.color.withValues(alpha: onMedia ? 0.24 : 0.16),
            blurRadius: onMedia ? 12 : 14,
            offset: const Offset(4, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlatformBrandMark(platform: item.platform, size: 22, flat: onMedia),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              item.platform,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: onMedia ? Colors.white : style.color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

LinearGradient _platformBadgeGradient(
  String platform,
  PlatformStyle style,
  bool onMedia,
) {
  if (onMedia) {
    return _brandGradient(platform, style);
  }
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      style.softColor.withValues(alpha: 0.96),
      _creamSurface.withValues(alpha: 0.9),
      style.color.withValues(alpha: 0.08),
    ],
    stops: const [0, 0.62, 1],
  );
}

class _CardTypeBadge extends StatelessWidget {
  const _CardTypeBadge({
    required this.label,
    required this.icon,
    required this.color,
    this.onMedia = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool onMedia;

  @override
  Widget build(BuildContext context) {
    final foreground = onMedia ? Colors.white : _mutedInk;
    return Container(
      constraints: const BoxConstraints(maxWidth: 124),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: onMedia
            ? _ink.withValues(alpha: 0.38)
            : _creamSurface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onMedia
              ? Colors.white.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.76),
        ),
        boxShadow: onMedia
            ? null
            : [
                BoxShadow(
                  color: _warmShadow.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(4, 6),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.score,
    required this.color,
    this.onMedia = false,
  });

  final int score;
  final Color color;
  final bool onMedia;

  @override
  Widget build(BuildContext context) {
    final high = score >= 75;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: onMedia
            ? _ink.withValues(alpha: 0.46)
            : _creamSurface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onMedia
              ? Colors.white.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.78),
        ),
        boxShadow: onMedia
            ? null
            : [
                BoxShadow(
                  color: _warmShadow.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(4, 7),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            size: 14,
            color: onMedia ? Colors.white : (high ? color : _mutedInk),
          ),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: onMedia ? Colors.white : _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

bool _isVideoItem(LinkItem item) {
  final type = item.contentType.toLowerCase();
  return type.contains('video') ||
      type.contains('视频') ||
      const {'哔哩哔哩', 'YouTube', '抖音', 'TikTok', '快手'}.contains(item.platform);
}

IconData _contentIcon(LinkItem item) {
  if (_isVideoItem(item)) {
    return Icons.play_circle_outline;
  }
  final type = item.contentType.toLowerCase();
  if (type.contains('image') || type.contains('图片')) {
    return Icons.image_outlined;
  }
  if (type.contains('audio') || type.contains('音频')) {
    return Icons.headphones_outlined;
  }
  if (type.contains('product') || type.contains('商品')) {
    return Icons.shopping_bag_outlined;
  }
  if (type.contains('place') || type.contains('地点')) {
    return Icons.place_outlined;
  }
  return Icons.folder_outlined;
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _creamSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: _warmShadow.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(4, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'favorite' => '重要',
    'archived' => '归档',
    _ => '资料库',
  };
}

IconData _statusIcon(String status) {
  return switch (status) {
    'favorite' => Icons.star,
    'archived' => Icons.archive,
    _ => Icons.inbox,
  };
}
