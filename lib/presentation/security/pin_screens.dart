import 'package:expense_tracker/presentation/notifiers/budget_notifier.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:expense_tracker/presentation/security/pin_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Number pad with dots for the digits entered. [onSubmit] returns an error
// message to show (the entry is cleared), or null on success.
class PinPad extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Future<String?> Function(String pin) onSubmit;

  const PinPad({
    super.key,
    required this.title,
    this.subtitle,
    required this.onSubmit,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  String? _error;
  bool _busy = false;

  void _press(String digit) {
    if (_busy || _pin.length >= maxPinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_pin.length < minPinLength) {
      setState(() => _error = 'Enter $minPinLength–$maxPinLength digits');
      return;
    }
    setState(() => _busy = true);
    final error = await widget.onSubmit(_pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      if (error != null) _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget key(String label, {VoidCallback? onTap, Widget? child}) => Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 72,
        height: 72,
        child: TextButton(
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
            textStyle: theme.textTheme.headlineSmall,
          ),
          onPressed: onTap ?? () => _press(label),
          child: child ?? Text(label),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.headlineSmall),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(widget.subtitle!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 24),
        Semantics(
          label: '${_pin.length} digits entered',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < maxPinLength; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? colors.primary : null,
                    border: Border.all(
                      color: i < minPinLength || i < _pin.length
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: Center(
            child: Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.error),
            ),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key(
              'delete',
              onTap: _backspace,
              child: const Icon(
                Icons.backspace_outlined,
                semanticLabel: 'Delete',
              ),
            ),
            key('0'),
            key(
              'ok',
              onTap: _submit,
              child: const Icon(Icons.check, semanticLabel: 'OK'),
            ),
          ],
        ),
      ],
    );
  }
}

// Covers the app until the right PIN is entered.
class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  bool _confirmingReset = false;

  Future<String?> _unlock(String pin) async {
    final notifier = ref.read(pinLockProvider.notifier);
    final wait = notifier.lockoutRemaining();
    if (wait != null) return 'Too many tries. Wait ${wait.inSeconds + 1} s.';
    if (notifier.unlock(pin)) return null;
    final left = maxFailedAttempts - ref.read(pinLockProvider).failedAttempts;
    return ref.read(pinLockProvider).lockedOutUntil != null
        ? 'Too many tries. Wait ${lockoutDuration.inSeconds} s.'
        : 'Wrong PIN. $left tries left.';
  }

  // The PIN can't be recovered, so forgetting it means starting over.
  Future<void> _resetApp() async {
    await ref.read(transactionRepositoryProvider).deleteAllTransactions();
    await ref.read(budgetRepositoryProvider).deleteAllBudgets();
    ref.invalidate(transactionNotifierProvider);
    ref.invalidate(budgetNotifierProvider);
    await ref.read(pinLockProvider.notifier).removePin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _confirmingReset
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "The PIN can't be recovered. You can remove the lock "
                        'by deleting all transactions and budgets on this '
                        'device (categories and settings are kept). Restore a '
                        'backup afterwards if you have one.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: _resetApp,
                        child: const Text('Delete data and remove lock'),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _confirmingReset = false),
                        child: const Text('Back'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 40),
                      const SizedBox(height: 12),
                      PinPad(title: 'Enter PIN', onSubmit: _unlock),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            setState(() => _confirmingReset = true),
                        child: const Text('Forgot PIN?'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Asks for a new PIN twice; pops true once it is saved.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _first;
  // Shown on the fresh pad after a mismatch; the old pad (and its error
  // text) is replaced when the step changes.
  bool _mismatch = false;

  Future<String?> _submit(String pin) async {
    if (_first == null) {
      setState(() {
        _first = pin;
        _mismatch = false;
      });
      return null;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _mismatch = true;
      });
      return null;
    }
    await ref.read(pinLockProvider.notifier).setPin(pin);
    if (mounted) Navigator.of(context).pop(true);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set PIN')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PinPad(
            // A new key resets the pad between the two steps.
            key: ValueKey(_first == null),
            title: _first == null ? 'Choose a PIN' : 'Confirm your PIN',
            subtitle: _mismatch
                ? "PINs didn't match. Start again."
                : _first == null
                ? '$minPinLength–$maxPinLength digits'
                : 'Enter the same PIN again',
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

// Asks for the current PIN; pops true if it is right.
class PinVerifyScreen extends ConsumerWidget {
  final String reason;

  const PinVerifyScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm PIN')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PinPad(
            title: 'Enter current PIN',
            subtitle: reason,
            onSubmit: (pin) async {
              if (!ref.read(pinLockProvider.notifier).verify(pin)) {
                return 'Wrong PIN';
              }
              Navigator.of(context).pop(true);
              return null;
            },
          ),
        ),
      ),
    );
  }
}

// Shows the lock screen over the whole app while locked, and locks again
// when the app comes back after [relockAfter] in the background.
class LockGate extends ConsumerStatefulWidget {
  final Widget child;

  const LockGate({super.key, required this.child});

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  late final AppLifecycleListener _listener;
  DateTime? _hiddenAt;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onHide: () => _hiddenAt = ref.read(clockProvider)(),
      onShow: () {
        final hiddenAt = _hiddenAt;
        _hiddenAt = null;
        if (hiddenAt != null &&
            ref.read(clockProvider)().difference(hiddenAt) >= relockAfter) {
          ref.read(pinLockProvider.notifier).lock();
        }
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(pinLockProvider.select((s) => s.locked));
    return Stack(
      children: [
        // Kept in the tree (and its navigation state with it), but hidden
        // from view and from assistive technology while locked.
        ExcludeSemantics(
          excluding: locked,
          child: Offstage(offstage: locked, child: widget.child),
        ),
        if (locked) const Positioned.fill(child: PinLockScreen()),
      ],
    );
  }
}
