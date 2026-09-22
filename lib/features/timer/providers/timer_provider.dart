import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/study_session.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';

class TimerState {
  final bool isSaving;
  final bool isSessionActive;
  final bool isRunning;
  final bool isOnBreak;
  final int elapsedStudySeconds;
  final int elapsedBreakSeconds;
  final int breakCount;
  final int goalDurationSeconds;
  final DateTime? sessionStartTime;
  final String sessionName;
  final bool appBlockEnabled;
  final List<String> blockedApps;

  TimerState({
    this.isSaving = false,
    this.isSessionActive = false,
    this.isRunning = false,
    this.isOnBreak = false,
    this.elapsedStudySeconds = 0,
    this.elapsedBreakSeconds = 0,
    this.breakCount = 0,
    this.goalDurationSeconds = 25 * 60,
    this.sessionStartTime,
    this.sessionName = '',
    this.appBlockEnabled = false,
    this.blockedApps = const [],
  });

  TimerState copyWith({
    bool? isSaving,
    bool? isSessionActive,
    bool? isRunning,
    bool? isOnBreak,
    int? elapsedStudySeconds,
    int? elapsedBreakSeconds,
    int? breakCount,
    int? goalDurationSeconds,
    DateTime? sessionStartTime,
    String? sessionName,
    bool? appBlockEnabled,
    List<String>? blockedApps,
  }) {
    return TimerState(
      isSaving: isSaving ?? this.isSaving,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      isRunning: isRunning ?? this.isRunning,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      elapsedStudySeconds: elapsedStudySeconds ?? this.elapsedStudySeconds,
      elapsedBreakSeconds: elapsedBreakSeconds ?? this.elapsedBreakSeconds,
      breakCount: breakCount ?? this.breakCount,
      goalDurationSeconds: goalDurationSeconds ?? this.goalDurationSeconds,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionName: sessionName ?? this.sessionName,
      appBlockEnabled: appBlockEnabled ?? this.appBlockEnabled,
      blockedApps: blockedApps ?? this.blockedApps,
    );
  }
}

class TimerController extends StateNotifier<TimerState> {
  TimerController(this._save, {Duration Function()? elapsedNow})
      : super(TimerState()) {
    _elapsedNow = elapsedNow ?? (() => _clock.elapsed);
  }
  final Future<void> Function(StudySession) _save;
  final Stopwatch _clock = Stopwatch()..start();
  late final Duration Function() _elapsedNow;
  Duration _lastTick = Duration.zero;
  String? _sessionId;

  void startSession({
    required int goalDurationSeconds,
    required String sessionName,
    required bool appBlockEnabled,
    required List<String> blockedApps,
  }) {
    if (state.isSessionActive || state.isSaving) return;
    if (goalDurationSeconds < 60 || goalDurationSeconds > 12 * 3600) {
      throw ArgumentError('Choose a goal between 1 and 720 minutes.');
    }
    _sessionId = const Uuid().v4();
    _lastTick = _elapsedNow();
    state = TimerState(
      isSessionActive: true,
      isRunning: true,
      isOnBreak: false,
      elapsedStudySeconds: 0,
      elapsedBreakSeconds: 0,
      breakCount: 0,
      goalDurationSeconds: goalDurationSeconds,
      sessionStartTime: DateTime.now(),
      sessionName: sessionName,
      appBlockEnabled: appBlockEnabled,
      blockedApps: blockedApps,
    );
  }

  void pauseSession() {
    if (!state.isSessionActive || !state.isRunning || state.isSaving) return;
    tick();
    state = state.copyWith(isRunning: false);
  }

  void resumeSession() {
    if (!state.isSessionActive || state.isRunning || state.isSaving) return;
    _lastTick = _elapsedNow();
    state = state.copyWith(isRunning: true);
  }

  void startBreak() {
    if (!state.isSessionActive ||
        !state.isRunning ||
        state.isOnBreak ||
        state.isSaving) return;
    tick();
    _lastTick = _elapsedNow();
    state = state.copyWith(
      isOnBreak: true,
      breakCount: state.breakCount + 1,
    );
  }

  void endBreak() {
    if (!state.isSessionActive || !state.isOnBreak || state.isSaving) return;
    tick();
    _lastTick = _elapsedNow();
    state = state.copyWith(isOnBreak: false);
  }

  void resetSession() {
    if (state.isSaving) return;
    _sessionId = null;
    state = TimerState(goalDurationSeconds: state.goalDurationSeconds);
  }

  void tick() {
    if (!state.isSessionActive || !state.isRunning || state.isSaving) return;
    final seconds = (_elapsedNow() - _lastTick).inSeconds;
    if (seconds <= 0) return;
    _lastTick += Duration(seconds: seconds);
    state = state.isOnBreak
        ? state.copyWith(
            elapsedBreakSeconds: state.elapsedBreakSeconds + seconds)
        : state.copyWith(
            elapsedStudySeconds: state.elapsedStudySeconds + seconds);
  }

  bool get isGoalReached =>
      state.goalDurationSeconds > 0 &&
      state.elapsedStudySeconds >= state.goalDurationSeconds;

  int get remainingStudySeconds {
    final remaining = state.goalDurationSeconds - state.elapsedStudySeconds;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> stopAndSave() async {
    if (state.sessionStartTime == null || state.isSaving) return;
    pauseSession();
    if (state.elapsedStudySeconds == 0 && state.elapsedBreakSeconds == 0) {
      throw StateError('Study for at least a second before saving.');
    }

    final session = StudySession(
      id: _sessionId!,
      sessionName: state.sessionName,
      startTime: state.sessionStartTime!,
      endTime: DateTime.now(),
      durationSeconds: state.elapsedStudySeconds,
      goalDurationSeconds: state.goalDurationSeconds,
      breakDurationSeconds: state.elapsedBreakSeconds,
      breakCount: state.breakCount,
      appBlockEnabled: state.appBlockEnabled,
      blockedApps: state.blockedApps,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(isSaving: true);
    try {
      await _save(session).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      state = state.copyWith(isSaving: false);
      resetSession();
    } catch (_) {
      if (mounted) state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  @override
  void dispose() {
    _clock.stop();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerController, TimerState>((ref) {
  return TimerController(ref.watch(firestoreServiceProvider).saveStudySession);
});
