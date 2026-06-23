part of '../../main.dart';

class LinkCard extends StatelessWidget {
  const LinkCard({super.key, required this.item, required this.controller});

  final LinkItem item;
  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final style = platformStyle(item.platform);
    final imageUrl = resolveBackendMediaUrl(
      controller.api.baseUrl,
      item.imageUrl?.trim() ?? '',
    );
    final hasImage = imageUrl.isNotEmpty;
    final isVideo = _isVideoItem(item);
    final contentIcon = _contentIcon(item);
    final tags = <String>[
      item.category,
      ...item.keywords.where((keyword) => keyword != item.category),
    ];
    return _GlassCardShell(
      style: style,
      hasImage: hasImage,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShareScope(
            controller: controller,
            child: DetailPage(itemId: item.id),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(child: _PlatformGlassTint(style: style)),
            Positioned(
              right: -42,
              bottom: -34,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.color.withValues(alpha: 0.075),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hasImage
                    ? _CardMediaHeader(
                        imageUrl: imageUrl,
                        item: item,
                        style: style,
                        showPlay: isVideo,
                        contentIcon: contentIcon,
                        onImageError: () =>
                            controller.refreshCover(item, force: true),
                      )
                    : _GeneratedCardBanner(
                        item: item,
                        style: style,
                        contentIcon: contentIcon,
                      ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _ink.withValues(alpha: 0.78),
                          height: 1.38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in tags.take(4))
                            _TinyTag(
                              label: tag,
                              icon: tag == item.category
                                  ? contentIcon
                                  : Icons.tag,
                              color: style.color,
                            ),
                          if (tags.length > 4)
                            _TinyTag(
                              label: '+${tags.length - 4}',
                              icon: Icons.more_horiz,
                              color: _mutedInk,
                            ),
                          if (item.status != 'active')
                            _TinyTag(
                              label: _statusLabel(item.status),
                              icon: _statusIcon(item.status),
                              color: _mutedInk,
                            ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      _CardFooter(item: item),
                    ],
                  ),
                ),
              ],
            ),
            Positioned.fill(child: _GlassSpecularOverlay(style: style)),
          ],
        ),
      ),
    );
  }
}

class _GlassCardShell extends StatelessWidget {
  const _GlassCardShell({
    required this.style,
    required this.hasImage,
    required this.onTap,
    required this.child,
  });

  final PlatformStyle style;
  final bool hasImage;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: _CardAtmosphere(style: style, hasImage: hasImage),
          ),
        ),
        GlassPanel(
          padding: EdgeInsets.zero,
          radius: 30,
          blurSigma: 10,
          color: _creamSurface.withValues(alpha: 0.9),
          borderColor: Colors.white.withValues(alpha: 0.74),
          onTap: onTap,
          child: child,
        ),
      ],
    );
  }
}

class _CardAtmosphere extends StatelessWidget {
  const _CardAtmosphere({required this.style, required this.hasImage});

  final PlatformStyle style;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE7D9BD).withValues(alpha: 0.6),
              style.softColor.withValues(alpha: hasImage ? 0.34 : 0.46),
              const Color(0xFFFFE1BA).withValues(alpha: 0.3),
              style.color.withValues(alpha: hasImage ? 0.12 : 0.2),
            ],
            stops: const [0, 0.42, 0.7, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -54,
              top: -42,
              child: _AtmosphereOrb(
                size: 170,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            Positioned(
              left: -48,
              bottom: -58,
              child: _AtmosphereOrb(
                size: 168,
                color: style.color.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: _AtmosphereOrb(
                size: 92,
                color: const Color(0xFFECA88E).withValues(alpha: 0.18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtmosphereOrb extends StatelessWidget {
  const _AtmosphereOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _GlassSpecularOverlay extends StatelessWidget {
  const _GlassSpecularOverlay({required this.style, this.radius = 30});

  final PlatformStyle style;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.34),
              Colors.white.withValues(alpha: 0.02),
              style.color.withValues(alpha: 0.025),
            ],
            stops: const [0, 0.46, 1],
          ),
        ),
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.item});

  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    final source = (item.author ?? '').trim().isEmpty
        ? item.platform
        : item.author!.trim();
    return Row(
      children: [
        Expanded(
          child: Text(
            source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 15, color: _mutedInk),
            const SizedBox(width: 4),
            Text(
              DateFormat('MM-dd HH:mm').format(item.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _mutedInk,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, color: _mutedInk, size: 22),
          ],
        ),
      ],
    );
  }
}

class _PlatformGlassTint extends StatelessWidget {
  const _PlatformGlassTint({required this.style});

  final PlatformStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            _creamSurface.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.08),
            style.color.withValues(alpha: 0.025),
          ],
          stops: const [0, 0.36, 0.74, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.78, -0.88),
            radius: 1.08,
            colors: [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
