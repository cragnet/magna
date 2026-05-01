import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../providers/rules_provider.dart';
import '../providers/settings_provider.dart';
import '../models/rule.dart';
import '../models/condition.dart';
import '../models/action.dart';
import '../services/permissions_service.dart';
import 'app_selector_screen.dart';

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

  final List<Map<String, String>> _installedApps = [];

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
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await PermissionsService.getInstalledApps();
    setState(() => _installedApps.addAll(apps));
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
            _section('Name'),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Rule name'),
            ),
            const SizedBox(height: 24),
            _section('Priority'),
            Slider(
              value: _priority.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: _priority.toString(),
              onChanged: (v) => setState(() => _priority = v.round()),
              activeColor: const Color(0xFF7C4DFF),
            ),
            const SizedBox(height: 24),
            _section('AI Tier'),
            SegmentedButton<AiTier>(
              segments: const [
                ButtonSegment(value: AiTier.local, label: Text('Local')),
                ButtonSegment(value: AiTier.cloud, label: Text('Cloud')),
                ButtonSegment(value: AiTier.auto, label: Text('Auto')),
              ],
              selected: {_aiTier},
              onSelectionChanged: (s) => setState(() => _aiTier = s.first),
            ),
            const SizedBox(height: 24),
            _section('Conditions'),
            ..._conditions.asMap().entries.map((e) => _ConditionTile(
              index: e.key,
              condition: e.value,
              apps: _installedApps,
              onChanged: (c) => setState(() => _conditions[e.key] = c),
              onDelete: () => setState(() => _conditions.removeAt(e.key)),
            )),
            const SizedBox(height: 8),
            _AddButton('Add condition', () => _addCondition()),
            const SizedBox(height: 24),
            _section('Actions'),
            ..._actions.asMap().entries.map((e) => _ActionTile(
              index: e.key,
              action: e.value,
              onChanged: (a) => setState(() => _actions[e.key] = a),
              onDelete: () => setState(() => _actions.removeAt(e.key)),
            )),
            const SizedBox(height: 8),
            _AddButton('Add action', () => _addRuleAction()),
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

  void _addCondition() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Choose condition type', style: TextStyle(fontWeight: FontWeight.w600))),
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('App'),
              subtitle: const Text('Match specific apps'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _conditions.add(Condition(type: ConditionType.app, params: {'apps': []})));
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Keyword'),
              subtitle: const Text('Match text containing keywords'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _conditions.add(Condition(type: ConditionType.keyword, params: {'keywords': []})));
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Regex'),
              subtitle: const Text('Match with a regular expression'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _conditions.add(Condition(type: ConditionType.regex, params: {'pattern': ''})));
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time range'),
              subtitle: const Text('Match during specific hours/days'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _conditions.add(Condition(type: ConditionType.timeRange, params: {
                  'start': '09:00',
                  'end': '17:00',
                  'days': [0,1,2,3,4],
                })));
              },
            ),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('OTP detected'),
              subtitle: const Text('Match notifications containing OTP codes'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _conditions.add(Condition(type: ConditionType.otpDetected, params: {})));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addRuleAction() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Choose action type', style: TextStyle(fontWeight: FontWeight.w600))),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Add to Glance'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _actions.add(RuleAction(type: ActionType.addToGlance, params: {})));
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Dismiss'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _actions.add(RuleAction(type: ActionType.dismiss, params: {})));
              },
            ),
            ListTile(
              leading: const Icon(Icons.summarize),
              title: const Text('Summarize'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _actions.add(RuleAction(type: ActionType.summarize, params: {})));
              },
            ),
          ],
        ),
      ),
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
    if (widget.rule == null) {
      provider.addRule(rule);
    } else {
      provider.updateRule(rule);
    }
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
        foregroundColor: const Color(0xFF7C4DFF),
        side: const BorderSide(color: Color(0xFF7C4DFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  final int index;
  final Condition condition;
  final List<Map<String, String>> apps;
  final ValueChanged<Condition> onChanged;
  final VoidCallback onDelete;

  const _ConditionTile({required this.index, required this.condition, required this.apps, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Condition ${index + 1} · ${condition.type.name}', style: const TextStyle(fontWeight: FontWeight.w600))),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: 8),
            if (condition.type == ConditionType.app) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...(condition.params['apps'] as List? ?? []).map((pkg) {
                    final app = apps.firstWhereOrNull((a) => a['packageName'] == pkg);
                    return Chip(
                      label: Text(app?['appName'] ?? pkg),
                      onDeleted: () {
                        final list = List<String>.from(condition.params['apps'] as List? ?? []);
                        list.remove(pkg);
                        onChanged(Condition(type: condition.type, params: {...condition.params, 'apps': list}));
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Add app'),
                    onPressed: () async {
                      final selected = await Navigator.push<List<String>>(
                        context,
                        MaterialPageRoute(builder: (_) => const _MiniAppPicker()),
                      );
                      if (selected != null) {
                        final list = List<String>.from(condition.params['apps'] as List? ?? []);
                        list.addAll(selected.where((s) => !list.contains(s)));
                        onChanged(Condition(type: condition.type, params: {...condition.params, 'apps': list}));
                      }
                    },
                  ),
                ],
              ),
            ],
            if (condition.type == ConditionType.keyword) ...[
              TextField(
                decoration: const InputDecoration(hintText: 'Enter keywords separated by commas'),
                controller: TextEditingController(
                  text: (condition.params['keywords'] as List? ?? []).join(', '),
                ),
                onChanged: (v) {
                  final list = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  onChanged(Condition(type: condition.type, params: {...condition.params, 'keywords': list}));
                },
              ),
            ],
            if (condition.type == ConditionType.regex) ...[
              TextField(
                decoration: const InputDecoration(hintText: 'Regular expression pattern'),
                controller: TextEditingController(text: condition.params['pattern']?.toString() ?? ''),
                onChanged: (v) => onChanged(Condition(type: condition.type, params: {...condition.params, 'pattern': v})),
              ),
            ],
            if (condition.type == ConditionType.timeRange) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Start (HH:MM)'),
                      controller: TextEditingController(text: condition.params['start']?.toString() ?? '09:00'),
                      onChanged: (v) => onChanged(Condition(type: condition.type, params: {...condition.params, 'start': v})),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'End (HH:MM)'),
                      controller: TextEditingController(text: condition.params['end']?.toString() ?? '17:00'),
                      onChanged: (v) => onChanged(Condition(type: condition.type, params: {...condition.params, 'end': v})),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text('Action ${index + 1} · ${action.type.name}', style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _MiniAppPicker extends StatelessWidget {
  const _MiniAppPicker();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: PermissionsService.getInstalledApps(),
      builder: (context, snapshot) {
        final apps = snapshot.data ?? [];
        final selected = <String>{};
        return StatefulBuilder(
          builder: (context, setState) => Scaffold(
            appBar: AppBar(
              title: const Text('Select apps'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, selected.toList()),
                  child: const Text('Done', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            body: ListView.builder(
              itemCount: apps.length,
              itemBuilder: (_, i) {
                final pkg = apps[i]['packageName']!;
                final name = apps[i]['appName']!;
                return CheckboxListTile(
                  title: Text(name),
                  subtitle: Text(pkg, style: const TextStyle(fontSize: 12, color: Colors.white38)),
                  value: selected.contains(pkg),
                  onChanged: (v) => setState(() {
                    if (v == true) selected.add(pkg);
                    else selected.remove(pkg);
                  }),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
