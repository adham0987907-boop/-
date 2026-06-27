import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vault_service.dart';
import 'home_screen.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _confirming = false;
  String? _error;

  static const int _pinLength = 4;

  List<String> get _currentPin => _confirming ? _confirmPin : _pin;

  void _onKeyPress(String key) {
    if (_currentPin.length >= _pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentPin.add(key);
      _error = null;
    });

    if (_currentPin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 200), _next);
    }
  }

  void _onDelete() {
    if (_currentPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _currentPin.removeLast());
  }

  Future<void> _next() async {
    if (!_confirming) {
      setState(() => _confirming = true);
    } else {
      if (_pin.join() == _confirmPin.join()) {
        await VaultService.instance.setPin(_pin.join());
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _error = 'الـ PIN غير متطابق، حاول مرة أخرى';
          _confirmPin.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Icon(Icons.security, color: Colors.white, size: 60),
            const SizedBox(height: 24),
            Text(
              _confirming ? 'أكد الـ PIN' : 'اختر PIN من 4 أرقام',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _confirming
                  ? 'أدخل الـ PIN مرة تانية للتأكيد'
                  : 'هتحتاجه عشان تفتح الخزنة',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 40),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _currentPin.length;
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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const Spacer(),
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
              const SizedBox(width: 72, height: 72),
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
}    if (_currentPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _currentPin.removeLast());
  }

  Future<void> _next() async {
    if (!_confirming) {
      setState(() => _confirming = true);
    } else {
      if (_pin.join() == _confirmPin.join()) {
        await VaultService.instance.setPin(_pin.join());
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _error = 'الـ PIN غير متطابق، حاول مرة أخرى';
          _confirmPin.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Icon(Icons.security, color: Colors.white, size: 60),
            const SizedBox(height: 24),
            Text(
              _confirming ? 'أكد الـ PIN' : 'اختر PIN من 4 أرقام',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _confirming
                  ? 'أدخل الـ PIN مرة تانية للتأكيد'
                  : 'هتحتاجه عشان تفتح الخزنة',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 40),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _currentPin.length;
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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const Spacer(),
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
              const SizedBox(width: 72, height: 72),
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
