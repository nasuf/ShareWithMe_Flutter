part of '../../main.dart';

// Three ways to look at a saved item:
//   1. Reader mode (OriginalContentView): the structured snapshot, always
//      available offline and after the link dies.
//   2. SourceWebPage: the live page in an in-app WebView, for the exact
//      original layout, comments and video.
//   3. ArchiveSnapshotPage: the screenshot taken when the item was saved, for
//      the original layout once the live page is gone.

// Pushed routes sit outside the ShareScope of the page that opened them, so
// they re-provide it (same pattern as the detail page).
void openSourceWebPage(BuildContext context, LinkItem item) {
  final controller = ShareScope.of(context);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ShareScope(
        controller: controller,
        child: SourceWebPage(itemId: item.id),
      ),
    ),
  );
}

void openArchiveSnapshot(BuildContext context, LinkItem item) {
  final controller = ShareScope.of(context);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ShareScope(
        controller: controller,
        child: ArchiveSnapshotPage(itemId: item.id),
      ),
    ),
  );
}

void openImageViewer(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => _ImageViewerPage(imageUrl: imageUrl),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class SourceWebPage extends StatefulWidget {
  const SourceWebPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<SourceWebPage> createState() => _SourceWebPageState();
}

class _SourceWebPageState extends State<SourceWebPage> {
  WebViewController? webController;
  Uri? sourceUri;
  int progress = 0;
  String? loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (webController != null) {
      return;
    }
    final item = ShareScope.of(context).itemById(widget.itemId);
    final uri = item == null ? null : Uri.tryParse(item.finalUrl);
    if (uri == null || !uri.hasScheme) {
      loadError = '链接格式无效';
      return;
    }
    sourceUri = uri;
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => progress = value);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => loadError = null);
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? true) && mounted) {
              setState(() => loadError = error.description);
            }
          },
          // Pages often try to bounce into their native app (snssdk://,
          // weixin://...). Stay in the WebView instead of failing on them.
          onNavigationRequest: (request) {
            final scheme = Uri.tryParse(request.url)?.scheme ?? '';
            return scheme == 'http' || scheme == 'https'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    final item = ShareScope.of(context).itemById(widget.itemId);
    final controller = webController;
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        title: Text(
          sourceUri?.host ?? '原网页',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        actions: [
          if (controller != null)
            IconButton(
              tooltip: '刷新',
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.reload(),
            ),
          if (sourceUri != null)
            IconButton(
              tooltip: '在浏览器中打开',
              icon: const Icon(Icons.open_in_browser),
              onPressed: () =>
                  launchUrl(sourceUri!, mode: LaunchMode.externalApplication),
            ),
        ],
        bottom: progress > 0 && progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          if (controller != null) WebViewWidget(controller: controller),
          if (loadError != null)
            Positioned.fill(
              child: ColoredBox(
                color: _surface,
                child: _SourceUnavailable(
                  message: loadError!,
                  hasArchive: item?.archive != null,
                  onRetry: controller == null
                      ? null
                      : () {
                          setState(() => loadError = null);
                          controller.reload();
                        },
                  onOpenArchive: item == null
                      ? null
                      : () => openArchiveSnapshot(context, item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceUnavailable extends StatelessWidget {
  const _SourceUnavailable({
    required this.message,
    required this.hasArchive,
    required this.onRetry,
    required this.onOpenArchive,
  });

  final String message;
  final bool hasArchive;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_rounded, size: 40, color: _mutedInk),
            const SizedBox(height: 12),
            Text('原网页暂时无法打开', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              hasArchive ? '可以查看保存时的存档快照。' : message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: _mutedInk),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (hasArchive && onOpenArchive != null)
                  FilledButton.icon(
                    onPressed: onOpenArchive,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('查看存档快照'),
                  ),
                if (onRetry != null)
                  OutlinedButton(onPressed: onRetry, child: const Text('重试')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ArchiveSnapshotPage extends StatefulWidget {
  const ArchiveSnapshotPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<ArchiveSnapshotPage> createState() => _ArchiveSnapshotPageState();
}

class _ArchiveSnapshotPageState extends State<ArchiveSnapshotPage> {
  final transform = TransformationController();
  String? fittedForUrl;
  bool capturing = false;

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  Future<void> _capture(ShareController controller, LinkItem item) async {
    setState(() => capturing = true);
    final error = await controller.captureArchive(item);
    if (!mounted) return;
    setState(() => capturing = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShareScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final item = controller.itemById(widget.itemId);
        final archive = item?.archive;
        return Scaffold(
          backgroundColor: _surface,
          appBar: AppBar(
            backgroundColor: _surface,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('存档快照', style: Theme.of(context).textTheme.titleSmall),
                if (archive != null)
                  Text(
                    '保存于 ${DateFormat('yyyy-MM-dd HH:mm').format(archive.capturedAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _mutedInk),
                  ),
              ],
            ),
            actions: [
              if (item != null && archive != null)
                capturing
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: '从原网页重新生成',
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _capture(controller, item),
                      ),
            ],
          ),
          body: item == null
              ? const Center(child: Text('内容已不存在'))
              : archive == null
              ? _EmptyArchive(
                  capturing: capturing,
                  onCapture: () => _capture(controller, item),
                )
              : _buildViewer(controller.api.baseUrl, archive),
        );
      },
    );
  }

  // Pan + pinch-zoom over the full-resolution screenshot, starting fitted to
  // the screen width and scrolled to the top.
  Widget _buildViewer(String backendUrl, ArchiveSnapshot archive) {
    final imageUrl = resolveBackendMediaUrl(backendUrl, archive.url);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = constraints.maxWidth / archive.width;
        final fitted = Matrix4.diagonal3Values(fit, fit, 1);
        if (fittedForUrl != imageUrl) {
          fittedForUrl = imageUrl;
          transform.value = fitted;
        }
        // Double-tap returns to the fitted, top-of-article view.
        return GestureDetector(
          onDoubleTap: () => transform.value = fitted,
          child: _archiveViewer(imageUrl, archive, fit),
        );
      },
    );
  }

  Widget _archiveViewer(String imageUrl, ArchiveSnapshot archive, double fit) {
    return Builder(
      builder: (context) {
        return InteractiveViewer(
          transformationController: transform,
          constrained: false,
          minScale: fit,
          maxScale: fit * 4,
          boundaryMargin: EdgeInsets.zero,
          child: SizedBox(
            width: archive.width.toDouble(),
            height: archive.height.toDouble(),
            child: Image.network(
              imageUrl,
              fit: BoxFit.fill,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (_, _, _) => const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Text('存档图片加载失败'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive({required this.capturing, required this.onCapture});

  final bool capturing;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 40,
              color: _mutedInk,
            ),
            const SizedBox(height: 12),
            Text('还没有存档快照', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '存档会在收藏后自动生成，保留原文当时的排版。\n也可以现在从原网页生成一份（约需 20 秒）。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _mutedInk,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: capturing ? null : onCapture,
              icon: capturing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(capturing ? '正在生成…' : '立即生成存档'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageViewerPage extends StatelessWidget {
  const _ImageViewerPage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox.expand(
          child: InteractiveViewer(
            maxScale: 5,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
