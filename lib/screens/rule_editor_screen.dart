import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../providers/rules_provider.dart';
import '../providers/webhooks_provider.dart';
import '../models/rule.dart';
import '../models/condition.dart';
import '../models/action.dart';
import '../services/permissions_service.dart';

class RuleEditorScreen extends StatefulWidget {
  final Rule? rule;
  const RuleEditorScreen({super.key, this.rule});

  @override
  State<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends State<RuleEditorScreen> {
  late String _id;
  late TextEditingController _nameCtrl;
  late int _priority;
  late AiTier _aiTier;
  late bool _enabled;
  final List<Condition> _conditions = [];
  final List<RuleAction> _actions = [];

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _id = r?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _nameCtrl = TextEditingController(text: r?.name ?? 'New Rule');
    _priority = r?.priority ?? 50;
    _aiTier = r?.aiTier ?? AiTier.auto;
    _enabled = r?.enabled ?? true;
    if (r != null) {
      _conditions.addAll(r.conditions);
      _actions.addAll(r.actions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rule == null ? 'New Rule' : 'Edit Rule'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Rule name',
                      hintText: 'e.g. Silence work emails at night',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Priority', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _priority.toDouble(),
                          min: 0, max: 100, divisions: 100,
                          label: _priority.toString(),
                          onChanged: (v) => setState(() => _priority = v.round()),
                          activeColor: const Color(0xFF7C4DFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<AiTier>(
                    segments: const [
                      ButtonSegment(value: AiTier.local, label: Text('Local AI')),
                      ButtonSegment(value: AiTier.cloud, label: Text('Cloud AI')),
                      ButtonSegment(value: AiTier.auto, label: Text('Auto')),
                    ],
                    selected: {_aiTier},
                    onSelectionChanged: (s) => setState(() => _aiTier = s.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section('When ALL of these are true'),
            if (_conditions.isEmpty)
              _emptyTile('No conditions — this rule will match every notification'),
            ..._conditions.asMap().entries.map((e) => _ConditionTile(
              index: e.key,
              condition: e.value,
              onChanged: (c) => setState(() => _conditions[e.key] = c),
              onDelete: () => setState(() => _conditions.removeAt(e.key)),
            )),
            const SizedBox(height: 8),
            _AddButton('Add condition', () => _showAddCondition(context)),
            const SizedBox(height: 24),
            _section('Then do these actions'),
            if (_actions.isEmpty)
              _emptyTile('No actions — add at least one'),
            ..._actions.asMap().entries.map((e) => _ActionTile(
              index: e.key,
              action: e.value,
              onChanged: (a) => setState(() => _actions[e.key] = a),
              onDelete: () => setState(() => _actions.removeAt(e.key)),
            )),
            const SizedBox(height: 8),
            _AddButton('Add action', () => _showAddAction(context)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Color(0xFF7C4DFF), fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _emptyTile(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Colors.white38), textAlign: TextAlign.center),
    );
  }

  void _showAddCondition(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Add condition', style: TextStyle(fontWeight: FontWeight.w600))),
              _conditionTypeTile(context, Icons.apps, 'App', 'Only from specific apps', ConditionType.app, {'apps': []}),
              _conditionTypeTile(context, Icons.person_outline, 'Sender', 'From a specific contact or sender name', ConditionType.sender, {'senders': []}),
              _conditionTypeTile(context, Icons.text_fields, 'Keyword', 'Text contains specific words', ConditionType.keyword, {'keywords': [], 'field': 'both'}),
              _conditionTypeTile(context, Icons.code, 'Regex', 'Match with a regular expression', ConditionType.regex, {'pattern': '', 'caseSensitive': false}),
              _conditionTypeTile(context, Icons.access_time, 'Time range', 'Only during certain hours/days', ConditionType.timeRange, {'start': '22:00', 'end': '07:00', 'days': [0,1,2,3,4,5,6]}),
              _conditionTypeTile(context, Icons.password, 'OTP detected', 'Contains a verification code', ConditionType.otpDetected, {}),
              _conditionTypeTile(context, Icons.smartphone, 'Screen state', 'Screen is on or off', ConditionType.screenState, {'state': 'off'}),
              _conditionTypeTile(context, Icons.volume_mute, 'Ringer mode', 'Phone is silent, normal, or vibrate', ConditionType.ringerMode, {'mode': 'silent'}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conditionTypeTile(BuildContext ctx, IconData icon, String title, String subtitle, ConditionType type, Map<String, dynamic> defaultParams) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7C4DFF)),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      onTap: () {
        Navigator.pop(ctx);
        setState(() => _conditions.add(Condition(type: type, params: defaultParams)));
      },
    );
  }

  void _showAddAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Add action', style: TextStyle(fontWeight: FontWeight.w600))),
              _actionTypeTile(context, Icons.summarize, 'Summarize', 'Run AI summary', ActionType.summarize, {}),
              _actionTypeTile(context, Icons.visibility_outlined, 'Add to Glance', 'Add to persistent summary', ActionType.addToGlance, {}),
              _actionTypeTile(context, Icons.clear, 'Dismiss', 'Silently remove notification', ActionType.dismiss, {}),
              _actionTypeTile(context, Icons.content_copy, 'Copy OTP', 'Copy verification code to clipboard', ActionType.copyOtp, {}),
              _actionTypeTile(context, Icons.record_voice_over, 'TTS readout', 'Speak the notification aloud', ActionType.ttsReadout, {}),
              _actionTypeTile(context, Icons.vibration, 'Custom vibration', 'Heartbeat, SOS, or double-tap', ActionType.customVibration, {'pattern': 'heartbeat'}),
              _actionTypeTile(context, Icons.webhook, 'Send webhook', 'POST JSON to a configured webhook', ActionType.webhook, {'webhookId': ''}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTypeTile(BuildContext ctx, IconData icon, String title, String subtitle, ActionType type, Map<String, dynamic> defaultParams) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7C4DFF)),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      onTap: () {
        Navigator.pop(ctx);
        setState(() => _actions.add(RuleAction(type: type, params: defaultParams)));
      },
    );
  }

  void _save() {
    if (_conditions.isEmpty || _actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A rule needs at least one condition and one action'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final rule = Rule(
      id: _id,
      name: _nameCtrl.text.trim().isEmpty ? 'New Rule' : _nameCtrl.text.trim(),
      enabled: _enabled,
      priority: _priority,
      conditions: _conditions,
      actions: _actions,
      aiTier: _aiTier,
    );
    final provider = context.read<RulesProvider>();
    if (widget.rule == null) { provider.addRule(rule); } else { provider.updateRule(rule); }
    Navigator.pop(context);
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF7C4DFF), side: const BorderSide(color: Color(0xFF7C4DFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  final int index;
  final Condition condition;
  final ValueChanged<Condition> onChanged;
  final VoidCallback onDelete;

  const _ConditionTile({required this.index, required this.condition, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _conditionIcon(condition.type),
                const SizedBox(width: 10),
                Expanded(child: Text(_conditionLabel(condition.type), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: 10),
            _buildEditor(context),
          ],
        ),
      ),
    );
  }

  Widget _conditionIcon(ConditionType t) {
    final icon = switch (t) {
      ConditionType.app => Icons.apps,
      ConditionType.sender => Icons.person_outline,
      ConditionType.keyword => Icons.text_fields,
      ConditionType.regex => Icons.code,
      ConditionType.timeRange => Icons.access_time,
      ConditionType.otpDetected => Icons.password,
      ConditionType.screenState => Icons.smartphone,
      ConditionType.ringerMode => Icons.volume_mute,
      _ => Icons.help_outline,
    };
    return CircleAvatar(radius: 16, backgroundColor: const Color(0xFF3A2E5A), child: Icon(icon, size: 16, color: const Color(0xFF7C4DFF)));
  }

  String _conditionLabel(ConditionType t) => switch (t) {
    ConditionType.app => 'From these apps',
    ConditionType.sender => 'From these senders',
    ConditionType.keyword => 'Contains keywords',
    ConditionType.regex => 'Matches regex',
    ConditionType.timeRange => 'During time range',
    ConditionType.otpDetected => 'OTP detected',
    ConditionType.screenState => 'Screen state',
    ConditionType.ringerMode => 'Ringer mode',
    _ => 'Condition',
  };

  Widget _buildEditor(BuildContext context) {
    switch (condition.type) {
      case ConditionType.app:
        return _AppConditionEditor(condition: condition, onChanged: onChanged);
      case ConditionType.sender:
        return _SenderConditionEditor(condition: condition, onChanged: onChanged);
      case ConditionType.keyword:
        return _KeywordConditionEditor(condition: condition, onChanged: onChanged);
      case ConditionType.regex:
        return _RegexConditionEditor(condition: condition, onChanged: onChanged);
      case ConditionType.timeRange:
        return _TimeRangeConditionEditor(condition: condition, onChanged: onChanged);
      case ConditionType.otpDetected:
        return const Text('Matches any 4–8 digit code', style: TextStyle(color: Colors.white38));
      case ConditionType.screenState:
        return _ScreenStateEditor(condition: condition, onChanged: onChanged);
      case ConditionType.ringerMode:
        return _RingerModeEditor(condition: condition, onChanged: onChanged);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _AppConditionEditor extends StatelessWidget {
  final Condition condition;
  final ValueChanged<Condition> onChanged;
  const _AppConditionEditor({required this.condition, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final apps = (condition.params['apps'] as List? ?? []).cast<String>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (apps.isNotEmpty)
          Wrap(
            spacing: 8, runSpacing: 8,
            children: apps.map((pkg) => InputChip(
              label: Text(pkg.split('.').last, style: const TextStyle(fontSize: 12)),
              onDeleted: () {
                final list = List<String>.from(apps)..remove(pkg);
                onChanged(Condition(type: condition.type, params: {...condition.params, 'apps': list}));
              },
            )).toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final selected = await Navigator.push<List<String>>(
              context, MaterialPageRoute(builder: (_) => const _FullAppPickerScreen(initialSelection: [])),
            );
            if (selected != null) {
              final list = List<String>.from(apps)..addAll(selected.where((s) => !apps.contains(s)));
              onChanged(Condition(type: condition.type, params: {...condition.params, 'apps': list}));
            }
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Choose apps'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7C4DFF)),
        ),
      ],
    );
  }
}

class _SenderConditionEditor extends StatelessWidget {
  final Condition condition;
  final ValueChanged<Condition> onChanged;
  const _SenderConditionEditor({required this.condition, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final senders = (condition.params['senders'] as List? ?? []).cast<String>();
    final ctrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ...senders.map((s) => InputChip(
              label: Text(s, style: const TextStyle(fontSize: 12)),
              onDeleted: () {
                final list = List<String>.from(senders)..remove(s);
                onChanged(Condition(type: condition.type, params: {...condition.params, 'senders': list}));
              },
            )),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: const InputDecoration(hintText: 'Add sender name'),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    final list = List<String>.from(senders)..add(v.trim());
                    onChanged(Condition(type: condition.type, params: {...condition.params, 'senders': list}));
                    ctrl.clear();
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  final list = List<String>.from(senders)..add(ctrl.text.trim());
                  onChanged(Condition(type: condition.type, params: {...condition.params, 'senders': list}));
                  ctrl.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _KeywordConditionEditor extends StatelessWidget {
  final Condition condition;
  final ValueChanged<Condition> onChanged;
  const _KeywordConditionEditor({required this.condition, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final keywords = (condition.params['keywords'] as List? ?? []).cast<String>();
    final field = condition.params['field']?.toString() ?? 'both';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'title', label: Text('Title')),
            ButtonSegment(value: 'text', label: Text('Body')),
            ButtonSegment(value: 'both', label: Text('Both')),
          ],
          selected: {field},
          onSelectionChanged: (s) => onChanged(Condition(type: condition.type, params: {...condition.params, 'field': s.first})),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ...keywords.map((k) => InputChip(
              label: Text(k, style: const TextStyle(fontSize: 12)),
              onDeleted: () {
                final list = List<String>.from(keywords)..remove(k);
                onChanged(Condition(type: condition.type, params: {...condition.params, 'keywords': list}));
              },
            )),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: const InputDecoration(hintText: 'Type keyword and press Enter'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              final list = List<String>.from(keywords)..add(v.trim());
              onChanged(Condition(type: condition.type, params: {...condition.params, 'keywords': list}));
            }
          },
        ),
      ],
    );
  }
}

