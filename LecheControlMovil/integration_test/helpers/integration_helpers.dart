import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Shared wait/pause helpers for device integration tests.
///
/// Use [integrationSlowMs] via `--dart-define=LECHE_E2E_SLOW_MS=650` on
/// Supabase e2e runs so steps are visible when demoing on a simulator.
///
/// Diagnostics (`e2eStep`, dumps, screenshots on timeout) print to the test
/// console so a stuck UI (keyboard covering a button, wrong screen, etc.) is
/// visible without watching the simulator the whole time.
const integrationSlowMs = int.fromEnvironment(
  'LECHE_E2E_SLOW_MS',
  defaultValue: 0,
);

IntegrationTestWidgetsFlutterBinding? _e2eBinding;
int _e2eStepIndex = 0;

/// Call once from `main()` after `ensureInitialized()`.
void e2eAttachBinding(IntegrationTestWidgetsFlutterBinding binding) {
  _e2eBinding = binding;
  _e2eStepIndex = 0;
}

void e2eLog(String message) {
  // ignore: avoid_print — must surface on device e2e console
  print('E2E[${DateTime.now().toIso8601String()}] $message');
}

Future<void> e2eStep(String label) async {
  _e2eStepIndex += 1;
  e2eLog('step $_e2eStepIndex: $label');
}

String visibleTextOnScreen(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .where((t) => t.trim().isNotEmpty)
      .toSet()
      .join(' | ');
}

String valueKeysOnScreen(WidgetTester tester) {
  final keys = <String>[];
  for (final element
      in find.byWidgetPredicate((w) => w.key is ValueKey).evaluate()) {
    final key = element.widget.key;
    if (key is ValueKey) keys.add(key.value.toString());
  }
  return keys.toSet().join(', ');
}

String focusSummary() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null) return 'none';
  final ctx = focus.context;
  final widget = ctx?.widget;
  final key = widget?.key;
  return '${widget.runtimeType}${key != null ? ' key=$key' : ''}';
}

/// Prints UI snapshot and optionally captures an integration_test screenshot.
Future<void> e2eDump(WidgetTester tester, {required String reason}) async {
  e2eLog('DUMP ($reason)');
  e2eLog('  focus=${focusSummary()}');
  e2eLog('  texts=${visibleTextOnScreen(tester)}');
  e2eLog('  keys=${valueKeysOnScreen(tester)}');
  final binding = _e2eBinding;
  if (binding == null) {
    e2eLog('  screenshot skipped (no binding attached)');
    return;
  }
  final name = 'dump_${reason.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')}';
  try {
    await binding.takeScreenshot(name);
    e2eLog('  screenshot=$name');
  } catch (e) {
    e2eLog('  screenshot failed: $e');
  }
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeoutSeconds = 15,
  String? label,
}) async {
  final tag = label ?? finder.toString();
  final end = DateTime.now().add(Duration(seconds: timeoutSeconds));
  var lastHeartbeat = DateTime.now();
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      e2eLog('wait ok: $tag');
      return;
    }
    final now = DateTime.now();
    if (now.difference(lastHeartbeat) >= const Duration(seconds: 5)) {
      lastHeartbeat = now;
      final left = end.difference(now).inSeconds;
      e2eLog(
        'waiting for "$tag" (${left}s left) focus=${focusSummary()} '
        'ui=${visibleTextOnScreen(tester)}',
      );
    }
  }
  await e2eDump(tester, reason: 'wait_timeout_$tag');
  fail(
    'Timeout waiting for "$tag" after ${timeoutSeconds}s.\n'
    'UI texts: ${visibleTextOnScreen(tester)}\n'
    'Keys: ${valueKeysOnScreen(tester)}\n'
    'Focus: ${focusSummary()}',
  );
}

Future<bool> tryTapAndWaitFor(
  WidgetTester tester, {
  required Finder tapTarget,
  required Finder waitFor,
  int timeoutSeconds = 8,
}) async {
  await tester.ensureVisible(tapTarget);
  await tester.tap(tapTarget);
  final end = DateTime.now().add(Duration(seconds: timeoutSeconds));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (waitFor.evaluate().isNotEmpty) return true;
  }
  return false;
}

