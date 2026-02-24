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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static final Uri _roboflowUri = Uri.parse(
    'https://demo.roboflow.com/drowsiness-sgvf2-tixi5/1?publishable_key=rf_JULDEIHODmWX9hxVH5cPND0AiSs2',
  );
  final PageController _pageController = PageController();
  final AudioService _audioService = AudioService();
  int _currentPage = 0;
  bool _appBlockingEnabled = false;
  bool _isRainPlaying = false;

  final List<String> _carouselImages = const [
    'assets/images/quotes/lock_in.jpg',
    'assets/images/quotes/insp1.jpg',
    'assets/images/quotes/inspo2.jpg',
  ];

  @override
  void dispose() {
    _audioService.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openDistractionDetection() async {
    await launchUrl(_roboflowUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleRain() async {
    if (_isRainPlaying) {
      await _audioService.stop();
    } else {
      await _audioService.playRain();
    }
    if (!mounted) return;
    setState(() {
      _isRainPlaying = !_isRainPlaying;
    });
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
            colors: [
              Color(0xFFFDEDF0),
              Color(0xFFF0F8FF),
              Color(0xFFEEF8F2),
            ],
          ),
        ),
        child: sessionsAsync.when(
          data: (sessions) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi ${user?.displayName ?? 'there'}',
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
                _buildTopRow(context),
                const SizedBox(height: 14),
                _buildPerformanceTracker(context, sessions),
                const SizedBox(height: 14),
                _buildRainPlayer(context),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading dashboard: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildTopCarousel(context)),
          const SizedBox(width: 12),
          Expanded(child: _buildAppBlockingCard(context)),
        ],
      ),
    );
  }

  Widget _buildTopCarousel(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _carouselImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (_, index) => Image.asset(
                  _carouselImages[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_carouselImages.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 8,
                width: isActive ? 24 : 8,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFF2A9AE) : const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTracker(BuildContext context, List<StudySession> sessions) {
    final totalStudy = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final totalBreak = sessions.fold<int>(0, (sum, s) => sum + s.breakDurationSeconds);
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
          const Expanded(
            child: Text('Focus Detection'),
          ),
          TextButton(
            onPressed: _openDistractionDetection,
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBlockingCard(BuildContext context) {
    return _SoftCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'App Blocking',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Switch(
            value: _appBlockingEnabled,
            onChanged: (value) {
              setState(() {
                _appBlockingEnabled = value;
              });
            },
          ),
          Text(
            _appBlockingEnabled ? 'Enabled' : 'Disabled',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRainPlayer(BuildContext context) {
    return _SoftCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Image.asset(
                'assets/images/sounds/rain.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              right: 14,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Rain & Thunder Focus Sound',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FloatingActionButton.small(
                    heroTag: 'rain_play',
                    backgroundColor: Colors.white,
                    onPressed: _toggleRain,
                    child: Icon(
                      _isRainPlaying ? Icons.pause : Icons.play_arrow,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(12),
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
