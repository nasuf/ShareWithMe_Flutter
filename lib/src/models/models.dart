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
    this.sourceApp,
    this.author,
    this.imageUrl,
    this.remoteImageUrl,
    this.coverCachedAt,
    this.coverCheckedAt,
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
  final String summary;
  final String category;
  final List<String> keywords;
  final List<String> entities;
  final String sentiment;
  final String contentType;
  final int importanceScore;
  final String notes;
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
      summary: json['summary'] as String,
      category: json['category'] as String,
      keywords: (json['keywords'] as List<dynamic>).cast<String>(),
      entities: (json['entities'] as List<dynamic>).cast<String>(),
      sentiment: json['sentiment'] as String,
      contentType: json['content_type'] as String,
      importanceScore: json['importance_score'] as int,
      notes: json['notes'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
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
