import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/soft_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/timer_provider.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with WidgetsBindingObserver {
  static final Uri _roboflowUri = Uri.parse(
    'https://demo.roboflow.com/drowsiness-sgvf2-tixi5/1?publishable_key=rf_JULDEIHODmWX9hxVH5cPND0AiSs2',
  );

  Timer? _timer;
  bool _goalReachedNotified = false;
  bool _sessionPausedByBackground = false;
  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _goalMinutesController =
      TextEditingController(text: '25');

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
    WidgetsBinding.instance.addObserver(this);
    for (final app in _apps) {
      _blocked[app] = false;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) ref.read(timerProvider.notifier).tick();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final timerState = ref.read(timerProvider);
      if (timerState.isSessionActive && timerState.isRunning) {
        _sessionPausedByBackground = true;
        ref.read(timerProvider.notifier).pauseSession();
      }
    }
    if (state == AppLifecycleState.resumed && _sessionPausedByBackground) {
      _sessionPausedByBackground = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Session paused. Your progress is safe; resume when you’re ready.'),
            duration: Duration(seconds: 4),
            backgroundColor: Color(0xFFC7664F),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    if (minutes == null || minutes <= 0 || minutes > 720) return 0;
    return minutes * 60;
  }

  Future<void> _openDistractionDetection() async {
    await launchUrl(_roboflowUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final controller = ref.read(timerProvider.notifier);

    if (controller.isGoalReached && !_goalReachedNotified) {
      _goalReachedNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal reached. You can stop and save.')),
        );
      });
    }
    if (!controller.isGoalReached) {
      _goalReachedNotified = false;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Study Session')),
      body: SoftBackdrop(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              _SoftCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _sessionNameController,
                      enabled: !timerState.isSessionActive,
                      decoration: const InputDecoration(
                        hintText: 'Session name',
                        prefixIcon: Icon(Icons.auto_stories_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(child: Text('Goal Minutes')),
                        SizedBox(
                          width: 92,
                          child: TextField(
                            controller: _goalMinutesController,
                            enabled: !timerState.isSessionActive,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3)
                            ],
                            decoration:
                                const InputDecoration(hintText: '1–720'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SoftCard(
                child: Column(
                  children: [
                    Text(
                      timerState.isOnBreak
                          ? 'Break: ${_formatDuration(timerState.elapsedBreakSeconds)}'
                          : _formatDuration(timerState.elapsedStudySeconds),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2C3550),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Remaining: ${_formatDuration(controller.remainingStudySeconds)}'),
                    const SizedBox(height: 4),
                    Text(
                      'Breaks: ${timerState.breakCount}  |  Break time: ${_formatDuration(timerState.elapsedBreakSeconds)}',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: timerState.isSessionActive
                              ? null
                              : () {
                                  if (_goalSeconds() == 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Choose a goal between 1 and 720 minutes.')));
                                    return;
                                  }
                                  FocusScope.of(context).unfocus();
                                  controller.startSession(
                                    goalDurationSeconds: _goalSeconds(),
                                    sessionName:
                                        _sessionNameController.text.trim(),
                                    appBlockEnabled:
                                        _blocked.values.any((v) => v),
                                    blockedApps: _blocked.entries
                                        .where((entry) => entry.value)
                                        .map((entry) => entry.key)
                                        .toList(),
                                  );
                                },
                          child: const Text('Start'),
                        ),
                        ElevatedButton(
                          onPressed: timerState.isRunning
                              ? () => controller.pauseSession()
                              : timerState.isSessionActive
                                  ? () => controller.resumeSession()
                                  : null,
                          child:
                              Text(timerState.isRunning ? 'Pause' : 'Resume'),
                        ),
                        ElevatedButton(
                          onPressed:
                              timerState.isSessionActive && !timerState.isSaving
                                  ? () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      try {
                                        await controller.stopAndSave();
                                      } catch (_) {
                                        if (!mounted) return;
                                        messenger.showSnackBar(const SnackBar(
                                            content: Text(
                                                'Couldn’t save yet. Your session is paused—check your connection and try again.')));
                                        return;
                                      }
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(
                                            content: Text('Session saved')),
                                      );
                                    }
                                  : null,
                          child: Text(
                              timerState.isSaving ? 'Saving…' : 'Stop & Save'),
                        ),
                        ElevatedButton(
                          onPressed: timerState.isSessionActive &&
                                  !timerState.isOnBreak
                              ? () => controller.startBreak()
                              : timerState.isSessionActive &&
                                      timerState.isOnBreak
                                  ? () => controller.endBreak()
                                  : null,
                          child: Text(
                            timerState.isOnBreak ? 'End Break' : 'Start Break',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (Theme.of(context).platform == TargetPlatform.iOS)
                _SoftCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: Color(0xFF95B8F6)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Focus Protection',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Leaving the app pauses your timer without losing progress. Resume when you return. This does not block other apps.',
                              style: TextStyle(color: Color(0xFF666666)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                _SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blocked Apps',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 6),
                      ..._apps.map((app) {
                        return SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(app),
                          value: _blocked[app] ?? false,
                          onChanged: timerState.isSessionActive
                              ? null
                              : (value) {
                                  setState(() {
                                    _blocked[app] = value;
                                  });
                                },
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openDistractionDetection,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Open Focus Detection'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: SoftSurface(padding: const EdgeInsets.all(16), child: child));
}
