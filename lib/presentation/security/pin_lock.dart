import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:expense_tracker/presentation/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int minPinLength = 4;
const int maxPinLength = 6;
const int maxFailedAttempts = 5;
const Duration lockoutDuration = Duration(seconds: 30);
// How long the app may sit in the background before asking again.
const Duration relockAfter = Duration(minutes: 1);

// Overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

// Only a salted, iterated SHA-256 of the PIN is stored. With 4–6 digits this
// is a privacy screen, not encryption: the data itself is not encrypted.
String hashPin(String pin, String salt, {int rounds = 10000}) {
  var digest = sha256.convert(utf8.encode('$salt:$pin')).bytes;
  for (var i = 1; i < rounds; i++) {
    digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
  }
  return base64Encode(digest);
}

String newSalt() {
  final random = Random.secure();
  return base64Encode(List<int>.generate(16, (_) => random.nextInt(256)));
}

bool isValidPin(String pin) =>
    RegExp('^\\d{$minPinLength,$maxPinLength}\$').hasMatch(pin);

class PinLockState {
  final bool enabled;
  final bool locked;
  final int failedAttempts;
  final DateTime? lockedOutUntil;

  const PinLockState({
    required this.enabled,
    required this.locked,
    this.failedAttempts = 0,
    this.lockedOutUntil,
  });
}

class PinLockNotifier extends Notifier<PinLockState> {
  static const String _hashKey = 'pinHash';
  static const String _saltKey = 'pinSalt';

  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  PinLockState build() {
    final enabled = ref.watch(settingsStoreProvider).read(_hashKey) != null;
    // Locked at startup whenever a PIN is set.
    return PinLockState(enabled: enabled, locked: enabled);
  }

  bool _matches(String pin) {
    final hash = _store.read(_hashKey);
    final salt = _store.read(_saltKey);
    return hash != null && salt != null && hashPin(pin, salt) == hash;
  }

  // Checks [pin] without unlocking, e.g. before changing or removing it.
  bool verify(String pin) => _matches(pin);

  // Time left before another attempt is allowed, or null.
  Duration? lockoutRemaining() {
    final until = state.lockedOutUntil;
    if (until == null) return null;
    final left = until.difference(ref.read(clockProvider)());
    return left.isNegative ? null : left;
  }

  // Returns true and unlocks if [pin] is right. After [maxFailedAttempts]
  // wrong tries, attempts pause for [lockoutDuration].
  bool unlock(String pin) {
    if (lockoutRemaining() != null) return false;
    if (_matches(pin)) {
      state = PinLockState(enabled: true, locked: false);
      return true;
    }
    final failed = state.failedAttempts + 1;
    state = PinLockState(
      enabled: true,
      locked: true,
      failedAttempts: failed >= maxFailedAttempts ? 0 : failed,
      lockedOutUntil: failed >= maxFailedAttempts
          ? ref.read(clockProvider)().add(lockoutDuration)
          : null,
    );
    return false;
  }

  void lock() {
    if (state.enabled) {
      state = PinLockState(enabled: true, locked: true);
    }
  }

  Future<void> setPin(String pin) async {
    assert(isValidPin(pin));
    final salt = newSalt();
    await _store.write(_saltKey, salt);
    await _store.write(_hashKey, hashPin(pin, salt));
    state = const PinLockState(enabled: true, locked: false);
  }

  Future<void> removePin() async {
    await _store.remove(_hashKey);
    await _store.remove(_saltKey);
    state = const PinLockState(enabled: false, locked: false);
  }
}

final pinLockProvider = NotifierProvider<PinLockNotifier, PinLockState>(
  PinLockNotifier.new,
);
