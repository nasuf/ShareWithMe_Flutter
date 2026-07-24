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
              backgroundColor: Colors.transparent,
              extendBody: true,
              body: GlassBackground(
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      if (wide) _ReferenceRail(controller: controller),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0.035, 0),
                              end: Offset.zero,
                            ).animate(animation);
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
              floatingActionButton: wide || controller.tabIndex != 0
                  ? null
                  : _CollectFab(controller: controller),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              bottomNavigationBar: wide
                  ? null
                  : SafeArea(
                      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      child: _ReferenceBottomNav(controller: controller),
                    ),
            );
          },
        );
      },
    );
  }
}

class _ReferenceBottomNav extends StatelessWidget {
  const _ReferenceBottomNav({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.96)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF263445).withValues(alpha: 0.14),
                blurRadius: 34,
                spreadRadius: -12,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              _ReferenceNavItem(
                selected: controller.tabIndex == 0,
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                label: '资料库',
                onTap: () => controller.selectTab(0),
              ),
              _ReferenceNavItem(
                selected: controller.tabIndex == 1,
                icon: Icons.query_stats_outlined,
                selectedIcon: Icons.query_stats_rounded,
                label: '洞察',
                onTap: () => controller.selectTab(1),
              ),
              _ReferenceNavItem(
                selected: controller.tabIndex == 2,
                icon: Icons.tune_outlined,
                selectedIcon: Icons.tune_rounded,
                label: '设置',
                onTap: () => controller.selectTab(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceNavItem extends StatelessWidget {
  const _ReferenceNavItem({
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
    final color = selected ? _accent : _mutedInk;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.06 : 1,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          selected ? selectedIcon : icon,
                          size: 21,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: selected ? 20 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectFab extends StatelessWidget {
  const _CollectFab({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '收集链接',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: controller.analyzing
            ? null
            : () => showAddLinkSheet(context, controller),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: controller.analyzing ? _mutedInk : _mint,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.3),
                blurRadius: 25,
                spreadRadius: -7,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: controller.analyzing
              ? const Padding(
                  padding: EdgeInsets.all(19),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _ReferenceRail extends StatelessWidget {
  const _ReferenceRail({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 0, 18),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        radius: 28,
        child: SizedBox(
          width: 86,
          child: Column(
            children: [
              const Icon(Icons.bookmarks_rounded, color: _accent, size: 30),
              const SizedBox(height: 24),
              for (final destination in const [
                (0, Icons.menu_book_outlined, '资料库'),
                (1, Icons.query_stats_outlined, '洞察'),
                (2, Icons.tune_outlined, '设置'),
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
                            ? _accentSoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            destination.$2,
                            color: controller.tabIndex == destination.$1
                                ? _accent
                                : _mutedInk,
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
