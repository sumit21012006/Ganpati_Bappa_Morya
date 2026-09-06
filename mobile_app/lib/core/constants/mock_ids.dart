import 'dart:math';

/// Generates realistic-looking temporary identifiers for DEMO mode only.
///
/// Once NestJS is live, all IDs come from PostgreSQL sequences/UUIDs —
/// these generators exist purely so mock flows can be demonstrated.
class MockIds {
  MockIds._();

  static final Random _random = Random();

  static String _digits(int count) =>
      List.generate(count, (_) => _random.nextInt(10)).join();

  static String inspection() => 'INSP-2026-${_digits(5)}';

  static String caseId() => 'LM/2026/${_digits(4)}';

  static String notice() => 'NOT-${_digits(6)}';

  static String sample() => 'SMP-${_digits(5)}';

  static String selfCheck() => 'SC-${_digits(6)}';

  static String payment() => 'PAY-${_digits(8)}';
}
