part of '../../main.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  bool loadingMissingItem = false;
  bool requestedMissingItem = false;
  bool requestedFreshness = false;
  // 0 while the cover is visible, 1 once the sheet has scrolled under the top
  // buttons; drives the top fade and the buttons' on-image style.
  final ValueNotifier<double> scrolledUnder = ValueNotifier(0);
  // 0 with the sheet resting under the cover, 1 once it has been pulled up to
  // the top: the cover blurs and zooms, the sheet widens to the screen edges.
  final ValueNotifier<double> sheetRaised = ValueNotifier(0);
  // 0 at rest, 1 once the page has been pulled down far enough to close;
  // the whole page shrinks into a card that follows the finger.
  final ValueNotifier<double> pullDismiss = ValueNotifier(0);
  late final AnimationController exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  bool dismissing = false;

  static const _pullDistance = 170.0;
  static const _pullToClose = 0.45;

  @override
  void dispose() {
    scrolledUnder.dispose();
    sheetRaised.dispose();
    pullDismiss.dispose();
    exit.dispose();
    super.dispose();
  }

  void _trackPull(double pixels) {
    if (dismissing) return;
    final pull = ((-pixels) / _pullDistance).clamp(0.0, 1.0);
    if (pull == pullDismiss.value) return;
    pullDismiss.value = pull;
    final route = ModalRoute.of(context);
    if (route is _DetailRoute) {
      // Let the library show through around the shrinking card.
      route.revealPrevious(pull > 0);
    }
  }

  Future<void> _maybeDismiss() async {
    if (dismissing || pullDismiss.value < _pullToClose) return;
    dismissing = true;
    unawaited(HapticFeedback.lightImpact());
    await exit.forward();
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route is _DetailRoute) {
      route.popInstantly();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ShareScope.of(context);
    if (!requestedMissingItem && controller.itemById(widget.itemId) == null) {
      requestedMissingItem = true;
      loadingMissingItem = true;
      unawaited(_loadMissingItem(controller));
    }
    final item = controller.itemById(widget.itemId);
    if (!requestedFreshness && item != null) {
      requestedFreshness = true;
      unawaited(controller.ensureFresh(item));
    }
    // List rows carry no article text; load it (re-runs when a newer slim
    // row replaces the full copy).
    if (item != null && item.contentOmitted) {
      unawaited(controller.ensureFullItem(item.id));
    }
  }

  Future<void> _loadMissingItem(ShareController controller) async {
    final item = await controller.loadItem(widget.itemId);
    if (item != null && !requestedFreshness) {
      requestedFreshness = true;
      unawaited(controller.ensureFresh(item));
    }
    if (mounted) {
      setState(() => loadingMissingItem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShareScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final item = controller.itemById(widget.itemId);
        if (item == null) {
          return Scaffold(
            backgroundColor: _surface,
            body: GlassBackground(
              child: Center(
                child: loadingMissingItem
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('内容已不存在'),
              ),
            ),
          );
        }
        final coverUrl = _coverUrl(controller, item);
        final hasCover = coverUrl.isNotEmpty;
        final topInset = MediaQuery.paddingOf(context).top;
        final heroHeight = hasCover
            ? (MediaQuery.sizeOf(context).height * 0.56).clamp(320.0, 560.0)
            : 0.0;
        return Listener(
          onPointerUp: (_) => _maybeDismiss(),
          onPointerCancel: (_) => _maybeDismiss(),
          child: AnimatedBuilder(
            animation: Listenable.merge([pullDismiss, exit]),
            builder: (context, page) {
              final pull = pullDismiss.value;
              final leaving = Curves.easeInCubic.transform(exit.value);
              final scale = (1 - 0.14 * pull) * (1 - 0.1 * leaving);
              // Always clipped: the raised cover is scaled past the screen
              // edges and would otherwise trail beside the page on swipe-back.
              // Keep the wrapper chain fixed: inserting a widget mid-drag
              // would remount the page and cancel the scroll gesture.
              return Opacity(
                opacity: 1 - leaving,
                child: Transform.scale(
                  scale: scale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      44 * (pull * 4).clamp(0.0, 1.0),
                    ),
                    child: page,
                  ),
                ),
              );
            },
            child: Scaffold(
              backgroundColor: _surface,
              body: GlassBackground(
                imageUrls: hasCover ? [coverUrl] : const [],
                child: Stack(
                  children: [
                    if (hasCover)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: heroHeight,
                        child: ValueListenableBuilder<double>(
                          valueListenable: sheetRaised,
                          builder: (context, raised, hero) {
                            final blur = 22 * raised;
                            return Transform.scale(
                              scale: 1 + 0.18 * raised,
                              alignment: Alignment.topCenter,
                              child: blur < 0.2
                                  ? hero
                                  : ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: blur,
                                        sigmaY: blur,
                                        tileMode: TileMode.clamp,
                                      ),
                                      child: hero,
                                    ),
                            );
                          },
                          // Fade the cover's bottom edge into the backdrop so
                          // no hard seam shows through the raised sheet.
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Color(0x00FFFFFF)],
                              stops: [0.82, 1],
                            ).createShader(rect),
                            child: _DetailHero(
                              url: coverUrl,
                              item: item,
                              onError: () =>
                                  controller.refreshCover(item, force: true),
                            ),
                          ),
                        ),
                      ),
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.depth == 0) {
                          _trackPull(notification.metrics.pixels);
                          final restingTop = hasCover
                              ? heroHeight - 64
                              : topInset + 68;
                          final sheetTop =
                              restingTop - notification.metrics.pixels;
                          final travel = (restingTop - topInset).clamp(
                            1.0,
                            2000.0,
                          );
                          sheetRaised.value =
                              (notification.metrics.pixels / travel).clamp(
                                0.0,
                                1.0,
                              );
                          scrolledUnder.value =
                              ((topInset + 76 - sheetTop) / 40).clamp(0.0, 1.0);
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: hasCover
                                  ? heroHeight - 64
                                  : topInset + 68,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _DetailWidth(
                              child: _DetailSheet(
                                controller: controller,
                                item: item,
                                raised: sheetRaised,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 110),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<double>(
                      valueListenable: scrolledUnder,
                      builder: (context, progress, _) => Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: topInset + 76,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: progress,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        _surface.withValues(alpha: 0.96),
                                        _surface.withValues(alpha: 0.85),
                                        _surface.withValues(alpha: 0),
                                      ],
                                      stops: const [0, 0.7, 1],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            top: topInset + 6,
                            child: _DetailTopBar(
                              controller: controller,
                              item: item,
                              onImage: hasCover && progress < 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: _DetailActionBar(
                            controller: controller,
                            item: item,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The detail page's route: the iOS slide and back-swipe, but the library
/// underneath stays put (no parallax), so it can show through around the
/// page while the page is pulled down to close.
class _DetailRoute<T> extends PageRoute<T> {
  _DetailRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => CupertinoRouteTransitionMixin.buildPageTransitions(
    this,
    context,
    animation,
    secondaryAnimation,
    child,
  );

  /// Paints the route below while the page is not covering the screen.
  void revealPrevious(bool reveal) {
    if (overlayEntries.isEmpty || !(animation?.isCompleted ?? false)) return;
    overlayEntries.first.opaque = !reveal;
  }

  /// Pops without the slide-out, for when the page has already animated
  /// itself away.
  void popInstantly() {
    controller?.reverseDuration = Duration.zero;
    navigator?.pop();
  }
}
