import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/models/study_session.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';

class TimerState {
  final bool isRunning;
  final int elapsedSeconds;
  final DateTime? startTime;

  TimerState({
    this.isRunning = false,
    this.elapsedSeconds = 0,
    this.startTime,
  });

  TimerState copyWith({
    bool? isRunning,
    int? elapsedSeconds,
    DateTime? startTime,
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startTime: startTime ?? this.startTime,
    );
  }
}

class TimerController extends StateNotifier<TimerState> {
  TimerController(this._firestoreService) : super(TimerState());

  final FirestoreService _firestoreService;

  void start() {
    if (state.isRunning) return;
    state = TimerState(
      isRunning: true,
      elapsedSeconds: 0,
      startTime: DateTime.now(),
    );
  }

  void pause() {
    if (!state.isRunning) return;
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
  }

  void reset() {
    state = TimerState();
  }

  void tick() {
    if (!state.isRunning || state.startTime == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(state.startTime!).inSeconds;
    state = state.copyWith(elapsedSeconds: elapsed);
  }

  Future<void> stopAndSave() async {
    if (state.startTime == null || state.elapsedSeconds == 0) return;

    final session = StudySession(
      id: const Uuid().v4(),
      startTime: state.startTime!,
      endTime: DateTime.now(),
      durationSeconds: state.elapsedSeconds,
      createdAt: DateTime.now(),
    );

    await _firestoreService.saveStudySession(session);
    reset();
  }
}

final timerProvider = StateNotifierProvider<TimerController, TimerState>((ref) {
  return TimerController(ref.watch(firestoreServiceProvider));
});
