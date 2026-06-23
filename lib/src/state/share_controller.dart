part of '../../main.dart';

class ShareController extends ChangeNotifier {
  ShareController(this.api, {required this.settings});

  ApiClient api;
  final AppSettings settings;
  List<LinkItem> items = [];
  final Map<String, LinkItem> _itemCache = {};
  final Set<String> _coverRefreshesInFlight = {};
  final Set<String> _autoCoverRefreshesTried = {};
  CollectionStats? stats;
  CollectionDigest? digest;
  AnalyzerStatus? analyzerStatus;
  String? error;
  String? healthMessage;
  String? lastActionMessage;
  bool loading = true;
  bool analyzing = false;
  bool checkingAnalyzer = false;
  bool importingBackup = false;
  Timer? _queryDebounce;
  int tabIndex = 0;
  String query = '';
  String category = '';
  String platform = '';
  String statusFilter = 'active';
  String sortMode = 'newest';
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  Future<void> bootstrap() async {
    await restoreSettings();
    await refresh();
    await _listenForSharedLinks();
  }

  Future<void> restoreSettings() async {
    final savedBackendUrl = await settings.loadBackendUrl();
    if (savedBackendUrl != null) {
      try {
        final normalized = normalizeBackendUrl(savedBackendUrl);
        if (normalized != savedBackendUrl) {
          await settings.saveBackendUrl(normalized);
        }
        if (normalized != api.baseUrl) {
          api = ApiClient(normalized);
        }
      } on FormatException {
        await settings.saveBackendUrl(defaultBackendUrl());
      }
    }
  }

  void selectTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  LinkItem? itemById(String id) {
    return items.where((item) => item.id == id).firstOrNull ?? _itemCache[id];
  }

  void _rememberItems(Iterable<LinkItem> values) {
    for (final item in values) {
      _itemCache[item.id] = item;
    }
  }

