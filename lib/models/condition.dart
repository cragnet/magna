enum ConditionType {
  app,
  keyword,
  regex,
  timeRange,
  screenState,
  ringerMode,
  otpDetected,
  aiImportance,
  sender,
}

class Condition {
  final ConditionType type;
  final Map<String, dynamic> params;

  Condition({required this.type, required this.params});

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'params': params,
  };

  factory Condition.fromJson(Map<String, dynamic> json) => Condition(
    type: ConditionType.values.byName(json['type'] as String),
    params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
  );
}
