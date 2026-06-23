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
            final wide = constraints.maxWidth >= 860;
            return Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              body: GlassBackground(
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      if (wide) _GlassRail(controller: controller),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final slide =
                                Tween<Offset>(
                                  begin: const Offset(0.035, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                );
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(controller.tabIndex),
                            child: pages[controller.tabIndex],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: wide
                  ? null
                  : SafeArea(
                      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                      child: _GlassBottomNav(controller: controller),
                    ),
              floatingActionButton: controller.tabIndex == 0
                  ? _GlassAddButton(controller: controller)
                  : null,
            );
          },
        );
      },
    );
  }
}

class _GlassRail extends StatelessWidget {
  const _GlassRail({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 14),
        radius: 30,
        child: SizedBox(
          width: 96,
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Share\nWithMe',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const Spacer(),
              _RailButton(
                selected: controller.tabIndex == 0,
                icon: Icons.auto_stories_outlined,
                selectedIcon: Icons.auto_stories,
                label: '资料库',
                onTap: () => controller.selectTab(0),
              ),
              _RailButton(
                selected: controller.tabIndex == 1,
                icon: Icons.query_stats,
                selectedIcon: Icons.query_stats,
                label: '洞察',
                onTap: () => controller.selectTab(1),
              ),
              _RailButton(
                selected: controller.tabIndex == 2,
                icon: Icons.tune,
                selectedIcon: Icons.tune,
                label: '设置',
                onTap: () => controller.selectTab(2),
              ),
              const Spacer(),
              IconButton(
                tooltip: '刷新',
                onPressed: controller.loading ? null : controller.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _ink : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? Colors.white : _mutedInk,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? Colors.white : _mutedInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  const _GlassBottomNav({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(7),
      radius: 34,
      color: _creamSurface.withValues(alpha: 0.92),
      borderColor: Colors.white.withValues(alpha: 0.78),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 3;
          return SizedBox(
            height: 56,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: tabWidth * controller.tabIndex,
                  top: 0,
                  width: tabWidth,
                  height: 56,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _mint.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.38),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _warmShadow.withValues(alpha: 0.28),
                          blurRadius: 22,
                          spreadRadius: -5,
                          offset: const Offset(8, 12),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: -8,
                          offset: const Offset(-5, -6),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _BottomNavButton(
                      selected: controller.tabIndex == 0,
                      icon: Icons.auto_stories_outlined,
                      selectedIcon: Icons.auto_stories,
                      label: '资料库',
                      onTap: () => controller.selectTab(0),
                    ),
                    _BottomNavButton(
                      selected: controller.tabIndex == 1,
                      icon: Icons.query_stats,
                      selectedIcon: Icons.query_stats,
                      label: '洞察',
                      onTap: () => controller.selectTab(1),
                    ),
                    _BottomNavButton(
                      selected: controller.tabIndex == 2,
                      icon: Icons.tune,
                      selectedIcon: Icons.tune,
                      label: '设置',
                      onTap: () => controller.selectTab(2),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlassAddButton extends StatelessWidget {
  const _GlassAddButton({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: 28,
      color: _mint.withValues(alpha: 0.98),
      borderColor: Colors.white.withValues(alpha: 0.42),
      onTap: controller.analyzing
          ? null
          : () => showAddLinkSheet(context, controller),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Center(
          child: controller.analyzing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.add_link_rounded,
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  selected ? selectedIcon : icon,
                  key: ValueKey('$label-$selected'),
                  color: selected
                      ? Colors.white
                      : _mutedInk.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style:
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? Colors.white
                            : _mutedInk.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w900,
                      ) ??
                      const TextStyle(),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