Future<void> scrollUntilVisible(WidgetTester tester, Finder finder) async {
  // Do not early-return when the finder matches off-screen (common in long lists).
  final target = finder.evaluate().length > 1 ? finder.first : finder;
  await tester.ensureVisible(target);
  await pumpBounded(tester, ticks: 10);
}

/// Scrolls a list item into view if needed, then taps it.
Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(
    finder,
    findsWidgets,
    reason: 'Text "$text" not found. UI: ${visibleTextOnScreen(tester)}',
  );
  await scrollUntilVisible(tester, finder.first);
  await tester.tap(finder.first);
  await pumpBounded(tester);
}

/// Scrolls [finder] into view (if needed) and taps it. Use for home module
/// cards that may sit below the fold on small desktop windows.
Future<void> tapKey(WidgetTester tester, Key key, {String? label}) async {
  final finder = find.byKey(key);
  await waitFor(tester, finder, label: label ?? key.toString());
  await scrollUntilVisible(tester, finder);
  await dismissKeyboard(tester);
  await tester.tap(finder);
  await pumpBounded(tester);
}

Future<void> pauseIntegration(WidgetTester tester, {int multiplier = 1}) async {
  if (integrationSlowMs <= 0) return;
  await tester.pump(Duration(milliseconds: integrationSlowMs * multiplier));
}

/// Bounded pump — avoids hanging forever on infinite animations
/// (spinners, sync indicators) that break [WidgetTester.pumpAndSettle].
Future<void> pumpBounded(
  WidgetTester tester, {
  int ticks = 40,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(step);
  }
}

/// Pops the top route. Prefer this over [WidgetTester.pageBack]: on device
/// runs (esp. iOS) two "Back" tooltips can coexist during transitions.
Future<void> tapBack(WidgetTester tester) async {
  await pumpBounded(tester);
  final backs = find.byTooltip('Back');
  expect(
    backs,
    findsWidgets,
    reason:
        'Expected at least one Back control: ${visibleTextOnScreen(tester)}',
  );
  await tester.tap(backs.last);
  await pumpBounded(tester);
}

/// Closes the soft keyboard so the next tap hits the intended control
/// (on iOS the first tap often only dismisses the keyboard).
Future<void> dismissKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  // Best-effort for flutter_test text input channel (no-op on some devices).
  try {
    tester.testTextInput.hide();
  } catch (_) {}
  await pumpBounded(tester, ticks: 10);
}

/// Ensures [finder] is visible, dismisses the keyboard, then taps.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await dismissKeyboard(tester);
  await tester.ensureVisible(finder);
  await pumpBounded(tester, ticks: 10);
  await tester.tap(finder);
  await pumpBounded(tester);
}

Object? _onPressedOf(Widget widget) {
  return switch (widget) {
    FilledButton(:final onPressed) => onPressed,
    ElevatedButton(:final onPressed) => onPressed,
    TextButton(:final onPressed) => onPressed,
    OutlinedButton(:final onPressed) => onPressed,
    IconButton(:final onPressed) => onPressed,
    FloatingActionButton(:final onPressed) => onPressed,
    _ => null,
  };
}

/// Prefer this for primary actions on device e2e: gesture taps often miss when
/// the iOS soft keyboard is open; invoking [onPressed] is deterministic.
Future<void> invokeButton(WidgetTester tester, Finder finder) async {
  await dismissKeyboard(tester);
  expect(
    finder,
    findsOneWidget,
    reason: 'Button not found. UI: ${visibleTextOnScreen(tester)}',
  );
  await tester.ensureVisible(finder);
  await pumpBounded(tester, ticks: 10);

  final widget = tester.widget(finder);
  final onPressed = _onPressedOf(widget);
  if (onPressed == null) {
    e2eLog('invokeButton: no onPressed on ${widget.runtimeType}, tapping');
    await tester.tap(finder);
  } else {
    e2eLog('invokeButton: calling onPressed on ${widget.runtimeType}');
    final result = (onPressed as Function)();
    // Login/guardar completan rápido; abrir un bottom sheet / dialog deja el
    // Future pendiente hasta cerrarlo — no hay que esperarlo.
    if (result is Future) {
      try {
        await result.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        e2eLog(
          'invokeButton: onPressed sigue pendiente (modal abierto); sigo',
        );
      }
    }
  }
  await pumpBounded(tester);
}
