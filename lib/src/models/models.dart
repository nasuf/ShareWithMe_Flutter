part of '../../main.dart';

class LinkItem {
  LinkItem({
    required this.id,
    required this.sourceUrl,
    required this.finalUrl,
    required this.platform,
    required this.title,
    required this.description,
    required this.contentText,
    required this.originalText,
    required this.summary,
    required this.category,
    required this.keywords,
    required this.entities,
    required this.sentiment,
    required this.contentType,
    required this.importanceScore,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.analysisPending = false,
    this.sourceApp,
    this.author,
    this.imageUrl,
    this.remoteImageUrl,
    this.coverCachedAt,
    this.coverCheckedAt,
    this.sharedText = '',
    this.originalContent = const OriginalContent.empty(),
    this.media = const [],
    this.sourceFacts = const [],
    this.sourceId,
    this.publishedAt,
    this.userEditedAt,
    this.extraction = const ExtractionState.legacy(),
  });

  final String id;
  final String sourceUrl;
  final String finalUrl;
  final String? sourceApp;
  final String platform;
  final String title;
  final String description;
  final String? author;
  final String? imageUrl;
  final String? remoteImageUrl;
  final DateTime? coverCachedAt;
  final DateTime? coverCheckedAt;
  final String contentText;
  final String originalText;
  final String sharedText;
  final OriginalContent originalContent;
  final List<MediaAsset> media;
  final List<SourceFact> sourceFacts;
  final String? sourceId;
  final DateTime? publishedAt;
  final DateTime? userEditedAt;
  final ExtractionState extraction;
  final String summary;
  final String category;
  final List<String> keywords;
  final List<String> entities;
  final String sentiment;
  final String contentType;
  final int importanceScore;
  final String notes;
  final bool analysisPending;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LinkItem.fromJson(Map<String, dynamic> json) {
    return LinkItem(
      id: json['id'] as String,
      sourceUrl: json['source_url'] as String,
      finalUrl: json['final_url'] as String,
      sourceApp: json['source_app'] as String?,
      platform: json['platform'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      author: json['author'] as String?,
      imageUrl: json['image_url'] as String?,
      remoteImageUrl: json['remote_image_url'] as String?,
      coverCachedAt: _parseOptionalDateTime(json['cover_cached_at']),
      coverCheckedAt: _parseOptionalDateTime(json['cover_checked_at']),
      contentText: json['content_text'] as String,
      originalText:
          (json['original_text'] as String?) ??
          (json['content_text'] as String),
      sharedText: (json['shared_text'] as String?) ?? '',
      originalContent: OriginalContent.fromJson(
        json['original_content'] as Map<String, dynamic>?,
        fallbackText:
            (json['original_text'] as String?) ??
            (json['content_text'] as String),
      ),
      media: ((json['media'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MediaAsset.fromJson)
          .toList(),
      sourceFacts: ((json['source_facts'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SourceFact.fromJson)
          .toList(),
      sourceId: json['source_id'] as String?,
      publishedAt: _parseOptionalDateTime(json['published_at']),
      userEditedAt: _parseOptionalDateTime(json['user_edited_at']),
      extraction: ExtractionState.fromJson(
        json['extraction'] as Map<String, dynamic>?,
      ),
      summary: json['summary'] as String,
      category: json['category'] as String,
      keywords: (json['keywords'] as List<dynamic>).cast<String>(),
      entities: (json['entities'] as List<dynamic>).cast<String>(),
      sentiment: json['sentiment'] as String,
      contentType: json['content_type'] as String,
      importanceScore: json['importance_score'] as int,
      notes: json['notes'] as String,
      analysisPending: (json['analysis_pending'] as bool?) ?? false,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  bool get contentNeedsRefresh {
    final refreshAfter = extraction.refreshAfter;
    return refreshAfter == null || !refreshAfter.isAfter(DateTime.now());
  }
}

class OriginalContent {
  const OriginalContent({
    required this.format,
    required this.plainText,
    required this.blocks,
  });

  const OriginalContent.empty()
    : format = '',
      plainText = '',
      blocks = const [];

  final String format;
  final String plainText;
  final List<ContentBlock> blocks;

  factory OriginalContent.fromJson(
    Map<String, dynamic>? json, {
    required String fallbackText,
  }) {
    if (json == null) {
      return OriginalContent(
        format: 'plain-text',
        plainText: fallbackText,
        blocks: fallbackText.trim().isEmpty
            ? const []
            : [ContentBlock(kind: 'paragraph', text: fallbackText)],
      );
    }
    return OriginalContent(
      format: (json['format'] as String?) ?? '',
      plainText: (json['plain_text'] as String?) ?? fallbackText,
      blocks: ((json['blocks'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ContentBlock.fromJson)
          .toList(),
    );
  }
}

class ContentBlock {
  const ContentBlock({
    required this.kind,
    this.text = '',
    this.level,
    this.url,
    this.alt,
    this.items = const [],
  });

  final String kind;
  final String text;
  final int? level;
  final String? url;
  final String? alt;
  final List<String> items;

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      kind: (json['kind'] as String?) ?? 'paragraph',
      text: (json['text'] as String?) ?? '',
      level: json['level'] as int?,
      url: json['url'] as String?,
      alt: json['alt'] as String?,
      items: ((json['items'] as List<dynamic>?) ?? []).cast<String>(),
    );
  }
}

class MediaAsset {
  const MediaAsset({
    required this.kind,
    required this.url,
    this.cachedUrl,
    this.thumbnailUrl,
    this.alt,
    this.width,
    this.height,
    this.durationSeconds,
  });

  final String kind;
  final String url;
  final String? cachedUrl;
  final String? thumbnailUrl;
  final String? alt;
  final int? width;
  final int? height;
  final double? durationSeconds;

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      kind: (json['kind'] as String?) ?? 'image',
      url: (json['url'] as String?) ?? '',
      cachedUrl: json['cached_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      alt: json['alt'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
    );
  }
}

class SourceFact {
  const SourceFact({
    required this.key,
    required this.label,
    required this.value,
  });

  final String key;
  final String label;
  final String value;

  factory SourceFact.fromJson(Map<String, dynamic> json) {
    return SourceFact(
      key: (json['key'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      value: (json['value'] as String?) ?? '',
    );
  }
}

class ExtractionState {
  const ExtractionState({
    required this.status,
    required this.adapter,
    required this.method,
    required this.completeness,
    this.fetchedAt,
    this.refreshAfter,
    this.contentFingerprint,
    this.lastError,
  });

  const ExtractionState.legacy()
    : status = 'legacy',
      adapter = 'legacy',
      method = 'legacy',
      completeness = 0,
      fetchedAt = null,
      refreshAfter = null,
      contentFingerprint = null,
      lastError = null;

  final String status;
  final String adapter;
  final String method;
  final int completeness;
  final DateTime? fetchedAt;
  final DateTime? refreshAfter;
  final String? contentFingerprint;
  final String? lastError;

  factory ExtractionState.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ExtractionState.legacy();
    }
    return ExtractionState(
      status: (json['status'] as String?) ?? 'legacy',
      adapter: (json['adapter'] as String?) ?? 'legacy',
      method: (json['method'] as String?) ?? 'legacy',
      completeness: (json['completeness'] as int?) ?? 0,
      fetchedAt: _parseOptionalDateTime(json['fetched_at']),
      refreshAfter: _parseOptionalDateTime(json['refresh_after']),
      contentFingerprint: json['content_fingerprint'] as String?,
      lastError: json['last_error'] as String?,
    );
  }
}

DateTime? _parseOptionalDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}

class CollectionStats {
  CollectionStats({
    required this.total,
    required this.categories,
    required this.platforms,
    required this.keywords,
  });

  final int total;
  final List<CountBucket> categories;
  final List<CountBucket> platforms;
  final List<CountBucket> keywords;

  factory CollectionStats.fromJson(Map<String, dynamic> json) {
    List<CountBucket> buckets(String key) {
      return ((json[key] as List<dynamic>?) ?? [])
          .map((item) => CountBucket.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return CollectionStats(
      total: json['total'] as int,
      categories: buckets('categories'),
      platforms: buckets('platforms'),
      keywords: buckets('keywords'),
    );
  }
}

class CountBucket {
  CountBucket({required this.label, required this.count});

  final String label;
  final int count;

  factory CountBucket.fromJson(Map<String, dynamic> json) {
    return CountBucket(
      label: json['label'] as String,
      count: json['count'] as int,
    );
  }
}

class AnalyzerStatus {
  AnalyzerStatus({
    required this.provider,
    required this.configured,
    required this.ok,
    required this.model,
    required this.message,
  });

  final String provider;
  final bool configured;
  final bool ok;
  final String model;
  final String message;

  factory AnalyzerStatus.fromJson(Map<String, dynamic> json) {
    return AnalyzerStatus(
      provider: json['provider'] as String,
      configured: json['configured'] as bool,
      ok: json['ok'] as bool,
      model: json['model'] as String,
      message: json['message'] as String,
    );
  }
}

class CollectionDigest {
  CollectionDigest({
    required this.total,
    required this.generatedAt,
    required this.focusSummary,
    required this.categorySummaries,
    required this.recentItems,
    required this.suggestions,
  });

  final int total;
  final DateTime generatedAt;
  final String focusSummary;
  final List<CountBucket> categorySummaries;
  final List<DigestItem> recentItems;
  final List<String> suggestions;

  factory CollectionDigest.fromJson(Map<String, dynamic> json) {
    return CollectionDigest(
      total: json['total'] as int,
      generatedAt: DateTime.parse(json['generated_at'] as String).toLocal(),
      focusSummary: json['focus_summary'] as String,
      categorySummaries: ((json['category_summaries'] as List<dynamic>?) ?? [])
          .map((item) => CountBucket.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentItems: ((json['recent_items'] as List<dynamic>?) ?? [])
          .map((item) => DigestItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      suggestions: ((json['suggestions'] as List<dynamic>?) ?? [])
          .cast<String>(),
    );
  }
}

class DigestItem {
  DigestItem({
    required this.id,
    required this.title,
    required this.platform,
    required this.category,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String platform;
  final String category;
  final String summary;
  final DateTime createdAt;

  factory DigestItem.fromJson(Map<String, dynamic> json) {
    return DigestItem(
      id: json['id'] as String,
      title: json['title'] as String,
      platform: json['platform'] as String,
      category: json['category'] as String,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

class JsonImportResult {
  JsonImportResult({
    required this.importedCount,
    required this.createdCount,
    required this.mergedCount,
    required this.totalCount,
  });

  final int importedCount;
  final int createdCount;
  final int mergedCount;
  final int totalCount;

  factory JsonImportResult.fromJson(Map<String, dynamic> json) {
    return JsonImportResult(
      importedCount: json['imported_count'] as int,
      createdCount: json['created_count'] as int,
      mergedCount: json['merged_count'] as int,
      totalCount: json['total_count'] as int,
    );
  }
}
