enum ActionType {
  addToGlance,
  dismiss,
  summarize,
  batchRelease,
  copyOtp,
  ttsReadout,
  customVibration,
  webhook,
  aiAutoReply,
}

class RuleAction {
  final ActionType type;
  final Map<String, dynamic> params;

  RuleAction({required this.type, required this.params});

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'params': params,
  };

  factory RuleAction.fromJson(Map<String, dynamic> json) => RuleAction(
    type: ActionType.values.byName(json['type'] as String),
    params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
  );
}
