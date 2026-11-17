part of '../../main.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShareScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pages = [
          InboxPage(controller: controller),
          InsightsPage(controller: controller),
          SettingsPage(controller: controller),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Scaffold(
              backgroundColor: context.tokens.surface,
              body: Stack(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        if (wide) _ReferenceRail(controller: controller),
                        Expanded(
                          child: IndexedStack(
                            index: controller.tabIndex,
                            children: pages,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.tabIndex == 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: MediaQuery.paddingOf(context).top,
                      child: IgnorePointer(
                        child: ValueListenableBuilder<double>(
                          valueListenable: controller.libraryBarPinned,
                          builder: (context, pinned, _) =>
                              FrostedStrip(progress: pinned),
                        ),
                      ),
                    ),
                  if (!wide)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 12),
                        child: _GlassTabBar(controller: controller),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

String _coverUrl(ShareController controller, LinkItem item) =>
    resolveBackendMediaUrl(controller.api.baseUrl, item.imageUrl?.trim() ?? '');

/// The library's hero: the most important item with a cover from the last
/// week, else the newest item with a cover.
LinkItem? _featuredItem(ShareController controller) {
  final withCover = controller.items
      .where((item) => _coverUrl(controller, item).isNotEmpty)
      .toList();
  if (withCover.isEmpty) {
    return null;
  }
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final recent = withCover
      .where((item) => item.createdAt.isAfter(weekAgo))
      .toList();
  final pool = recent.isEmpty ? withCover : recent;
  return pool.reduce(
    (best, item) => item.importanceScore > best.importanceScore ? item : best,
  );
}

/// The floating tab bar. The selection is a glass droplet: press a tab and it
/// lifts off the bar, magnifying what is under it, follows the finger across
/// the tabs, and settles on release with a spring.
class _GlassTabBar extends StatefulWidget {
  const _GlassTabBar({required this.controller});

  final ShareController controller;

  @override
  State<_GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<_GlassTabBar>
    with TickerProviderStateMixin {
  static const _tabs = [
    (Icons.auto_stories_outlined, '资料库'),
    (Icons.insights_rounded, '洞察'),
    (Icons.settings_outlined, '设置'),
  ];
  static const _barHeight = 62.0;
  static const _inset = 5.0;
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 30,
  );

  /// Droplet position in tab units (0 = first tab), free to sit between tabs.
  late final AnimationController position = AnimationController.unbounded(
    vsync: this,
    value: widget.controller.tabIndex.toDouble(),
  );

  /// 0 resting in the bar, 1 lifted under the finger.
  late final AnimationController lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 320),
  );
  bool interacting = false;
  double slotWidth = 1;

  @override
  void dispose() {
    position.dispose();
    lift.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tab changed from elsewhere (search button, insight chips).
    final target = widget.controller.tabIndex.toDouble();
    if (!interacting && !position.isAnimating && position.value != target) {
      _settleTo(target, 0);
    }
  }

  double _slotAt(double dx) =>
      ((dx - _inset) / slotWidth - 0.5).clamp(0.0, _tabs.length - 1.0);

  void _settleTo(double target, double velocity) {
    position.animateWith(
      SpringSimulation(_spring, position.value, target, velocity),
    );
  }

  void _press(double dx) {
    interacting = true;
    position.stop();
    lift.forward();
    HapticFeedback.selectionClick();
  }

  void _drag(double dx) {
    final slot = _slotAt(dx);
    if (slot.round() != position.value.round()) {
      HapticFeedback.selectionClick();
    }
    position.value = slot;
  }

  void _release({double? toSlot, double velocity = 0}) {
    final target = (toSlot ?? position.value).round().clamp(
      0,
      _tabs.length - 1,
    );
    interacting = false;
    _settleTo(target.toDouble(), velocity);
    lift.reverse();
    if (target != widget.controller.tabIndex) {
      widget.controller.selectTab(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _barHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                slotWidth = (constraints.maxWidth - _inset * 2) / _tabs.length;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _press(d.localPosition.dx),
                  onTapUp: (d) => _release(toSlot: _slotAt(d.localPosition.dx)),
                  onTapCancel: () {
                    if (interacting) _release();
                  },
                  onHorizontalDragStart: (d) {
                    if (!interacting) _press(d.localPosition.dx);
                    _drag(d.localPosition.dx);
                  },
                  onHorizontalDragUpdate: (d) => _drag(d.localPosition.dx),
                  onHorizontalDragEnd: (d) => _release(
                    velocity: d.velocity.pixelsPerSecond.dx / slotWidth,
                  ),
                  onHorizontalDragCancel: () => _release(),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([position, lift]),
                    builder: (context, _) => _buildBar(constraints.maxWidth),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        GlassCircleButton(
          tooltip: '搜索收藏',
          icon: Icons.search_rounded,
          size: _barHeight,
          onPressed: widget.controller.openSearch,
        ),
      ],
    );
  }

  Widget _buildBar(double width) {
    final pos = position.value;
    final lifted = Curves.easeOut.transform(lift.value);
    final active = pos.round();
    final centerX = _inset + slotWidth * (pos + 0.5);
    final pillWidth = slotWidth;
    const pillHeight = _barHeight - _inset * 2;
    // The lifted droplet swells past the bar's edges.
    final dropWidth = pillWidth * (1 + 0.18 * lifted);
    final dropHeight = pillHeight * (1 + 0.42 * lifted);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: LiquidGlass(
            radius: _barHeight / 2,
            blur: 28,
            opacity: 0.7,
            child: Stack(
              children: [
                // Resting selection: a soft white pill under the labels.
                Positioned(
                  left: centerX - pillWidth / 2,
                  top: _inset,
                  width: pillWidth,
                  height: pillHeight,
                  child: Opacity(
                    opacity: 1 - lifted,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(pillHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: context.tokens.glassShadow.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(_inset),
                  child: Row(
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _GlassTabLabel(
                            icon: _tabs[i].$1,
                            label: _tabs[i].$2,
                            selected: i == active,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (lifted > 0.01)
          Positioned(
            left: centerX - dropWidth / 2,
            top: _barHeight / 2 - dropHeight / 2,
            width: dropWidth,
            height: dropHeight,
            child: IgnorePointer(child: _GlassDroplet(lift: lifted)),
          ),
      ],
    );
  }
}

/// The lifted lens: clear glass that magnifies whatever is beneath it.
class _GlassDroplet extends StatelessWidget {
  const _GlassDroplet({required this.lift});

  final double lift;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final radius = BorderRadius.circular(size.height / 2);
        final zoom = 1 + 0.22 * lift;
        final cx = size.width / 2;
        final cy = size.height / 2;
        final magnify = Matrix4.identity()
          ..translateByDouble(cx, cy, 0, 1)
          ..scaleByDouble(zoom, zoom, 1, 1)
          ..translateByDouble(-cx, -cy, 0, 1);
        // No Opacity here: it would isolate the BackdropFilter from the bar
        // beneath and the lens would flash dark. Fade the paint instead.
        final fade = lift.clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: context.tokens.glassShadow.withValues(alpha: 0.22 * fade),
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.matrix(magnify.storage),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.34 * fade),
                      Colors.white.withValues(alpha: 0.06 * fade),
                      Colors.white.withValues(alpha: 0.18 * fade),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95 * fade),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassTabLabel extends StatelessWidget {
  const _GlassTabLabel({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.accent : t.mutedInk;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceRail extends StatelessWidget {
  const _ReferenceRail({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 0, 18),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        radius: 28,
        child: SizedBox(
          width: 86,
          child: Column(
            children: [
              Icon(Icons.bookmarks_rounded, color: t.accent, size: 30),
              const SizedBox(height: 24),
              for (final destination in const [
                (0, Icons.auto_stories_outlined, '资料库'),
                (1, Icons.insights_rounded, '洞察'),
                (2, Icons.settings_outlined, '设置'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => controller.selectTab(destination.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: controller.tabIndex == destination.$1
                            ? t.glassFill.withValues(alpha: 0.8)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            destination.$2,
                            color: controller.tabIndex == destination.$1
                                ? t.accent
                                : t.mutedInk,
                          ),
                          const SizedBox(height: 4),
                          Text(destination.$3),
                        ],
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              IconButton.filled(
                tooltip: '收集链接',
                onPressed: controller.analyzing
                    ? null
                    : () => showAddLinkSheet(context, controller),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
