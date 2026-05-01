import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/webhooks_provider.dart';
import '../models/webhook_config.dart';
import 'dart:math';

class WebhooksScreen extends StatelessWidget {
  const WebhooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final webhooks = context.watch<WebhooksProvider>().webhooks;

    return Scaffold(
      appBar: AppBar(title: const Text('Webhooks')),
      body: webhooks.isEmpty
          ? _emptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: webhooks.length,
              itemBuilder: (context, index) {
                final wh = webhooks[index];
                return _WebhookCard(webhook: wh);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add webhook'),
        backgroundColor: const Color(0xFF7C4DFF),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.webhook_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No webhooks configured', style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Send notifications as JSON to Home Assistant, IFTTT, Zapier, or your server',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showEditor(BuildContext context, {WebhookConfig? webhook}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WebhookEditorSheet(webhook: webhook),
    );
  }
}

class _WebhookCard extends StatelessWidget {
  final WebhookConfig webhook;
  const _WebhookCard({required this.webhook});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WebhooksProvider>();
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
                    webhook.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: webhook.enabled ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
                Switch(
                  value: webhook.enabled,
                  onChanged: (_) => provider.toggleWebhook(webhook.id),
                  activeColor: const Color(0xFF7C4DFF),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(webhook.url, style: const TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditor(context, webhook: webhook),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, provider, webhook),
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

  void _showEditor(BuildContext context, {WebhookConfig? webhook}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WebhookEditorSheet(webhook: webhook),
    );
  }

  void _confirmDelete(BuildContext context, WebhooksProvider provider, WebhookConfig webhook) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete webhook?'),
        content: Text('"${webhook.name}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { provider.deleteWebhook(webhook.id); Navigator.pop(context); },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _WebhookEditorSheet extends StatefulWidget {
  final WebhookConfig? webhook;
  const _WebhookEditorSheet({this.webhook});

  @override
  State<_WebhookEditorSheet> createState() => _WebhookEditorSheetState();
}

class _WebhookEditorSheetState extends State<_WebhookEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _headerKeyCtrl;
  late final TextEditingController _headerValCtrl;

  final Map<String, String> _headers = {};

  @override
  void initState() {
    super.initState();
    final w = widget.webhook;
    _nameCtrl = TextEditingController(text: w?.name ?? '');
    _urlCtrl = TextEditingController(text: w?.url ?? '');
    _bodyCtrl = TextEditingController(text: w?.bodyTemplate ?? '{"app":"{app_name}","title":"{title}","text":"{text}"}');
    _headerKeyCtrl = TextEditingController();
    _headerValCtrl = TextEditingController();
    if (w != null) _headers.addAll(w.headers);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Webhook', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(labelText: 'URL'),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            decoration: const InputDecoration(labelText: 'Body template (JSON)'),
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          Text(
            'Variables: {app_name}, {title}, {text}, {timestamp}, {package}',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text('Headers', style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._headers.entries.map((e) => Chip(
                label: Text('${e.key}: ${e.value}'),
                onDeleted: () => setState(() => _headers.remove(e.key)),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _headerKeyCtrl,
                  decoration: const InputDecoration(hintText: 'Key'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _headerValCtrl,
                  decoration: const InputDecoration(hintText: 'Value'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_headerKeyCtrl.text.isNotEmpty && _headerValCtrl.text.isNotEmpty) {
                    setState(() {
                      _headers[_headerKeyCtrl.text] = _headerValCtrl.text;
                      _headerKeyCtrl.clear();
                      _headerValCtrl.clear();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and URL are required')), backgroundColor: Colors.redAccent,
      );
      return;
    }
    final provider = context.read<WebhooksProvider>();
    final wh = WebhookConfig(
      id: widget.webhook?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      url: url,
      bodyTemplate: _bodyCtrl.text.trim(),
      headers: Map.from(_headers),
      enabled: widget.webhook?.enabled ?? true,
    );
    if (widget.webhook == null) {
      provider.addWebhook(wh);
    } else {
      provider.updateWebhook(wh);
    }
    Navigator.pop(context);
  }
}
