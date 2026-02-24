import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/streak_models.dart';
import '../services/study_streaks_service.dart';
import '../widgets/streak_card_widget.dart';
import 'camera_page.dart';
import 'inbox_page.dart';

final studyStreaksServiceProvider = Provider<StudyStreaksService>((ref) {
  return StudyStreaksService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final streaksProvider = StreamProvider<List<FriendStreak>>((ref) {
  return ref.read(studyStreaksServiceProvider).watchStreaks();
});

final inboxSnapsProvider = StreamProvider<List<StudySnap>>((ref) {
  return ref.read(studyStreaksServiceProvider).watchInbox();
});

class StudyStreaksPage extends ConsumerStatefulWidget {
  const StudyStreaksPage({super.key});

  @override
  ConsumerState<StudyStreaksPage> createState() => _StudyStreaksPageState();
}

class _StudyStreaksPageState extends ConsumerState<StudyStreaksPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final service = ref.read(studyStreaksServiceProvider);
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            const CameraPage(friends: StudyStreaksService.defaultFriends),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (result == null) return;
    try {
      final savedPath = await service.persistCapturedImage(result['imagePath']);
      await service.sendDailySnap(
        friend: result['friend'] as FriendContact,
        imagePath: savedPath,
        caption: result['caption'] as String?,
        emoji: result['emoji'] as String?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study moment sent. Streak updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _openHistory(FriendStreak streak) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        final historyStream =
            ref.read(studyStreaksServiceProvider).watchFriendHistory(streak.friendId);
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: StreamBuilder<List<StudySnap>>(
            stream: historyStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final snaps = snapshot.data ?? [];
              if (snaps.isEmpty) {
                return const Center(child: Text('No snap history yet.'));
              }
              return ListView.builder(
                itemCount: snaps.length,
                itemBuilder: (context, index) {
                  final snap = snaps[index];
                  return ListTile(
                    title: Text(snap.friendName),
                    subtitle: Text(snap.createdAtIso.substring(0, 16)),
                    trailing: Text(snap.emoji ?? ''),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final streaksAsync = ref.watch(streaksProvider);
    final inboxAsync = ref.watch(inboxSnapsProvider);
    final service = ref.read(studyStreaksServiceProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9F1EC), Color(0xFFF1F4FB), Color(0xFFF0F7F2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 2),
                child: Text(
                  'Stay consistent.',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Send one intentional study moment every day.'),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Streaks'),
                  Tab(text: 'Inbox'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    streaksAsync.when(
                      data: (streaks) => ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: streaks.length,
                              itemBuilder: (context, index) {
                                final streak = streaks[index];
                                return StreakCardWidget(
                                  streak: streak,
                                  onTap: () => _openHistory(streak),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                    inboxAsync.when(
                      data: (snaps) => InboxPage(snaps: snaps, service: service),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCamera,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Send Study Moment'),
      ),
    );
  }
}
