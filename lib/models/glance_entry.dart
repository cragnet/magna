class GlanceEntry {
  final String id;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final int timestamp;
  final String? summary;

  GlanceEntry({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.timestamp,
    this.summary,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'packageName': packageName,
    'appName': appName,
    'title': title,
    'text': text,
    'timestamp': timestamp,
    'summary': summary,
  };

  factory GlanceEntry.fromJson(Map<String, dynamic> json) => GlanceEntry(
    id: json['id'] as String,
    packageName: json['packageName'] as String,
    appName: json['appName'] as String,
    title: json['title'] as String,
    text: json['text'] as String,
    timestamp: json['timestamp'] as int,
    summary: json['summary'] as String?,
  );
}
