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

class Action {
  final ActionType type;
  final Map<String, dynamic> params;

  Action({required this.type, required this.params});

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'params': params,
  };

  factory Action.fromJson(Map<String, dynamic> json) => Action(
    type: ActionType.values.byName(json['type'] as String),
    params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
  );
}
