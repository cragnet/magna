import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class BiometricLock extends StatefulWidget {
  final Widget child;
  const BiometricLock({super.key, required this.child});

  @override
  State<BiometricLock> createState() => _BiometricLockState();
}

class _BiometricLockState extends State<BiometricLock> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _locked = false;
  bool _checking = false;
  DateTime? _lastUnlock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maybeLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeLock();
    }
    if (state == AppLifecycleState.paused) {
      // Reset unlock time so next resume triggers lock
      // (but keep it in memory only, not persisted)
    }
  }

  Future<void> _maybeLock() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.biometricEnabled) return;
    if (_locked || _checking) return;

    final timeout = Duration(minutes: settings.biometricTimeoutMinutes);
    if (_lastUnlock != null && DateTime.now().difference(_lastUnlock!) < timeout) {
      return;
    }

    final available = await _auth.canCheckBiometrics;
    if (!available) return;

    setState(() => _locked = true);
  }

  Future<void> _authenticate() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Unlock Magna',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (success && mounted) {
        setState(() {
          _locked = false;
          _lastUnlock = DateTime.now();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Material(
            color: const Color(0xFF121212),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Color(0xFF7C4DFF)),
                  const SizedBox(height: 24),
                  const Text('Magna is locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Authenticate to continue', style: TextStyle(color: Colors.white38)),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: _checking
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.fingerprint),
                    label: Text(_checking ? 'Verifying...' : 'Unlock'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
