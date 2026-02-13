import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/timer_provider.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  static final Uri _roboflowUri = Uri.parse(
    'https://demo.roboflow.com/drowsiness-sgvf2-tixi5/1?publishable_key=rf_JULDEIHODmWX9hxVH5cPND0AiSs2',
  );

  Timer? _timer;
  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _goalMinutesController =
      TextEditingController(text: '25');
  bool _isOnBreak = false;

  final List<String> _apps = const [
    'Instagram',
    'YouTube',
    'TikTok',
    'Discord',
    'Chrome',
    'WhatsApp',
    'Snapchat',
  ];

  final Map<String, bool> _blocked = {};

  @override
  void initState() {
    super.initState();
    for (final app in _apps) {
      _blocked[app] = false;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(timerProvider.notifier).tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionNameController.dispose();
    _goalMinutesController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int _goalSeconds() {
    final minutes = int.tryParse(_goalMinutesController.text.trim());
    if (minutes == null || minutes <= 0) return 25 * 60;
    return minutes * 60;
  }

  Future<void> _openDistractionDetection() async {
    await launchUrl(_roboflowUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final controller = ref.read(timerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: Image.asset(
                      'assets/images/study/study_sesh.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Study Sesh',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6C5CE7),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _sessionNameController,
                  decoration: const InputDecoration(
                    hintText: 'New study sesh...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Goal Time (min): '),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _goalMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDuration(timerState.elapsedSeconds),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: timerState.isRunning
                          ? null
                          : () {
                              controller.start();
                            },
                      child: const Text('Start'),
                    ),
                    ElevatedButton(
                      onPressed: timerState.isRunning
                          ? () {
                              controller.pause();
                            }
                          : null,
                      child: const Text('Pause'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await controller.stopAndSave();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Session saved')),
                        );
                      },
                      child: const Text('Stop'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isOnBreak = !_isOnBreak;
                          if (_isOnBreak) {
                            controller.pause();
                          } else {
                            controller.resume();
                          }
                        });
                      },
                      child: Text(_isOnBreak ? 'Resume' : 'Break'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'App Blocking',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text(
                'Block These Apps During Study',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _apps.map((app) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(app)),
                        Switch(
                          value: _blocked[app] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _blocked[app] = value;
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Enable App Blocker Service'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _openDistractionDetection,
                child: const Text('Add Snap (Break)'),
              ),
              const SizedBox(height: 16),
              Text(
                'Goal: ${_goalSeconds() ~/ 60} min',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
