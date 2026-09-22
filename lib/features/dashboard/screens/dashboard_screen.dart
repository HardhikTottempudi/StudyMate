import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/audio_service.dart';
import '../../../shared/models/study_session.dart';
import '../widgets/study_dashboard_view.dart';

final studySessionsProvider = StreamProvider<List<StudySession>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudySessions();
});

// ── Daily quote (rotates by day of year, works offline) ──────────────────────

const _kQuotes = [
  ('The secret of getting ahead is getting started.', 'Mark Twain'),
  ('Study hard in silence; let success make the noise.', 'Unknown'),
  ('It always seems impossible until it\'s done.', 'Nelson Mandela'),
  ('Education is the most powerful weapon.', 'Nelson Mandela'),
  ('The expert in anything was once a beginner.', 'Helen Hayes'),
  ('Push yourself, because no one else is going to do it for you.', 'Unknown'),
  ('Great things never come from comfort zones.', 'Unknown'),
  ('Dream it. Wish it. Do it.', 'Unknown'),
  ('Success doesn\'t just find you. You have to go out and get it.', 'Unknown'),
  (
    'The harder you work for something, the greater you\'ll feel when you achieve it.',
    'Unknown'
  ),
  ('Don\'t stop when you\'re tired. Stop when you\'re done.', 'Unknown'),
  ('Wake up with determination. Go to bed with satisfaction.', 'Unknown'),
  ('Do something today that your future self will thank you for.', 'Unknown'),
  (
    'Discipline is doing what needs to be done even when you don\'t want to.',
    'Unknown'
  ),
  (
    'Your future is created by what you do today, not tomorrow.',
    'Robert Kiyosaki'
  ),
  ('Strive for progress, not perfection.', 'Unknown'),
  (
    'You don\'t have to be great to start, but you have to start to be great.',
    'Zig Ziglar'
  ),
  ('Believe you can and you\'re halfway there.', 'Theodore Roosevelt'),
  ('Act as if what you do makes a difference. It does.', 'William James'),
  (
    'Success is not final, failure is not fatal: it is the courage to continue that counts.',
    'Winston Churchill'
  ),
  (
    'Knowing is not enough; we must apply. Willing is not enough; we must do.',
    'Goethe'
  ),
  (
    'The beautiful thing about learning is nobody can take it away from you.',
    'B.B. King'
  ),
  (
    'Live as if you were to die tomorrow. Learn as if you were to live forever.',
    'Gandhi'
  ),
  (
    'Intelligence plus character — that is the goal of true education.',
    'Martin Luther King Jr.'
  ),
  ('An investment in knowledge pays the best interest.', 'Benjamin Franklin'),
  ('There are no shortcuts to any place worth going.', 'Beverly Sills'),
  ('Focus on being productive instead of busy.', 'Tim Ferriss'),
  ('Energy and persistence conquer all things.', 'Benjamin Franklin'),
  ('You are braver than you believe, stronger than you seem.', 'A.A. Milne'),
  (
    'The mind is not a vessel to be filled, but a fire to be kindled.',
    'Plutarch'
  ),
];

(String quote, String author) _todaysQuote() {
  final dayOfYear =
      DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
  return _kQuotes[dayOfYear % _kQuotes.length];
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static final Uri _roboflowUri = Uri.parse(
    'https://demo.roboflow.com/drowsiness-sgvf2-tixi5/1?publishable_key=rf_JULDEIHODmWX9hxVH5cPND0AiSs2',
  );

  final AudioService _audioService = AudioService();
  String? _playingId;
  bool _soundBusy = false;

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _openDistractionDetection() async {
    try {
      final opened =
          await launchUrl(_roboflowUri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('Could not open focus check-in');
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Couldn’t open focus check-in. Please try again.')));
    }
  }

  Future<void> _toggleSound(AmbientSound sound) async {
    if (_soundBusy) return;
    setState(() => _soundBusy = true);
    try {
      if (_playingId == sound.id && _audioService.isPlaying) {
        await _audioService.stop();
      } else {
        await _audioService.play(sound);
      }
      if (mounted) setState(() => _playingId = _audioService.currentId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              sound.assetPath != null
                  ? 'Couldn’t play this sound. Please try again.'
                  : 'This stream is unavailable. Try offline Rain or White Noise.')));
    } finally {
      if (mounted) setState(() => _soundBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final sessions = ref.watch(studySessionsProvider);
    final now = DateTime.now();
    final today = (sessions.valueOrNull ?? <StudySession>[]).where((s) {
      final date = s.startTime.toLocal();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    });
    final (quote, author) = _todaysQuote();
    final displayName = user?.displayName?.trim() ?? '';
    return StudyDashboardView(
      name: displayName.isEmpty ? 'Hello' : displayName.split(' ').first,
      greeting: now.hour < 12
          ? 'Good morning'
          : now.hour < 17
              ? 'Good afternoon'
              : 'Good evening',
      studyMinutes:
          today.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60,
      sessionCount: today.length,
      breakMinutes:
          today.fold<int>(0, (sum, s) => sum + s.breakDurationSeconds) ~/ 60,
      quote: quote,
      quoteAuthor: author,
      loading: sessions.isLoading,
      hasError: sessions.hasError,
      onRetry: () => ref.invalidate(studySessionsProvider),
      onFocus: () => widget.onNavigate(1),
      onLearn: () => widget.onNavigate(2),
      onStudyTok: () => widget.onNavigate(3),
      onFocusCheck: _openDistractionDetection,
      onSound: _toggleSound,
      playingId: _playingId,
      soundBusy: _soundBusy,
      onSignOut: () async {
        try {
          await ref.read(authControllerProvider.notifier).signOut();
        } catch (_) {
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Couldn’t sign out. Please try again.')));
        }
      },
    );
  }
}
