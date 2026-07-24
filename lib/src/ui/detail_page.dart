part of '../../main.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool loadingMissingItem = false;
  bool requestedMissingItem = false;
  bool requestedFreshness = false;

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
            backgroundColor: Colors.transparent,
            body: GlassBackground(
              child: Center(
                child: loadingMissingItem
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('内容已不存在'),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: _surface,
          body: GlassBackground(
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _DetailWidth(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                        child: _DetailTopBar(
                          controller: controller,
                          item: item,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _DetailWidth(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 124),
                        child: _DetailArticle(
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
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: _DetailActionBar(item: item),
          ),
        );
      },
    );
  }
}
