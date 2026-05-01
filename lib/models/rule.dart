import 'condition.dart';
import 'action.dart';

enum AiTier { local, cloud, auto }

class Rule {
  final String id;
  final String name;
  final bool enabled;
  final int priority;
  final List<Condition> conditions;
  final List<Action> actions;
  final AiTier aiTier;

  Rule({
    required this.id,
    required this.name,
    this.enabled = true,
    this.priority = 50,
    this.conditions = const [],
    this.actions = const [],
    this.aiTier = AiTier.auto,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'enabled': enabled,
    'priority': priority,
    'conditions': conditions.map((c) => c.toJson()).toList(),
    'actions': actions.map((a) => a.toJson()).toList(),
    'aiTier': aiTier.name,
  };

  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
    id: json['id'] as String,
    name: json['name'] as String,
    enabled: json['enabled'] as bool? ?? true,
    priority: json['priority'] as int? ?? 50,
    conditions: (json['conditions'] as List? ?? [])
        .map((c) => Condition.fromJson(c as Map<String, dynamic>))
        .toList(),
    actions: (json['actions'] as List? ?? [])
        .map((a) => Action.fromJson(a as Map<String, dynamic>))
        .toList(),
    aiTier: AiTier.values.byName(json['aiTier'] as String? ?? 'auto'),
  );

  Rule copyWith({
    String? id,
    String? name,
    bool? enabled,
    int? priority,
    List<Condition>? conditions,
    List<Action>? actions,
    AiTier? aiTier,
  }) => Rule(
    id: id ?? this.id,
    name: name ?? this.name,
    enabled: enabled ?? this.enabled,
    priority: priority ?? this.priority,
    conditions: conditions ?? this.conditions,
    actions: actions ?? this.actions,
    aiTier: aiTier ?? this.aiTier,
  );
}
