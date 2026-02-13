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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: sessionsAsync.when(
        data: (_) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.displayName != null
                      ? 'Welcome back, ${user!.displayName}!'
                      : 'Stay consistent, stay sharp.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                _buildTopCarousel(context),
                const SizedBox(height: 25),
                _buildPerformanceTracker(context),
                const SizedBox(height: 30),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildDistractionWidget(context),
                      const SizedBox(width: 12),
                      _buildAppBlockingCard(context),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildRainPlayer(context),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading data: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCarousel(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _carouselImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  _carouselImages[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_carouselImages.length, (index) {
            final isActive = _currentPage == index;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: isActive ? 10 : 8,
              width: isActive ? 10 : 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPerformanceTracker(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text(
              'Performance Metrix',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _PerformanceCard(title: 'Hours Completed', value: '10 Hrs'),
                  SizedBox(width: 12),
                  _PerformanceCardWithImage(
                    title: 'Break duration',
                    imagePath: 'assets/images/performance/chart.png',
                  ),
                  SizedBox(width: 12),
                  _PerformanceCard(title: 'Tasks Done', value: '24'),
                  SizedBox(width: 12),
                  _PerformanceCard(title: 'Focus Time', value: '2 Hrs'),
                  SizedBox(width: 12),
                  _PerformanceCard(title: 'Meetings', value: '3'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistractionWidget(BuildContext context) {
    return Card(
      elevation: 4,
      child: SizedBox(
        width: 250,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Camera Distraction Detection',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _openDistractionDetection,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Open'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBlockingCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: SizedBox(
        width: 140,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              const Text(
                'App-blocking Mode',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: _appBlockingEnabled,
                onChanged: (value) {
                  setState(() {
                    _appBlockingEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRainPlayer(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Image.asset(
              'assets/images/sounds/rain.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  '20hr of Rain and thunder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _toggleRain,
                  icon: Icon(
                    _isRainPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final String title;
  final String value;

  const _PerformanceCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: SizedBox(
        width: 180,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceCardWithImage extends StatelessWidget {
  final String title;
  final String imagePath;

  const _PerformanceCardWithImage({
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: SizedBox(
        width: 180,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
