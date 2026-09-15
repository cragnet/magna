import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rule.dart';

class RulesProvider extends ChangeNotifier {
  List<Rule> _rules = [];
  List<Rule> get rules => List.unmodifiable(_rules);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('magna_rules');
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _rules = list.map((e) => Rule.fromJson(e as Map<String, dynamic>)).toList();
        _rules.sort((a, b) => b.priority.compareTo(a.priority));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_rules.map((r) => r.toJson()).toList());
    await prefs.setString('magna_rules', raw);
  }

  Future<void> addRule(Rule rule) async {
    _rules.add(rule);
    _rules.sort((a, b) => b.priority.compareTo(a.priority));
    await _save();
    notifyListeners();
  }

  Future<void> updateRule(Rule rule) async {
    final idx = _rules.indexWhere((r) => r.id == rule.id);
    if (idx >= 0) {
      _rules[idx] = rule;
      _rules.sort((a, b) => b.priority.compareTo(a.priority));
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteRule(String id) async {
    _rules.removeWhere((r) => r.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> toggleRule(String id) async {
    final idx = _rules.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      _rules[idx] = _rules[idx].copyWith(enabled: !_rules[idx].enabled);
      await _save();
      notifyListeners();
    }
  }

  Future<void> reorderRules(List<Rule> newOrder) async {
    _rules = List.from(newOrder);
    await _save();
    notifyListeners();
  }
}
