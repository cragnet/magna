class WebhookConfig {
  final String id;
  final String name;
  final String url;
  final String method;
  final Map<String, String> headers;
  final String bodyTemplate;
  final bool enabled;

  WebhookConfig({
    required this.id,
    required this.name,
    required this.url,
    this.method = 'POST',
    this.headers = const {},
    this.bodyTemplate = '{"app":"{app_name}","title":"{title}","text":"{text}"}',
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'method': method,
    'headers': headers,
    'bodyTemplate': bodyTemplate,
    'enabled': enabled,
  };

  factory WebhookConfig.fromJson(Map<String, dynamic> json) => WebhookConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    url: json['url'] as String,
    method: json['method'] as String? ?? 'POST',
    headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
    bodyTemplate: json['bodyTemplate'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? true,
  );

  WebhookConfig copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    Map<String, String>? headers,
    String? bodyTemplate,
    bool? enabled,
  }) => WebhookConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    method: method ?? this.method,
    headers: headers ?? this.headers,
    bodyTemplate: bodyTemplate ?? this.bodyTemplate,
    enabled: enabled ?? this.enabled,
  );
}
