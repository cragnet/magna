import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/permissions_service.dart';
import '../models/glance_entry.dart';

class GlanceScreen extends StatefulWidget {
  const GlanceScreen({super.key});

  @override
  State<GlanceScreen> createState() => _GlanceScreenState();
}

class _GlanceScreenState extends State<GlanceScreen> {
  List<GlanceEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final raw = await PermissionsService.getGlanceEntries();
      final list = jsonDecode(raw) as List;
      setState(() {
        _entries = list.map((e) => GlanceEntry.fromJson(e as Map<String, dynamic>)).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _clear() async {
    await PermissionsService.clearGlance();
    setState(() => _entries = []);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Glance cleared'), backgroundColor: Color(0xFF7C4DFF)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glance'),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : _entries.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    final dt = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(
                          entry.appName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(entry.title),
                        ),
                        trailing: Text(
                          DateFormat.Hm().format(dt),
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility_off_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Glance is empty', style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Notifications will appear here when Glance is enabled',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