  void _replaceItem(LinkItem updated) {
    _itemCache[updated.id] = updated;
    items = [for (final item in items) item.id == updated.id ? updated : item];
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
    _queryDebounce?.cancel();
    _queryDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(refresh());
    });
  }

  void setCategory(String value) {
    category = category == value ? '' : value;
    notifyListeners();
    unawaited(refresh());
  }

  void setPlatform(String value) {
    platform = platform == value ? '' : value;
    notifyListeners();
    unawaited(refresh());
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    category = '';
    platform = '';
    notifyListeners();
    unawaited(refresh());
  }

  void setSortMode(String value) {
    sortMode = value;
    notifyListeners();
    unawaited(refresh());
  }

  Future<void> setBackendUrl(String value) async {
    final normalized = normalizeBackendUrl(value);
    api = ApiClient(normalized);
    analyzerStatus = null;
    await settings.saveBackendUrl(normalized);
    await refresh();
  }

  Future<void> checkAnalyzer() async {
    checkingAnalyzer = true;
    error = null;
    notifyListeners();
    try {
      analyzerStatus = await api.checkAnalyzer();
    } catch (exception) {
      error = exception.toString();
    } finally {
      checkingAnalyzer = false;
      notifyListeners();
    }
  }

  Future<JsonImportResult?> importJsonBackup(String rawJson) async {
    importingBackup = true;
    error = null;
    lastActionMessage = null;
    notifyListeners();
    try {
      final result = await api.importJsonBackup(rawJson);
      lastActionMessage =
          '已导入 ${result.importedCount} 条：新增 ${result.createdCount}，合并 ${result.mergedCount}';
      await refresh();
      return result;
    } catch (exception) {
      error = exception.toString();
      notifyListeners();
      return null;
    } finally {
      importingBackup = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.listItems(
          query: query,
          category: category,
          platform: platform,
          status: statusFilter,
          sort: sortMode,
        ),
        api.stats(status: statusFilter),
        api.digest(),
        api.health(),
      ]);
      items = results[0] as List<LinkItem>;
      _rememberItems(items);
      stats = results[1] as CollectionStats;
      digest = results[2] as CollectionDigest;
      final health = results[3] as Map<String, dynamic>;
      final model = (health['deepseek_model'] ?? 'deepseek-v4-flash')
          .toString();
      healthMessage = health['deepseek_configured'] == true
          ? 'DeepSeek 已配置：$model'
          : 'DeepSeek 未配置，使用本地启发式分析';
      unawaited(_refreshStaleRemoteCovers());
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<LinkItem?> analyzeLink({
    required String text,
    String? sourceApp,
  }) async {
    final items = await analyzeSharedText(text: text, sourceApp: sourceApp);
    return items.firstOrNull;
  }

  Future<List<LinkItem>> analyzeSharedText({
    required String text,
    String? sourceApp,
  }) async {
    if (text.trim().isEmpty) {
      return [];
    }
    analyzing = true;
    error = null;
    lastActionMessage = null;
    notifyListeners();
    try {
      final items = await api.analyzeLinks(
        sharedText: text,
        sourceApp: sourceApp,
      );
      _rememberItems(items);
      lastActionMessage = items.isEmpty
          ? null
          : items.length == 1
          ? '已整理 1 条链接'
          : '已整理 ${items.length} 条链接';
      await refresh();
      return items;
    } catch (exception) {
      error = exception.toString();
      notifyListeners();
      return [];
    } finally {
      analyzing = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(LinkItem item, String status) async {
    final updated = await api.updateStatus(item.id, status);
    _rememberItems([updated]);
    statusFilter = status;
    await refresh();
  }

  Future<void> editItem({
    required LinkItem item,
    required String category,
    required List<String> keywords,
    required String notes,
  }) async {
    final updated = await api.updateItem(
      id: item.id,
      category: category,
      keywords: keywords,
      notes: notes,
    );
    _rememberItems([updated]);
    await refresh();
  }

  Future<void> deleteItem(LinkItem item) async {
    await api.deleteItem(item.id);
    _itemCache.remove(item.id);
    await refresh();
  }

  Future<void> reanalyze(LinkItem item) async {
    analyzing = true;
    notifyListeners();
    try {
      final updated = await api.reanalyze(item.id);
      _rememberItems([updated]);
      await refresh();
    } finally {
      analyzing = false;
      notifyListeners();
    }
  }

  Future<void> refreshCover(LinkItem item, {bool force = false}) async {
    if (_coverRefreshesInFlight.contains(item.id)) {
      return;
    }
    _coverRefreshesInFlight.add(item.id);
    try {
      final updated = await api.refreshCover(item.id, force: force);
      _replaceItem(updated);
      notifyListeners();
    } catch (exception) {
      debugPrint('Cover refresh failed for ${item.id}: $exception');
    } finally {
      _coverRefreshesInFlight.remove(item.id);
    }
  }

  Future<void> _refreshStaleRemoteCovers() async {
    final candidates = items
        .where(_shouldAutoRefreshCover)
        .take(3)
        .toList(growable: false);
    for (final item in candidates) {
      _autoCoverRefreshesTried.add(item.id);
      await refreshCover(item);
    }
  }

  bool _shouldAutoRefreshCover(LinkItem item) {
    final imageUrl = item.imageUrl?.trim() ?? '';
    if (imageUrl.isEmpty ||
        imageUrl.startsWith('/media/') ||
        imageUrl.contains('/media/cover-')) {
      return false;
    }
    if (_autoCoverRefreshesTried.contains(item.id) ||
        _coverRefreshesInFlight.contains(item.id)) {
      return false;
    }
    if (item.coverCachedAt != null) {
      return false;
    }
    final checkedAt = item.coverCheckedAt;
    if (checkedAt == null) {
      return true;
    }
    return DateTime.now().difference(checkedAt) > const Duration(hours: 6);
  }

  Future<LinkItem?> loadItem(String id) async {
    final cached = itemById(id);
    if (cached != null) {
      return cached;
    }
    try {
      final item = await api.getItem(id);
      _rememberItems([item]);
      notifyListeners();
      return item;
    } catch (exception) {
      error = exception.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> _listenForSharedLinks() async {
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) {
        await _handleSharedMedia(initial);
        await ReceiveSharingIntent.instance.reset();
      }
      _shareSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen(_handleSharedMedia);
    } catch (exception) {
      debugPrint('Share intent unavailable: $exception');
    }
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> files) async {
    final parts = <String>[];
    for (final file in files) {
      if (file.path.trim().isNotEmpty) {
        parts.add(file.path);
      }
      if ((file.message ?? '').trim().isNotEmpty) {
        parts.add(file.message!.trim());
      }
    }
    if (parts.isNotEmpty) {
      await analyzeSharedText(
        text: parts.join('\n'),
        sourceApp: 'system_share_sheet',
      );
    }
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    _shareSubscription?.cancel();
    super.dispose();
  }
}
