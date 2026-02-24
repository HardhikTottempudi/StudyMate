import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/models/study_session.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';

class TimerState {
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
  TimerController(this._firestoreService) : super(TimerState());

  final FirestoreService _firestoreService;

  void startSession({
    required int goalDurationSeconds,
    required String sessionName,
    required bool appBlockEnabled,
    required List<String> blockedApps,
  }) {
    if (state.isSessionActive) return;
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
    if (!state.isSessionActive || !state.isRunning) return;
    state = state.copyWith(isRunning: false);
  }

  void resumeSession() {
    if (!state.isSessionActive || state.isRunning) return;
    state = state.copyWith(isRunning: true);
  }

  void startBreak() {
    if (!state.isSessionActive || !state.isRunning || state.isOnBreak) return;
    state = state.copyWith(
      isOnBreak: true,
      breakCount: state.breakCount + 1,
    );
  }

  void endBreak() {
    if (!state.isSessionActive || !state.isOnBreak) return;
    state = state.copyWith(isOnBreak: false);
  }

  void resetSession() {
    state = TimerState(goalDurationSeconds: state.goalDurationSeconds);
  }

  void tick() {
    if (!state.isSessionActive || !state.isRunning) return;
    if (state.isOnBreak) {
      state = state.copyWith(elapsedBreakSeconds: state.elapsedBreakSeconds + 1);
      return;
    }
    state = state.copyWith(elapsedStudySeconds: state.elapsedStudySeconds + 1);
  }

  bool get isGoalReached =>
      state.goalDurationSeconds > 0 &&
      state.elapsedStudySeconds >= state.goalDurationSeconds;

  int get remainingStudySeconds {
    final remaining = state.goalDurationSeconds - state.elapsedStudySeconds;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> stopAndSave() async {
    if (state.sessionStartTime == null) return;
    if (state.elapsedStudySeconds == 0 && state.elapsedBreakSeconds == 0) {
      resetSession();
      return;
    }

    final session = StudySession(
      id: const Uuid().v4(),
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

    await _firestoreService.saveStudySession(session);
    resetSession();
  }
}

final timerProvider = StateNotifierProvider<TimerController, TimerState>((ref) {
  return TimerController(ref.watch(firestoreServiceProvider));
});
