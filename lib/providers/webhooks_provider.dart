import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/webhook_config.dart';

class WebhooksProvider extends ChangeNotifier {
  List<WebhookConfig> _webhooks = [];
  List<WebhookConfig> get webhooks => List.unmodifiable(_webhooks);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('magna_webhooks');
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _webhooks = list.map((e) => WebhookConfig.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_webhooks.map((w) => w.toJson()).toList());
    await prefs.setString('magna_webhooks', raw);
  }

  Future<void> addWebhook(WebhookConfig webhook) async {
    _webhooks.add(webhook);
    await _save();
    notifyListeners();
  }

  Future<void> updateWebhook(WebhookConfig webhook) async {
    final idx = _webhooks.indexWhere((w) => w.id == webhook.id);
    if (idx >= 0) {
      _webhooks[idx] = webhook;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteWebhook(String id) async {
    _webhooks.removeWhere((w) => w.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> toggleWebhook(String id) async {
    final idx = _webhooks.indexWhere((w) => w.id == id);
    if (idx >= 0) {
      _webhooks[idx] = _webhooks[idx].copyWith(enabled: !_webhooks[idx].enabled);
      await _save();
      notifyListeners();
    }
  }
}
