import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:studymate/features/timer/providers/timer_provider.dart';
import 'package:studymate/shared/models/study_session.dart';

void main() {
  late Duration elapsed;
  late TimerController timer;
  late List<StudySession> saved;
  void start() => timer.startSession(
      goalDurationSeconds: 1500,
      sessionName: 'Maths',
      appBlockEnabled: false,
      blockedApps: []);
  setUp(() {
    elapsed = Duration.zero;
    saved = [];
    timer = TimerController((s) async {
      saved.add(s);
    }, elapsedNow: () => elapsed);
  });
  tearDown(() => timer.dispose());
  test('delayed ticks use actual elapsed time, paused time is excluded', () {
    start();
    elapsed = const Duration(seconds: 12);
    timer.tick();
    expect(timer.state.elapsedStudySeconds, 12);
    timer.pauseSession();
    elapsed = const Duration(minutes: 2);
    timer.tick();
    expect(timer.state.elapsedStudySeconds, 12);
    timer.resumeSession();
    elapsed += const Duration(seconds: 3);
    timer.tick();
    expect(timer.state.elapsedStudySeconds, 15);
  });
  test('study and break durations stay separate', () async {
    start();
    elapsed += const Duration(seconds: 10);
    timer.startBreak();
    elapsed += const Duration(seconds: 5);
    timer.endBreak();
    await timer.stopAndSave();
    expect(saved.single.durationSeconds, 10);
    expect(saved.single.breakDurationSeconds, 5);
    expect(saved.single.breakCount, 1);
    expect(timer.state.isSessionActive, isFalse);
  });
  test('concurrent saves are ignored and failures preserve a stable retry ID',
      () async {
    timer.dispose();
    final pending = Completer<void>();
    final ids = <String>[];
    timer = TimerController((s) {
      ids.add(s.id);
      return ids.length == 1 ? pending.future : Future.value();
    }, elapsedNow: () => elapsed);
    start();
    elapsed += const Duration(seconds: 10);
    final first = timer.stopAndSave();
    final failure = expectLater(first, throwsStateError);
    await timer.stopAndSave();
    expect(ids.length, 1);
    pending.completeError(StateError('offline'));
    await failure;
    expect(timer.state.isSessionActive, isTrue);
    expect(timer.state.isRunning, isFalse);
    expect(timer.state.elapsedStudySeconds, 10);
    await timer.stopAndSave();
    expect(ids[0], ids[1]);
  });
}
