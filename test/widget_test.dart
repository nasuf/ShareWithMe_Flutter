import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_with_me/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('api client builds bearer authorization headers', () {
    final api = ApiClient('https://example.com', apiToken: ' secret-token ');
    expect(api.authorizationHeaders, {'authorization': 'Bearer secret-token'});
  });

  test('parseKeywords normalizes separators and duplicates', () {
    expect(parseKeywords('旅行，攻略 路线、攻略;周末'), ['旅行', '攻略', '路线', '周末']);
  });

  test('app settings save and load backend URL', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = AppSettings();
    await settings.saveBackendUrl(' http://10.0.0.5:8080 ');

    expect(await settings.loadBackendUrl(), 'http://10.0.0.5:8080');
  });

  test('bootstrap uses persisted backend URL', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.backend_url': 'https://share.example.com',
    });

    final controller = ShareController(
      ApiClient(defaultBackendUrl()),
      settings: AppSettings(),
    );
    expect(controller.api.baseUrl, defaultBackendUrl());

    await controller.restoreSettings();

    expect(controller.api.baseUrl, 'https://share.example.com');
    controller.dispose();
  });

  test('default backend URL points to RackNerd production server', () {
    expect(defaultBackendUrl(), 'http://192.210.235.115:8080');
  });

  test(
    'bootstrap migrates legacy local backend URL to production default',
    () async {
      SharedPreferences.setMockInitialValues({
        'flutter.backend_url': 'http://192.168.1.106:8080',
      });

      final controller = ShareController(
        ApiClient(defaultBackendUrl()),
        settings: AppSettings(),
      );

      await controller.restoreSettings();

      expect(controller.api.baseUrl, 'http://192.210.235.115:8080');
      expect(
        await AppSettings().loadBackendUrl(),
        'http://192.210.235.115:8080',
      );
      controller.dispose();
    },
  );

  test('private backend hosts are treated as stale local defaults', () {
    expect(isPrivateBackendHost('127.0.0.1'), isTrue);
    expect(isPrivateBackendHost('localhost'), isTrue);
    expect(isPrivateBackendHost('10.0.2.2'), isTrue);
    expect(isPrivateBackendHost('10.1.2.3'), isTrue);
    expect(isPrivateBackendHost('172.16.0.3'), isTrue);
    expect(isPrivateBackendHost('172.31.255.1'), isTrue);
    expect(isPrivateBackendHost('192.168.1.106'), isTrue);
    expect(isPrivateBackendHost('192.210.235.115'), isFalse);
    expect(isPrivateBackendHost('share.example.com'), isFalse);
  });

  test('normalizeBackendUrl accepts common LAN inputs', () {
    expect(
      normalizeBackendUrl(' 192.168.1.23:8080/ '),
      'http://192.168.1.23:8080',
    );
    expect(
      normalizeBackendUrl('https://share.example.com/api/'),
      'https://share.example.com/api',
    );
  });

  test('normalizeBackendUrl rejects non-http backend URLs', () {
    expect(
      () => normalizeBackendUrl('ftp://192.168.1.23:8080'),
      throwsFormatException,
    );
    expect(() => normalizeBackendUrl(''), throwsFormatException);
  });

  testWidgets('renders ShareWithMe shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ShareWithMeApp());
    await tester.pump();

    expect(find.textContaining('资料库'), findsWidgets);
    expect(find.text('资料库'), findsWidgets);
    expect(find.text('洞察'), findsWidgets);
  });

  testWidgets('library shows a retry state when the backend is unavailable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ShareController(
      _FailingApiClient(_sampleItem()),
      settings: AppSettings(),
    );

    await controller.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: ShareScope(
          controller: controller,
          child: Scaffold(body: InboxPage(controller: controller)),
        ),
      ),
    );

    expect(find.text('暂时无法连接资料服务'), findsOneWidget);
    expect(find.text('重新连接'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('add link sheet validates empty shared text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ShareController(
      _FakeApiClient(_sampleItem()),
      settings: AppSettings(),
    )..loading = false;

    await _pumpAddSheetHarness(tester, controller);
    await tester.tap(find.text('打开添加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('解析并收集'));
    await tester.pumpAndSettle();

    expect(find.text('请先粘贴分享文本或链接'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('add link sheet shows backend analysis errors', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ShareController(
      _FakeApiClient(_sampleItem(), analyzeError: '无法连接后端'),
      settings: AppSettings(),
    )..loading = false;

    await _pumpAddSheetHarness(tester, controller);
    await tester.tap(find.text('打开添加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'https://example.com/a');
    await tester.tap(find.text('解析并收集'));
    await tester.pumpAndSettle();

    expect(find.text('Exception: 无法连接后端'), findsOneWidget);
    expect(find.text('收集链接'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('add link sheet closes after successful analysis', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final api = _FakeApiClient(_sampleItem());
    final controller = ShareController(api, settings: AppSettings())
      ..loading = false;

    await _pumpAddSheetHarness(tester, controller);
    await tester.tap(find.text('打开添加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'https://example.com/a');
    await tester.tap(find.text('解析并收集'));
    await tester.pumpAndSettle();

    expect(api.analyzedTexts, ['https://example.com/a']);
    expect(find.text('收集链接'), findsNothing);
    controller.dispose();
  });

  testWidgets('settings exposes readable and structured exports', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ShareController(
      _FakeApiClient(_sampleItem()),
      settings: AppSettings(),
    )..loading = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ShareScope(
          controller: controller,
          child: Scaffold(body: SettingsPage(controller: controller)),
        ),
      ),
    );

    expect(find.text('复制 Markdown'), findsOneWidget);
    expect(find.text('复制 JSON 备份'), findsOneWidget);
    expect(find.text('导入 JSON 备份'), findsOneWidget);
    expect(controller.api.exportJsonUri().path, '/api/export/json');
    controller.dispose();
  });

  testWidgets('settings imports pasted JSON backups', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final api = _FakeApiClient(_sampleItem());
    final controller = ShareController(api, settings: AppSettings())
      ..loading = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ShareScope(
          controller: controller,
          child: Scaffold(body: SettingsPage(controller: controller)),
        ),
      ),
    );

    await tester.tap(find.text('导入 JSON 备份'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入'));
    await tester.pumpAndSettle();

    expect(find.text('请先粘贴 JSON 备份内容'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      '{"schema_version":1,"items":[]}',
    );
    await tester.tap(find.text('导入'));
    await tester.pumpAndSettle();

    expect(api.importedBackups, ['{"schema_version":1,"items":[]}']);
    expect(find.text('导入完成：新增 1，合并 0'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('insights folders open the filtered library', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final item = _sampleItem();
    final api = _FakeApiClient(item);
    final controller = ShareController(api, settings: AppSettings());
    await controller.refresh();
    controller.selectTab(1);

    await tester.pumpWidget(
      MaterialApp(
        home: ShareScope(
          controller: controller,
          child: Scaffold(body: InsightsPage(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('收藏夹'), findsWidgets);

    await tester.tap(find.text('阅读'));
    await tester.pumpAndSettle();

    expect(controller.category, '阅读');
    expect(controller.tabIndex, 0);
    controller.dispose();
  });

  testWidgets('edit sheet reuses an existing folder instead of retyping it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final item = _sampleItem();
    final api = _FakeApiClient(item);
    final controller = ShareController(api, settings: AppSettings())
      ..loading = false
      ..items = [item]
      ..stats = CollectionStats(
        total: 2,
        categories: [
          CountBucket(label: '阅读', count: 1),
          CountBucket(label: '旅游攻略', count: 1),
        ],
        platforms: const [],
        keywords: const [],
      );

    await _pumpEditSheetHarness(tester, controller, item);
    await tester.tap(find.text('打开编辑'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, '旅游攻略'), findsOneWidget);

    await tester.tap(find.text('旅游攻略'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(api.updatedCategories, ['旅游攻略']);
    controller.dispose();
  });

  testWidgets('library card menu is not clipped to its trigger size', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final item = _sampleItem();
    final api = _FakeApiClient(item);
    final controller = ShareController(api, settings: AppSettings())
      ..loading = false
      ..items = [item];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: ShareScope(
              controller: controller,
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 360,
                    child: LinkCard(item: item, controller: controller),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    for (final label in ['编辑收藏夹与关键词', '标为重要', '归档', '重新生成 AI 分析']) {
      expect(find.text(label), findsOneWidget);
    }
    // The longest label must lay out at its natural width rather than being
    // squeezed into the trigger-sized box the menu used to inherit.
    expect(tester.getSize(find.text('编辑收藏夹与关键词')).width, greaterThan(80));
    controller.dispose();
  });

  testWidgets('detail page asks for confirmation before deleting', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final item = _sampleItem();
    final api = _FakeApiClient(item);
    final controller = ShareController(api, settings: AppSettings())
      ..loading = false
      ..items = [item];

    await tester.pumpWidget(
      MaterialApp(
        home: ShareScope(
          controller: controller,
          child: const DetailPage(itemId: 'item-1'),
        ),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();

    expect(find.text('删除这条内容？'), findsOneWidget);
    expect(api.deletedIds, isEmpty);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(api.deletedIds, isEmpty);
    expect(find.text('测试链接'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();

    expect(api.deletedIds, ['item-1']);
    controller.dispose();
  });

  testWidgets('detail page opens the archive view from the original section', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final item = _sampleItem();
    final controller =
        ShareController(_FakeApiClient(item), settings: AppSettings())
          ..loading = false
          ..items = [item];

    await tester.pumpWidget(
      MaterialApp(
        home: ShareScope(
          controller: controller,
          child: const DetailPage(itemId: 'item-1'),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('存档'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('存档'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('还没有存档快照'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('archive viewer double-tap resets zoom to fit width', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final base = _sampleItem();
    final item = LinkItem.fromJson({
      'id': base.id,
      'source_url': base.sourceUrl,
      'final_url': base.finalUrl,
      'platform': base.platform,
      'title': base.title,
      'description': base.description,
      'content_text': base.contentText,
      'summary': base.summary,
      'category': base.category,
      'keywords': base.keywords,
      'entities': base.entities,
      'sentiment': base.sentiment,
      'content_type': base.contentType,
      'importance_score': base.importanceScore,
      'notes': base.notes,
      'status': base.status,
      'created_at': base.createdAt.toIso8601String(),
      'updated_at': base.updatedAt.toIso8601String(),
      'archive': {
        'url': '/media/snapshot.jpg',
        'width': 1352,
        'height': 13352,
        'captured_at': '2026-11-07T05:45:14Z',
      },
    });
    final controller =
        ShareController(_FakeApiClient(item), settings: AppSettings())
          ..loading = false
          ..items = [item];

    await tester.pumpWidget(
      MaterialApp(
        home: ShareScope(
          controller: controller,
          child: const ArchiveSnapshotPage(itemId: 'item-1'),
        ),
      ),
    );
    await tester.pump();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final transform = viewer.transformationController!;
    // x-axis scale; getMaxScaleOnAxis() would include z (always 1).
    final fitScale = transform.value.entry(0, 0);
    expect(fitScale, closeTo(800 / 1352, 0.001));

    transform.value = Matrix4.diagonal3Values(fitScale * 3, fitScale * 3, 1);
    final center = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();

    expect(transform.value.entry(0, 0), closeTo(fitScale, 0.001));
    controller.dispose();
  });

  testWidgets('detail page loads full article text for a slim list row', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final full = _sampleItem();
    final slim = LinkItem(
      id: full.id,
      sourceUrl: full.sourceUrl,
      finalUrl: full.finalUrl,
      platform: full.platform,
      title: full.title,
      description: full.description,
      contentText: '',
      originalText: '',
      summary: full.summary,
      category: full.category,
      keywords: full.keywords,
      entities: full.entities,
      sentiment: full.sentiment,
      contentType: full.contentType,
      importanceScore: full.importanceScore,
      notes: full.notes,
      status: full.status,
      createdAt: full.createdAt,
      updatedAt: full.updatedAt,
      contentOmitted: true,
    );
    final api = _FakeApiClient(full);
    final controller = ShareController(api, settings: AppSettings())
      ..loading = false
      ..items = [slim];

    await tester.pumpWidget(
      MaterialApp(
        home: ShareScope(
          controller: controller,
          child: const DetailPage(itemId: 'item-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.fetchedIds, ['item-1']);
    expect(controller.itemById('item-1')?.contentOmitted, isFalse);
    expect(find.text('正在加载原文…'), findsNothing);
    controller.dispose();
  });

  test('archive snapshot parses only complete payloads', () {
    expect(ArchiveSnapshot.tryParse(null), isNull);
    expect(ArchiveSnapshot.tryParse({'url': '/media/a.jpg'}), isNull);
    final archive = ArchiveSnapshot.tryParse({
      'kind': 'screenshot',
      'url': '/media/snapshot-1.jpg',
      'width': 676,
      'height': 6676,
      'captured_at': '2026-11-07T05:45:14Z',
    });
    expect(archive?.height, 6676);
  });
}

Future<void> _pumpEditSheetHarness(
  WidgetTester tester,
  ShareController controller,
  LinkItem item,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ShareScope(
        controller: controller,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showEditItemSheet(context, controller, item),
                child: const Text('打开编辑'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpAddSheetHarness(
  WidgetTester tester,
  ShareController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ShareScope(
        controller: controller,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showAddLinkSheet(context, controller),
                child: const Text('打开添加'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

LinkItem _sampleItem() {
  final now = DateTime(2026, 6, 11, 12);
  return LinkItem(
    id: 'item-1',
    sourceUrl: 'https://example.com/a',
    finalUrl: 'https://example.com/a',
    platform: 'Example',
    title: '测试链接',
    description: '用于测试删除确认',
    contentText: '正文',
    originalText: '正文',
    summary: '摘要',
    category: '阅读',
    keywords: const ['测试'],
    entities: const [],
    sentiment: 'neutral',
    contentType: 'article',
    importanceScore: 3,
    notes: '本地启发式分析',
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.item, {this.analyzeError})
    : super('http://127.0.0.1:8080');

  final LinkItem item;
  final String? analyzeError;
  final List<String> analyzedTexts = [];
  final List<String> deletedIds = [];
  final List<String> importedBackups = [];
  final List<String> updatedCategories = [];
  final List<String> fetchedIds = [];

  @override
  Future<LinkItem> getItem(String id) async {
    fetchedIds.add(id);
    return item;
  }

  @override
  Future<LinkItem> updateItem({
    required String id,
    required String category,
    required List<String> keywords,
    required String notes,
  }) async {
    updatedCategories.add(category);
    return item;
  }

  @override
  Future<List<LinkItem>> analyzeLinks({
    required String sharedText,
    String? sourceApp,
  }) async {
    analyzedTexts.add(sharedText);
    if (analyzeError != null) {
      throw Exception(analyzeError);
    }
    return [item];
  }

  @override
  Future<JsonImportResult> importJsonBackup(String rawJson) async {
    importedBackups.add(rawJson);
    return JsonImportResult(
      importedCount: 1,
      createdCount: 1,
      mergedCount: 0,
      totalCount: 1,
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<LinkItem> refreshContent(String id, {bool force = false}) async {
    return item;
  }

  @override
  Future<List<LinkItem>> listItems({
    String query = '',
    String category = '',
    String platform = '',
    String status = 'active',
    String sort = 'newest',
  }) async {
    return deletedIds.contains(item.id) ? [] : [item];
  }

  @override
  Future<CollectionStats> stats({String status = 'active'}) async {
    final gone = deletedIds.contains(item.id);
    return CollectionStats(
      total: gone ? 0 : 1,
      categories: gone
          ? const []
          : [CountBucket(label: item.category, count: 1)],
      platforms: const [],
      keywords: const [],
    );
  }

  @override
  Future<CollectionDigest> digest() async {
    return CollectionDigest(
      total: deletedIds.contains(item.id) ? 0 : 1,
      generatedAt: DateTime(2026, 6, 11, 12),
      focusSummary: '测试',
      categorySummaries: const [],
      recentItems: const [],
      suggestions: const [],
    );
  }

  @override
  Future<Map<String, dynamic>> health() async {
    return {
      'deepseek_configured': false,
      'deepseek_model': 'deepseek-v4-flash',
    };
  }
}

class _FailingApiClient extends _FakeApiClient {
  _FailingApiClient(super.item);

  @override
  Future<List<LinkItem>> listItems({
    String query = '',
    String category = '',
    String platform = '',
    String status = 'active',
    String sort = 'newest',
  }) {
    throw Exception('connection refused');
  }

  @override
  Future<Map<String, dynamic>> health() {
    throw Exception('connection refused');
  }
}