class _RegexConditionEditor extends StatefulWidget {
  final Condition condition;
  final ValueChanged<Condition> onChanged;
  const _RegexConditionEditor({required this.condition, required this.onChanged});

  @override
  State<_RegexConditionEditor> createState() => _RegexConditionEditorState();
}

class _RegexConditionEditorState extends State<_RegexConditionEditor> {
  final _testCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final pattern = widget.condition.params['pattern']?.toString() ?? '';
    final caseSensitive = widget.condition.params['caseSensitive'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(hintText: 'Regular expression', prefixIcon: Icon(Icons.code)),
          controller: TextEditingController(text: pattern),
          onChanged: (v) => widget.onChanged(Condition(type: widget.condition.type, params: {...widget.condition.params, 'pattern': v})),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: caseSensitive,
              onChanged: (v) => widget.onChanged(Condition(type: widget.condition.type, params: {...widget.condition.params, 'caseSensitive': v == true})),
            ),
            const Text('Case sensitive', style: TextStyle(color: Colors.white54)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _testCtrl,
          decoration: InputDecoration(
            hintText: 'Test string…',
            suffixIcon: _testCtrl.text.isNotEmpty
                ? (_isMatch(pattern, caseSensitive, _testCtrl.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.cancel, color: Colors.redAccent))
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  bool _isMatch(String pattern, bool caseSensitive, String text) {
    try {
      final re = RegExp(pattern, caseSensitive: caseSensitive);
      return re.hasMatch(text);
    } catch (_) { return false; }
  }
}

class _TimeRangeConditionEditor extends StatelessWidget {
  final Condition condition;
  final ValueChanged<Condition> onChanged;
  const _TimeRangeConditionEditor({required this.condition, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final start = condition.params['start']?.toString() ?? '22:00';
    final end = condition.params['end']?.toString() ?? '07:00';
    final days = (condition.params['days'] as List? ?? [0,1,2,3,4,5,6]).cast<int>();
    final dayNames = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'From', prefixIcon: Icon(Icons.access_time)),
                controller: TextEditingController(text: start),
                onChanged: (v) => onChanged(Condition(type: condition.type, params: {...condition.params, 'start': v})),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'To', prefixIcon: Icon(Icons.access_time_filled)),
                controller: TextEditingController(text: end),
                onChanged: (v) => onChanged(Condition(type: condition.type, params: {...condition.params, 'end': v})),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: List.generate(7, (i) {
            final active = days.contains(i);
            return FilterChip(
              label: Text(dayNames[i], style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.white54)),
              selected: active,
              onSelected: (v) {
                final list = List<int>.from(days);
                if (v) { list.add(i); } else { list.remove(i); }
                onChanged(Condition(type: condition.type, params: {...condition.params, 'days': list}));
              },
              selectedColor: const Color(0xFF7C4DFF),
              backgroundColor: const Color(0xFF2A2A2A),
              checkmarkColor: Colors.white,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            );
          }),
        ),
      ],
    );
  }
}

