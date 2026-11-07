part of '../../main.dart';

class ApiClient {
  ApiClient(this.baseUrl, {this.apiToken = buildApiToken});

  static const _requestTimeout = Duration(seconds: 12);
  static const _analysisTimeout = Duration(minutes: 5);

  final String baseUrl;
  final String apiToken;

  Map<String, String> get authorizationHeaders => apiToken.trim().isEmpty
      ? const {}
      : {'authorization': 'Bearer ${apiToken.trim()}'};

  Uri _uri(String path, [Map<String, String?> query = const {}]) {
    final clean = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$clean$path').replace(
      queryParameters: {
        for (final entry in query.entries)
          if ((entry.value ?? '').isNotEmpty) entry.key: entry.value!,
      },
    );
  }

  Future<Map<String, dynamic>> health() async {
    final response = await _get(_uri('/health'));
    return _decodeObject(response);
  }

  Uri exportMarkdownUri() => _uri('/api/export/markdown');

  Uri exportJsonUri() => _uri('/api/export/json');

  Future<String> exportMarkdown() async {
    final response = await _get(exportMarkdownUri());
    _ensureSuccess(response);
    return utf8.decode(response.bodyBytes);
  }

  Future<String> exportJson() async {
    final response = await _get(exportJsonUri());
    _ensureSuccess(response);
    return utf8.decode(response.bodyBytes);
  }

  Future<JsonImportResult> importJsonBackup(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON 备份必须是对象');
    }
    final response = await _post(
      _uri('/api/import/json'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(decoded),
    );
    return JsonImportResult.fromJson(_decodeObject(response));
  }

  Future<List<LinkItem>> listItems({
    String query = '',
    String category = '',
    String platform = '',
    String status = 'active',
    String sort = 'newest',
  }) async {
    final response = await _get(
      _uri('/api/items', {
        'query': query,
        'category': category,
        'platform': platform,
        'status': status,
        'sort': sort,
      }),
    );
    final decoded = _decodeList(response);
    return decoded.map((item) => LinkItem.fromJson(item)).toList();
  }

  Future<LinkItem> getItem(String id) async {
    final response = await _get(_uri('/api/items/$id'));
    return LinkItem.fromJson(_decodeObject(response));
  }

  Future<CollectionStats> stats({String status = 'active'}) async {
    final response = await _get(_uri('/api/stats', {'status': status}));
    return CollectionStats.fromJson(_decodeObject(response));
  }

  Future<CollectionDigest> digest() async {
    final response = await _get(_uri('/api/digest'));
    return CollectionDigest.fromJson(_decodeObject(response));
  }

  Future<AnalyzerStatus> checkAnalyzer() async {
    final response = await _post(_uri('/api/analyzer/check'));
    return AnalyzerStatus.fromJson(_decodeObject(response));
  }

  Future<LinkItem> analyzeLink({
    required String sharedText,
    String? sourceApp,
  }) async {
    final response = await _post(
      _uri('/api/links/analyze'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'shared_text': sharedText, 'source_app': sourceApp}),
      timeout: _analysisTimeout,
    );
    return LinkItem.fromJson(_decodeObject(response));
  }

  Future<List<LinkItem>> analyzeLinks({
    required String sharedText,
    String? sourceApp,
  }) async {
    final response = await _post(
      _uri('/api/links/analyze-many'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'shared_text': sharedText, 'source_app': sourceApp}),
      timeout: _analysisTimeout,
    );
    final decoded = _decodeList(response);
    return decoded.map((item) => LinkItem.fromJson(item)).toList();
  }

  Future<LinkItem> reanalyze(String id) async {
    final response = await _post(
      _uri('/api/items/$id/reanalyze'),
      timeout: _analysisTimeout,
    );
    return LinkItem.fromJson(_decodeObject(response));
  }

  Future<LinkItem> refreshContent(String id, {bool force = false}) async {
    final response = await _post(
      _uri('/api/items/$id/refresh', {'force': force ? 'true' : null}),
      timeout: _analysisTimeout,
    );
    return LinkItem.fromJson(_decodeObject(response));
  }

  /// Re-captures the archive screenshot from the live source (slow: renders the
  /// page in a headless browser on the backend).
  Future<LinkItem> captureArchive(String id) async {
    final response = await _post(
      _uri('/api/items/$id/archive'),
      timeout: _analysisTimeout,
    );
    return LinkItem.fromJson(_decodeObject(response));
  }

  Future<LinkItem> refreshCover(String id, {bool force = false}) async {
    final response = await _post(
      _uri('/api/items/$id/cover/refresh', {'force': force ? 'true' : null}),
    );
    return LinkItem.fromJson(_decodeObject(response));
  }

  Future<LinkItem> updateStatus(String id, String status) async {
    final response = await _patch(
      _uri('/api/items/$id/status'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return LinkItem.fromJson(_decodeObject(response));
  }

  Future<LinkItem> updateItem({
    required String id,
    required String category,
    required List<String> keywords,
    required String notes,
  }) async {
    final response = await _patch(
      _uri('/api/items/$id'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'category': category,
        'keywords': keywords,
        'notes': notes,
      }),
    );
    return LinkItem.fromJson(_decodeObject(response));
  }

  Future<void> deleteItem(String id) async {
    final response = await _delete(_uri('/api/items/$id'));
    if (response.statusCode != 204) {
      _throwHttp(response);
    }
  }

  Future<http.Response> _get(Uri uri) {
    return http
        .get(uri, headers: authorizationHeaders)
        .timeout(_requestTimeout);
  }

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = _requestTimeout,
  }) {
    return http
        .post(uri, headers: _mergeHeaders(headers), body: body)
        .timeout(timeout);
  }

  Future<http.Response> _patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return http
        .patch(uri, headers: _mergeHeaders(headers), body: body)
        .timeout(_requestTimeout);
  }

  Future<http.Response> _delete(Uri uri) {
    return http
        .delete(uri, headers: authorizationHeaders)
        .timeout(_requestTimeout);
  }

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    return {...authorizationHeaders, ...?headers};
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwHttp(response);
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwHttp(response);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwHttp(response);
    }
    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Never _throwHttp(http.Response response) {
    String message = 'HTTP ${response.statusCode}';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }
}
