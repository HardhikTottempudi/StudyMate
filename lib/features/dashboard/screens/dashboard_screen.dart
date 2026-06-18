import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/audio_service.dart';
import '../../../shared/models/study_session.dart';

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
  ('The harder you work for something, the greater you\'ll feel when you achieve it.', 'Unknown'),
  ('Don\'t stop when you\'re tired. Stop when you\'re done.', 'Unknown'),
  ('Wake up with determination. Go to bed with satisfaction.', 'Unknown'),
  ('Do something today that your future self will thank you for.', 'Unknown'),
  ('Discipline is doing what needs to be done even when you don\'t want to.', 'Unknown'),
  ('Your future is created by what you do today, not tomorrow.', 'Robert Kiyosaki'),
  ('Strive for progress, not perfection.', 'Unknown'),
  ('You don\'t have to be great to start, but you have to start to be great.', 'Zig Ziglar'),
  ('Believe you can and you\'re halfway there.', 'Theodore Roosevelt'),
  ('Act as if what you do makes a difference. It does.', 'William James'),
  ('Success is not final, failure is not fatal: it is the courage to continue that counts.', 'Winston Churchill'),
  ('Knowing is not enough; we must apply. Willing is not enough; we must do.', 'Goethe'),
  ('The beautiful thing about learning is nobody can take it away from you.', 'B.B. King'),
  ('Live as if you were to die tomorrow. Learn as if you were to live forever.', 'Gandhi'),
  ('Intelligence plus character — that is the goal of true education.', 'Martin Luther King Jr.'),
  ('An investment in knowledge pays the best interest.', 'Benjamin Franklin'),
  ('There are no shortcuts to any place worth going.', 'Beverly Sills'),
  ('Focus on being productive instead of busy.', 'Tim Ferriss'),
  ('Energy and persistence conquer all things.', 'Benjamin Franklin'),
  ('You are braver than you believe, stronger than you seem.', 'A.A. Milne'),
  ('The mind is not a vessel to be filled, but a fire to be kindled.', 'Plutarch'),
];

(String quote, String author) _todaysQuote() {
  final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
  return _kQuotes[dayOfYear % _kQuotes.length];
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static final Uri _roboflowUri = Uri.parse(
    'https://demo.roboflow.com/drowsiness-sgvf2-tixi5/1?publishable_key=rf_JULDEIHODmWX9hxVH5cPND0AiSs2',
  );

  final AudioService _audioService = AudioService();
  String? _playingId;

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _openDistractionDetection() async {
    await launchUrl(_roboflowUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleSound(AmbientSound sound) async {
    if (_playingId == sound.id && _audioService.isPlaying) {
      await _audioService.stop();
      if (!mounted) return;
      setState(() => _playingId = null);
    } else {
      await _audioService.play(sound);
      if (!mounted) return;
      setState(() => _playingId = sound.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final sessionsAsync = ref.watch(studySessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDEDF0), Color(0xFFF0F8FF), Color(0xFFEEF8F2)],
          ),
        ),
        child: sessionsAsync.when(
          data: (sessions) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi ${user?.displayName ?? 'there'} 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D3142),
                      ),
                ),
                Text(
                  'Keep your momentum steady today.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6F7480),
                      ),
                ),
                const SizedBox(height: 14),
                _buildDailyQuoteCard(context),
                const SizedBox(height: 14),
                _buildPerformanceTracker(context, sessions),
                const SizedBox(height: 14),
                _buildWhiteNoisePlayer(context),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  // ── Daily Quote Card ────────────────────────────────────────────────────────

  Widget _buildDailyQuoteCard(BuildContext context) {
    final (quote, author) = _todaysQuote();
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CBF), Color(0xFF4A90D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x337C5CBF),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded,
                  color: Colors.white54, size: 20),
              const SizedBox(width: 6),
              Text(
                'Daily Inspiration',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$quote"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— $author',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Performance Tracker ─────────────────────────────────────────────────────

  Widget _buildPerformanceTracker(
      BuildContext context, List<StudySession> sessions) {
    final totalStudy =
        sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final totalBreak =
        sessions.fold<int>(0, (sum, s) => sum + s.breakDurationSeconds);
    final totalStudyHours = (totalStudy / 3600).toStringAsFixed(1);
    final totalBreakMin = (totalBreak / 60).round();

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  title: 'Study Hours',
                  value: '$totalStudyHours h',
                  color: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricChip(
                  title: 'Breaks',
                  value: '$totalBreakMin min',
                  color: const Color(0xFFFDF1E6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricChip(
                  title: 'Sessions',
                  value: sessions.length.toString(),
                  color: const Color(0xFFE8EEFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDistractionWidget(context),
        ],
      ),
    );
  }

  Widget _buildDistractionWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.camera_alt_rounded, color: Color(0xFF7D8CC4)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Focus Detection')),
          TextButton(
            onPressed: _openDistractionDetection,
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  // ── White Noise Player ──────────────────────────────────────────────────────

  Widget _buildWhiteNoisePlayer(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.headphones_rounded,
                  color: Color(0xFF7C5CBF), size: 22),
              const SizedBox(width: 8),
              Text(
                'Ambient Sounds',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              if (_playingId != null)
                TextButton.icon(
                  onPressed: () async {
                    await _audioService.stop();
                    if (!mounted) return;
                    setState(() => _playingId = null);
                  },
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: const Text('Stop'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC7664F),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kAmbientSounds.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final sound = kAmbientSounds[index];
              final isPlaying =
                  _playingId == sound.id && _audioService.isPlaying;
              return GestureDetector(
                onTap: () => _toggleSound(sound),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? const Color(0xFF7C5CBF)
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPlaying
                          ? const Color(0xFF7C5CBF)
                          : const Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                    boxShadow: isPlaying
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF7C5CBF).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(sound.emoji,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(
                        sound.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPlaying
                              ? Colors.white
                              : const Color(0xFF2D3142),
                        ),
                      ),
                      if (isPlaying)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.graphic_eq_rounded,
                              size: 14, color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_playingId != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Now playing: ${kAmbientSounds.firstWhere((s) => s.id == _playingId).name}  ${kAmbientSounds.firstWhere((s) => s.id == _playingId).emoji}',
                style: const TextStyle(
                  color: Color(0xFF7C5CBF),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