class _ScreenStateEditor extends StatelessWidget {
  final Condition condition;
  final ValueChanged<Condition> onChanged;
  const _ScreenStateEditor({required this.condition, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final state = condition.params['state']?.toString() ?? 'off';
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'on', label: Text('Screen ON')),
        ButtonSegment(value: 'off', label: Text('Screen OFF')),
      ],
      selected: {state},
      onSelectionChanged: (s) => onChanged(Condition(type: condition.type, params: {...condition.params, 'state': s.first})),
    );
  }
}

class _RingerModeEditor extends StatelessWidget {
  final Condition condition;
  final ValueChanged<Condition> onChanged;
  const _RingerModeEditor({required this.condition, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final mode = condition.params['mode']?.toString() ?? 'silent';
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'silent', label: Text('Silent')),
        ButtonSegment(value: 'normal', label: Text('Normal')),
        ButtonSegment(value: 'vibrate', label: Text('Vibrate')),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(Condition(type: condition.type, params: {...condition.params, 'mode': s.first})),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final int index;
  final RuleAction action;
  final ValueChanged<RuleAction> onChanged;
  final VoidCallback onDelete;
  const _ActionTile({required this.index, required this.action, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _actionIcon(action.type),
                const SizedBox(width: 10),
                Expanded(child: Text(_actionLabel(action.type), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: 10),
            _buildEditor(context),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(ActionType t) {
    final icon = switch (t) {
      ActionType.summarize => Icons.summarize,
      ActionType.addToGlance => Icons.visibility_outlined,
      ActionType.dismiss => Icons.clear,
      ActionType.copyOtp => Icons.content_copy,
      ActionType.ttsReadout => Icons.record_voice_over,
      ActionType.customVibration => Icons.vibration,
      ActionType.webhook => Icons.webhook,
      _ => Icons.bolt,
    };
    return CircleAvatar(radius: 16, backgroundColor: const Color(0xFF3A2E5A), child: Icon(icon, size: 16, color: const Color(0xFF7C4DFF)));
  }

  String _actionLabel(ActionType t) => switch (t) {
    ActionType.summarize => 'Summarize',
    ActionType.addToGlance => 'Add to Glance',
    ActionType.dismiss => 'Dismiss',
    ActionType.copyOtp => 'Copy OTP',
    ActionType.ttsReadout => 'TTS readout',
    ActionType.customVibration => 'Custom vibration',
    ActionType.webhook => 'Send webhook',
    _ => 'Action',
  };

  Widget _buildEditor(BuildContext context) {
    switch (action.type) {
      case ActionType.customVibration:
        final pattern = action.params['pattern']?.toString() ?? 'heartbeat';
        return SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'heartbeat', label: Text('Heartbeat')),
            ButtonSegment(value: 'sos', label: Text('SOS')),
            ButtonSegment(value: 'doubleTap', label: Text('Double-tap')),
          ],
          selected: {pattern},
          onSelectionChanged: (s) => onChanged(RuleAction(type: action.type, params: {...action.params, 'pattern': s.first})),
        );
      case ActionType.webhook:
        final webhooks = context.watch<WebhooksProvider>().webhooks.where((w) => w.enabled).toList();
        final currentId = action.params['webhookId']?.toString() ?? '';
        if (webhooks.isEmpty) {
          return const Text('No webhooks configured. Add one in Settings → Webhooks.', style: TextStyle(color: Colors.white38));
        }
        return DropdownButtonFormField<String>(
          value: currentId.isEmpty ? null : currentId,
          decoration: const InputDecoration(labelText: 'Select webhook'),
          items: webhooks.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => onChanged(RuleAction(type: action.type, params: {...action.params, 'webhookId': v})),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _FullAppPickerScreen extends StatefulWidget {
  final List<String> initialSelection;
  const _FullAppPickerScreen({required this.initialSelection});

  @override
  State<_FullAppPickerScreen> createState() => _FullAppPickerScreenState();
}

class _FullAppPickerScreenState extends State<_FullAppPickerScreen> {
  List<Map<String, String>> _apps = [];
  final Set<String> _selected = {};
  String _search = '';
  final _searchCtrl = TextEditingController();
  static final Map<String, Future<Uint8List?>> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelection);
    _load();
  }

  Future<void> _load() async {
    final apps = await PermissionsService.getInstalledApps();
    setState(() => _apps = apps);
  }

  List<Map<String, String>> get _filtered {
    if (_search.isEmpty) return _apps;
    final q = _search.toLowerCase();
    return _apps.where((a) =>
      (a['appName'] ?? '').toLowerCase().contains(q) ||
      (a['packageName'] ?? '').toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_selected.length} selected'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search ${_apps.length} apps…',
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, color: Colors.white38, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                  : null,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: _apps.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final app = _filtered[i];
                    final pkg = app['packageName']!;
                    final name = app['appName']!;
                    final sel = _selected.contains(pkg);
                    return CheckboxListTile(
                      secondary: _AppIconMini(pkg: pkg, name: name),
                      title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(pkg, style: const TextStyle(fontSize: 11, color: Colors.white24), overflow: TextOverflow.ellipsis),
                      value: sel,
                      onChanged: (v) => setState(() {
                        if (v == true) _selected.add(pkg); else _selected.remove(pkg);
                      }),
                      activeColor: const Color(0xFF7C4DFF),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _AppIconMini extends StatelessWidget {
  final String pkg;
  final String name;
  static final Map<String, Future<Uint8List?>> _cache = {};

  const _AppIconMini({required this.pkg, required this.name});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _cache.putIfAbsent(pkg, () => PermissionsService.getAppIcon(pkg)),
      builder: (_, snap) {
        if (snap.hasData && snap.data != null) {
          return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(snap.data!, width: 36, height: 36, fit: BoxFit.cover));
        }
        final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final colors = [const Color(0xFF4CAF50), const Color(0xFF2196F3), const Color(0xFF9C27B0), const Color(0xFFFF5722), const Color(0xFF00BCD4), const Color(0xFFFF9800), const Color(0xFF607D8B), const Color(0xFFE91E63)];
        final color = colors[pkg.hashCode.abs() % colors.length];
        return Container(width: 36, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        );
      },
    );
  }
}
