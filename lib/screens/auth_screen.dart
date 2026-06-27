import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vault_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'setup_pin_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with WidgetsBindingObserver {
  final List<String> _enteredPin = [];
  bool _loading = true;
  bool _hasPinSet = false;
  bool _biometricAvailable = false;
  String? _error;
  bool _shaking = false;

  static const int _pinLength = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _init() async {
    final hasPinSet = await VaultService.instance.hasPinSet();
    final biometricAvail = await AuthService.instance.isBiometricAvailable();

    setState(() {
      _hasPinSet = hasPinSet;
      _biometricAvailable = biometricAvail;
      _loading = false;
    });

    if (!hasPinSet) {
      _goToSetup();
    } else if (biometricAvail) {
      _tryBiometric();
    }
  }

  void _goToSetup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SetupPinScreen()),
      );
    });
  }

  Future<void> _tryBiometric() async {
    final success = await AuthService.instance.authenticateWithBiometrics();
    if (success && mounted) _unlock();
  }

  void _onKeyPress(String key) {
    if (_enteredPin.length >= _pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin.add(key);
      _error = null;
    });

    if (_enteredPin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _enteredPin.removeLast());
  }

  Future<void> _verifyPin() async {
    final pin = _enteredPin.join();
    final valid = await VaultService.instance.verifyPin(pin);

    if (valid) {
      _unlock();
    } else {
      _shake();
    }
  }

  void _shake() {
    HapticFeedback.heavyImpact();
    setState(() {
      _shaking = true;
      _error = 'PIN خاطئ، حاول مرة أخرى';
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _shaking = false;
          _enteredPin.clear();
        });
      }
    });
  }

  void _unlock() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Logo / icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.lock_outline, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'أدخل الـ PIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            // PIN dots
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: _shaking
                  ? Matrix4.translationValues(10, 0, 0)
                  : Matrix4.identity(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ],
            const Spacer(),
            // Numpad
            _buildNumpad(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildNumRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildNumRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildNumRow(['7', '8', '9']),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Biometric button
              SizedBox(
                width: 72,
                height: 72,
                child: _biometricAvailable
                    ? _NumKey(
                        child: const Icon(Icons.fingerprint, size: 32),
                        onTap: _tryBiometric,
                      )
                    : const SizedBox(),
              ),
              _NumKey(label: '0', onTap: () => _onKeyPress('0')),
              SizedBox(
                width: 72,
                height: 72,
                child: _NumKey(
                  child: const Icon(Icons.backspace_outlined, size: 24),
                  onTap: _onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys
          .map((k) => _NumKey(label: k, onTap: () => _onKeyPress(k)))
          .toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback onTap;

  const _NumKey({this.label, this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
        ),
        alignment: Alignment.center,
        child: child ??
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
            ),
      ),
    );
  }
}
