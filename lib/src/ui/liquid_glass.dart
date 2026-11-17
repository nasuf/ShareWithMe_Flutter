part of '../../main.dart';

// Liquid glass surfaces (design E): a translucent fill that brightens toward
// the top-left, a hairline rim, a specular highlight along the top edge and a
// soft drop shadow. Colors are read from AppTokens so both light and dark
// themes get the right rim and shadow. Real-time blur is reserved for floating
// chrome (tab bar, buttons, sheets); list rows skip the backdrop filter so
// scrolling stays cheap.

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.blur = 26,
    this.opacity = 0.62,
    this.dark = false,
    this.shadow = true,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final double radius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  /// Backdrop blur sigma; 0 draws the glass look without sampling the backdrop.
  final double blur;

  /// Strength of the white (or dark) fill at its brightest corner.
  final double opacity;
  final bool dark;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shape = borderRadius ?? BorderRadius.circular(radius);
    // 深色模式：无论 dark 参数如何，主题深色时都使用 glassFill 而非纯白，
    // 并将不透明度拉到 0.88+ 才能与深色背景拉开层次。
    final isDark = dark || t.brightness == Brightness.dark;
    final base = isDark ? t.glassFill : Colors.white;
    final rim = isDark ? Colors.white.withValues(alpha: 0.22) : t.glassRim;
    final effectiveOpacity = isDark ? opacity.clamp(0.82, 1.0) : opacity;
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: effectiveOpacity),
            base.withValues(alpha: effectiveOpacity * 0.75),
          ],
        ),
        border: Border.all(color: rim, width: 0.8),
      ),
      child: Stack(
        children: [
          Padding(padding: padding, child: child),
          // Specular highlight hugging the top edge.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 1.2,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: isDark ? 0.35 : 0.95),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      surface = Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: shape, onTap: onTap, child: surface),
      );
    }
    surface = ClipRRect(
      borderRadius: shape,
      child: blur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: surface,
            )
          : surface,
    );
    if (!shadow) {
      return surface;
    }
    final shadowColor = context.tokens.glassShadow;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: isDark ? 0.4 : 0.13),
            blurRadius: 32,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: surface,
    );
  }
}

/// A round glass button (44pt hit target and up).
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.onImage = false,
    this.foreground,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  /// Placed over a photo: a darker, more transparent glass with white glyphs.
  final bool onImage;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = foreground ?? (onImage ? Colors.white : t.ink);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: SizedBox.square(
          dimension: size,
          child: LiquidGlass(
            radius: size / 2,
            blur: 20,
            opacity: onImage ? 0.26 : 0.66,
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon,
                size: size * 0.47,
                color: onPressed == null ? color.withValues(alpha: 0.4) : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The screen backdrop: a cover photo blown up and blurred under a light veil,
/// so the whole page takes its tint from the content. Falls back to a soft
/// neutral gradient while there is no image.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({
    super.key,
    required this.imageUrls,
    required this.child,
    this.veil = 0.6,
  });

  /// One URL fills the screen; several are tiled as a mosaic before blurring.
  final List<String> imageUrls;
  final Widget child;
  final double veil;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final urls = imageUrls.where((url) => url.isNotEmpty).take(9).toList();
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: t.backdropGradient,
            ),
          ),
        ),
        if (urls.isNotEmpty)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: urls.length == 1
                    ? _BackdropImage(key: ValueKey(urls.first), url: urls.first)
                    : ImageFiltered(
                        key: ValueKey(urls.join('|')),
                        imageFilter: ImageFilter.blur(
                          sigmaX: 24,
                          sigmaY: 24,
                          tileMode: TileMode.mirror,
                        ),
                        child: _BackdropMosaic(urls: urls),
                      ),
              ),
            ),
          ),
        Positioned.fill(
          child: ColoredBox(
            // 深色模式下直接用 backdropVeilAlpha，不再乘以 veil，
            // 否则 0.6 × 0.82 = 0.49 根本压不住彩色 blur 背景。
            color: t.backdropVeil.withValues(
              alpha: t.brightness == Brightness.dark
                  ? t.backdropVeilAlpha
                  : veil * t.backdropVeilAlpha,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackdropImage extends StatelessWidget {
  const _BackdropImage({super.key, required this.url, this.cacheWidth = 32});

  final String url;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

class _BackdropMosaic extends StatelessWidget {
  const _BackdropMosaic({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[];
    for (var index = 0; index < urls.length; index += 3) {
      rows.add(urls.sublist(index, (index + 3).clamp(0, urls.length)));
    }
    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                for (final url in row)
                  Expanded(child: _BackdropImage(url: url, cacheWidth: 24)),
              ],
            ),
          ),
      ],
    );
  }
}

/// The frosted band behind pinned chrome (the library's folder bar and the
/// status bar above it); `progress` fades it in.
class FrostedStrip extends StatelessWidget {
  const FrostedStrip({super.key, required this.progress, this.divider = false});

