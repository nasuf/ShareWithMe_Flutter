part of '../../main.dart';

class _LibraryFilterSheet extends StatelessWidget {
  const _LibraryFilterSheet({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return GlassSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '筛选资料',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: context.tokens.ink,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (controller.statusFilter != 'active') {
                        controller.setStatusFilter('active');
                      }
                      if (controller.sortMode != 'newest') {
                        controller.setSortMode('newest');
                      }
                      if (controller.category.isNotEmpty) {
                        controller.setCategory(controller.category);
                      }
                      if (controller.platform.isNotEmpty) {
                        controller.setPlatform(controller.platform);
                      }
                    },
                    child: const Text('恢复默认'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _FilterHeading('状态'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in const [
                    ('active', '资料库', Icons.menu_book_outlined),
                    ('favorite', '重要', Icons.star_outline),
                    ('archived', '归档', Icons.archive_outlined),
                    ('', '全部', Icons.all_inbox_outlined),
                  ])
                    ChoiceChip(
                      selected: controller.statusFilter == value.$1,
                      showCheckmark: false,
                      avatar: Icon(value.$3, size: 17, color: context.tokens.accent),
                      label: Text(value.$2),
                      labelStyle: TextStyle(
                        color: context.tokens.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => controller.setStatusFilter(value.$1),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              const _FilterHeading('排序'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in const [
                    ('newest', '最新', Icons.schedule),
                    ('oldest', '最早', Icons.history),
                    ('importance', '重要度', Icons.priority_high),
                  ])
                    ChoiceChip(
                      selected: controller.sortMode == value.$1,
                      showCheckmark: false,
                      avatar: Icon(value.$3, size: 17, color: context.tokens.accent),
                      label: Text(value.$2),
                      labelStyle: TextStyle(
                        color: context.tokens.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => controller.setSortMode(value.$1),
                    ),
                ],
              ),
              if ((stats?.categories ?? []).isNotEmpty) ...[
                const SizedBox(height: 22),
                const _FilterHeading('收藏夹'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final bucket in stats!.categories.take(10))
                      FilterChip(
                        selected: controller.category == bucket.label,
                        label: Text('${bucket.label} ${bucket.count}'),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: context.tokens.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => controller.setCategory(bucket.label),
                      ),
                  ],
                ),
              ],
              if ((stats?.platforms ?? []).isNotEmpty) ...[
                const SizedBox(height: 22),
                const _FilterHeading('来源平台'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final bucket in stats!.platforms.take(12))
                      FilterChip(
                        selected: controller.platform == bucket.label,
                        avatar: PlatformBrandMark(
                          platform: bucket.label,
                          size: 18,
                          flat: true,
                        ),
                        label: Text('${bucket.label} ${bucket.count}'),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: context.tokens.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => controller.setPlatform(bucket.label),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('完成'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterHeading extends StatelessWidget {
  const _FilterHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: context.tokens.ink,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

String? _firstUrlFromText(String text) {
  return RegExp(r'https?://[^\s，。、《》<>"]+').firstMatch(text)?.group(0);
}
