class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String? url;
  final DateTime publishedAt;
  final String? category;

  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    this.url,
    required this.publishedAt,
    this.category,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? json['content'] as String? ?? '',
      source: json['source'] as String? ?? 'OpenClaw',
      url: json['url'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] as String?,
    );
  }
}
