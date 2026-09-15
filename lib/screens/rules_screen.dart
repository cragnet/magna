import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rules_provider.dart';
import '../models/rule.dart';
import 'rule_editor_screen.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = context.watch<RulesProvider>().rules;

    return Scaffold(
      appBar: AppBar(title: const Text('Rules')),
      body: rules.isEmpty
          ? _emptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return _RuleCard(rule: rule);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RuleEditorScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Rule'),
        backgroundColor: const Color(0xFF7C4DFF),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rule_folder_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No rules yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Create rules to automate how notifications are handled',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RuleEditorScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create your first rule'),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final Rule rule;
  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RulesProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: rule.enabled ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
                Switch(
                  value: rule.enabled,
                  onChanged: (_) => provider.toggleRule(rule.id),
                  activeColor: const Color(0xFF7C4DFF),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge('Priority ${rule.priority}', Icons.sort),
                _Badge('${rule.conditions.length} condition${rule.conditions.length == 1 ? '' : 's'}', Icons.filter_list),
                _Badge('${rule.actions.length} action${rule.actions.length == 1 ? '' : 's'}', Icons.bolt),
                _Badge(rule.aiTier.name, Icons.memory),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RuleEditorScreen(rule: rule)),
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, provider, rule),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, RulesProvider provider, Rule rule) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete rule?'),
        content: Text('"${rule.name}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteRule(rule.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Badge(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }
}