  final double progress;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) {
      return const SizedBox.shrink();
    }
    final t = context.tokens;
    final dark = t.brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22 * progress, sigmaY: 22 * progress),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: (dark ? 0.86 : 0.78) * progress),
            border: divider
                ? Border(
                    bottom: BorderSide(
                      color: t.line.withValues(alpha: t.line.a * progress),
                      width: 0.5,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// `11月9日 星期一`, without needing intl's locale data.
String _chineseDateLabel(DateTime date) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${date.month}月${date.day}日 星期${weekdays[date.weekday - 1]}';
}

TextStyle _largeTitleStyle(BuildContext context) {
  final t = context.tokens;
  return Theme.of(context).textTheme.headlineMedium!.copyWith(
    color: t.ink,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.1,
  );
}

TextStyle _eyebrowStyle(BuildContext context) {
  final t = context.tokens;
  return Theme.of(context).textTheme.labelLarge!.copyWith(
    color: t.mutedInk,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}

/// A frosted bottom-sheet body that drags as one piece.
///
/// Pulling down while the content is scrolled to its top moves the whole
/// panel (content and glass together); letting go far or fast enough closes
/// the sheet, otherwise it springs back. Open it with `enableDrag: false` so
/// the route's own drag handling does not fight this one.
class GlassSheet extends StatefulWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  State<GlassSheet> createState() => _GlassSheetState();
}

class _GlassSheetState extends State<GlassSheet>
    with SingleTickerProviderStateMixin {
  static const _closeDistance = 110.0;
  static const _closeVelocity = 700.0;

  final scroll = ScrollController();
  late final AnimationController settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addListener(_onSettle);
  double drag = 0;
  double settleFrom = 0;
  int? pointer;
  VelocityTracker? tracker;
  bool closing = false;

  @override
  void dispose() {
    settle.dispose();
    scroll.dispose();
    super.dispose();
  }

  bool get _atTop =>
      !scroll.hasClients ||
      scroll.position.pixels <= scroll.position.minScrollExtent + 0.5;

  void _onSettle() {
    setState(() {
      drag = settleFrom * (1 - Curves.easeOutCubic.transform(settle.value));
    });
  }

  void _onDown(PointerDownEvent event) {
    if (pointer != null || closing) return;
    pointer = event.pointer;
    settle.stop();
    tracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _onMove(PointerMoveEvent event) {
    if (event.pointer != pointer || closing) return;
    tracker?.addPosition(event.timeStamp, event.position);
    final dy = event.delta.dy;
    if (drag > 0 || (dy > 0 && _atTop)) {
      setState(() => drag = (drag + dy).clamp(0.0, double.infinity));
    }
  }

  void _onUp(PointerEvent event) {
    if (event.pointer != pointer) return;
    pointer = null;
    final velocity = tracker?.getVelocity().pixelsPerSecond.dy ?? 0;
    tracker = null;
    if (drag <= 0) return;
    if (drag > _closeDistance || velocity > _closeVelocity) {
      closing = true;
      Navigator.of(context).maybePop();
    } else {
      settleFrom = drag;
      settle.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Listener(
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: Transform.translate(
        offset: Offset(0, drag),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.sheetFill.withValues(alpha: t.brightness == Brightness.dark ? 0.88 : 0.82),
                border: Border(
                  top: BorderSide(color: t.sheetBorder),
                ),
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  controller: scroll,
                  physics: drag > 0
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  padding: widget.padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 5,
                          decoration: BoxDecoration(
                            color: t.ink.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      widget.child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassMenuItem<T> {
  const GlassMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
    this.groupStart = false,
  });

  final T value;
  final String label;
  final IconData icon;
  final bool destructive;

  /// Draws a group separator above this item.
  final bool groupStart;
}

/// An iOS-style glass context menu that grows out of [anchorContext].
Future<T?> showGlassMenu<T>({
  required BuildContext anchorContext,
  required List<GlassMenuItem<T>> items,
}) {
  final navigator = Navigator.of(anchorContext);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final anchor = anchorContext.findRenderObject()! as RenderBox;
  final rect = MatrixUtils.transformRect(
    anchor.getTransformTo(overlay),
    Offset.zero & anchor.size,
  );
  final screen = overlay.size;
  // Grow from the anchor's bottom-right corner.
  final origin = Alignment(
    rect.right / screen.width * 2 - 1,
    rect.bottom / screen.height * 2 - 1,
  );
  return showGeneralDialog<T>(
    context: anchorContext,
    barrierDismissible: true,
    barrierLabel: '关闭菜单',
    barrierColor: anchorContext.tokens.ink.withValues(alpha: 0.06),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, _, _) => Stack(
      children: [
        Positioned(
          top: rect.bottom + 8,
          right: screen.width - rect.right,
          child: _GlassMenu<T>(items: items),
        ),
      ],
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      // Scale only: fading would put the glass in a translucent layer
      // where its backdrop blur samples nothing and shows dark.
      return ScaleTransition(
        alignment: origin,
        scale: Tween(begin: 0.15, end: 1.0).animate(curved),
        child: child,
      );
    },
  );
}

class _GlassMenu<T> extends StatelessWidget {
  const _GlassMenu({required this.items});

  final List<GlassMenuItem<T>> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: LiquidGlass(
        radius: 22,
        blur: 30,
        opacity: 0.84,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items) ...[
                if (item.groupStart && item != items.first)
                  Container(
                    height: 7,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: context.tokens.ink.withValues(alpha: 0.05),
                  ),
                _GlassMenuRow<T>(item: item),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassMenuRow<T> extends StatelessWidget {
  const _GlassMenuRow({required this.item});

  final GlassMenuItem<T> item;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = item.destructive ? const Color(0xFFE5484D) : t.ink;
    return InkWell(
      onTap: () => Navigator.of(context).pop(item.value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(item.icon, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}
