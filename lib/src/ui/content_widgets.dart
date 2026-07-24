part of '../../main.dart';

class OriginalContentView extends StatelessWidget {
  const OriginalContentView({
    super.key,
    required this.item,
    required this.backendUrl,
  });

  final LinkItem item;
  final String backendUrl;

  @override
  Widget build(BuildContext context) {
    final blocks = item.originalContent.blocks;
    final referencedUrls = blocks
        .map((block) => block.url?.trim())
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toSet();
    final additionalMedia = item.media
        .where(
          (asset) =>
              asset.kind == 'image' &&
              asset.url.trim().isNotEmpty &&
              !referencedUrls.contains(asset.url.trim()),
        )
        .take(6)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (blocks.isEmpty)
          SelectableText(
            _originalTextFor(item),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.55),
          )
        else
          for (var index = 0; index < blocks.length; index++) ...[
            _ContentBlockView(
              block: blocks[index],
              imageUrl: _imageUrlFor(blocks[index]),
            ),
            if (index != blocks.length - 1) const SizedBox(height: 12),
          ],
        if (additionalMedia.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (var index = 0; index < additionalMedia.length; index++) ...[
            _OriginalMediaView(
              asset: additionalMedia[index],
              backendUrl: backendUrl,
              preferPortrait: _prefersPortraitMedia(item.platform),
            ),
            if (index != additionalMedia.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  String? _imageUrlFor(ContentBlock block) {
    final sourceUrl = block.url?.trim();
    if (sourceUrl == null || sourceUrl.isEmpty) {
      return null;
    }
    final media = item.media
        .where((asset) => asset.url == sourceUrl)
        .firstOrNull;
    final preferred = media?.cachedUrl ?? sourceUrl;
    return resolveBackendMediaUrl(backendUrl, preferred);
  }
}

class _OriginalMediaView extends StatelessWidget {
  const _OriginalMediaView({
    required this.asset,
    required this.backendUrl,
    required this.preferPortrait,
  });

  final MediaAsset asset;
  final String backendUrl;
  final bool preferPortrait;

  @override
  Widget build(BuildContext context) {
    final source = (asset.cachedUrl ?? asset.url).trim();
    if (source.isEmpty) {
      return const SizedBox.shrink();
    }
    final width = asset.width?.toDouble();
    final height = asset.height?.toDouble();
    final ratio = width != null && height != null && width > 0 && height > 0
        ? (width / height).clamp(0.65, 1.9)
        : preferPortrait
        ? 4 / 5
        : 16 / 9;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: ratio,
        child: Image.network(
          resolveBackendMediaUrl(backendUrl, source),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: Colors.white.withValues(alpha: 0.34),
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        ),
      ),
    );
  }
}

bool _prefersPortraitMedia(String platform) {
  return const {'小红书', 'Instagram', '抖音'}.contains(platform);
}

class SourceSnapshotView extends StatelessWidget {
  const SourceSnapshotView({super.key, required this.item});

  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    final extraction = item.extraction;
    final status = _extractionStatusStyle(extraction.status);
    final fetchedAt = extraction.fetchedAt;
    final facts = item.sourceFacts
        .where((fact) => fact.key != 'content_kind')
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(status.icon, size: 19, color: status.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${extraction.completeness}%',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        if (fetchedAt != null) ...[
          const SizedBox(height: 6),
          Text(
            '更新于 ${DateFormat('MM-dd HH:mm').format(fetchedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final fact in facts) ...[
            _FactRow(fact: fact),
            if (fact != facts.last) const Divider(height: 18),
          ],
        ],
        if ((extraction.lastError ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            extraction.lastError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _ContentBlockView extends StatelessWidget {
  const _ContentBlockView({required this.block, required this.imageUrl});

  final ContentBlock block;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (block.kind) {
      case 'heading':
        final level = block.level ?? 2;
        return SelectableText(
          block.text,
          style:
              (level <= 2
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(height: 1.28, fontWeight: FontWeight.w800),
        );
      case 'quote':
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: _mint, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: SelectableText(
              block.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      case 'list-item':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 8, right: 10),
              decoration: const BoxDecoration(
                color: _ink,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: SelectableText(
                block.text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ],
        );
      case 'code':
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            block.text,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              fontFamily: 'Menlo',
            ),
          ),
        );
      case 'image':
        final url = imageUrl;
        if (url == null || url.isEmpty) {
          return const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        );
      case 'link':
        final url = block.url?.trim() ?? '';
        final label = block.text.trim().isEmpty ? '打开链接' : block.text.trim();
        if (url.isEmpty) {
          return SelectableText(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
          );
        }
        return _LinkBlockTile(text: label, url: url);
      default:
        return SelectableText(
          block.text,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
        );
    }
  }
}

class _LinkBlockTile extends StatelessWidget {
  const _LinkBlockTile({required this.text, required this.url});

  final String text;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: _mint.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _confirmAndOpen(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: _mint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: _ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, size: 15, color: _mutedInk),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndOpen(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('即将前往微信打开此内容，使用完整服务。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('前往'),
          ),
        ],
      ),
    );
    if (proceed != true) {
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final SourceFact fact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(fact.label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: SelectableText(
            fact.value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

({String label, IconData icon, Color color}) _extractionStatusStyle(
  String status,
) {
  return switch (status) {
    'complete' => (
      label: '原文快照已保存',
      icon: Icons.verified_outlined,
      color: _mint,
    ),
    'partial' => (label: '已保存部分公开内容', icon: Icons.adjust, color: _mutedInk),
    'blocked' => (
      label: '平台限制访问',
      icon: Icons.lock_outline,
      color: Color(0xFFE35B52),
    ),
    'stale' => (label: '保留上次完整快照', icon: Icons.history, color: _mutedInk),
    _ => (label: '等待首次内容刷新', icon: Icons.sync, color: _mutedInk),
  };
}
