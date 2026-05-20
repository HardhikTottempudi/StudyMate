import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/streak_models.dart';
import '../services/study_streaks_service.dart';
import '../widgets/streak_card_widget.dart';
import 'camera_page.dart';
import 'inbox_page.dart';

final studyStreaksServiceProvider = Provider<StudyStreaksService>((ref) {
  return StudyStreaksService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    FirebaseStorage.instance,
  );
});

final friendsProvider = StreamProvider<List<FriendContact>>((ref) {
  return ref.read(studyStreaksServiceProvider).watchFriends();
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
  bool _checkingUsername = true;
  bool _needsUsername = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUsername();
  }

  Future<void> _checkUsername() async {
    final username =
        await ref.read(studyStreaksServiceProvider).fetchCurrentUsername();
    if (!mounted) return;
    setState(() {
      _needsUsername = username == null || username.isEmpty;
      _checkingUsername = false;
    });
    if (_needsUsername) _showUsernameSetupDialog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Username setup ────────────────────────────────────────────────────────

  void _showUsernameSetupDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UsernameDialog(
        controller: controller,
        onSave: (username) async {
          await ref
              .read(studyStreaksServiceProvider)
              .saveUsername(username);
          if (!mounted) return;
          setState(() => _needsUsername = false);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── Add friend ────────────────────────────────────────────────────────────

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter username',
            prefixText: '@',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final username = controller.text.trim();
              Navigator.pop(ctx);
              try {
                await ref
                    .read(studyStreaksServiceProvider)
                    .addFriendByUsername(username);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('@$username added!')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _openCamera(List<FriendContact> friends) async {
    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add a friend first to send study moments.')),
      );
      return;
    }

    final service = ref.read(studyStreaksServiceProvider);
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CameraPage(friends: friends),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (result == null) return;

    try {
      await service.sendDailySnap(
        friend: result['friend'] as FriendContact,
        localImagePath: result['imagePath'] as String,
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
        final historyStream = ref
            .read(studyStreaksServiceProvider)
            .watchFriendHistory(streak.friendId);
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
                    title: Text('To ${snap.friendName}'),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final streaksAsync = ref.watch(streaksProvider);
    final inboxAsync = ref.watch(inboxSnapsProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final service = ref.read(studyStreaksServiceProvider);

    if (_checkingUsername) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Stay consistent.',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add_rounded),
                      tooltip: 'Add Friend',
                      onPressed: _showAddFriendDialog,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child:
                    Text('Send one intentional study moment every day.'),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                tabs: inboxAsync.when(
                  data: (snaps) => [
                    const Tab(text: 'Streaks'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Inbox'),
                          if (snaps.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _Badge(count: snaps.length),
                          ],
                        ],
                      ),
                    ),
                  ],
                  loading: () => const [Tab(text: 'Streaks'), Tab(text: 'Inbox')],
                  error: (_, __) =>
                      const [Tab(text: 'Streaks'), Tab(text: 'Inbox')],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Streaks tab ──
                    streaksAsync.when(
                      data: (streaks) {
                        if (streaks.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No streaks yet.\nAdd a friend and send your first study moment!',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return ListView(
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
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Center(child: Text('Error: $e')),
                    ),

                    // ── Inbox tab ──
                    inboxAsync.when(
                      data: (snaps) =>
                          InboxPage(snaps: snaps, service: service),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Center(child: Text('Error: $e')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: friendsAsync.when(
        data: (friends) => FloatingActionButton.extended(
          onPressed: () => _openCamera(friends),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Send Study Moment'),
        ),
        loading: () => const FloatingActionButton.extended(
          onPressed: null,
          icon: Icon(Icons.camera_alt_rounded),
          label: Text('Send Study Moment'),
        ),
        error: (_, __) => null,
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _UsernameDialog extends StatefulWidget {
  const _UsernameDialog({required this.controller, required this.onSave});
  final TextEditingController controller;
  final Future<void> Function(String) onSave;

  @override
  State<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<_UsernameDialog> {
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose a username'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Friends will use this to find and add you. You can\'t change it later.'),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            autofocus: true,
            decoration: InputDecoration(
              prefixText: '@',
              hintText: 'e.g. hardhik123',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final username = widget.controller.text.trim().toLowerCase();
                  if (username.length < 3) {
                    setState(() => _error = 'At least 3 characters');
                    return;
                  }
                  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
                    setState(
                        () => _error = 'Only letters, numbers, underscores');
                    return;
                  }
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  try {
                    await widget.onSave(username);
                  } catch (e) {
                    if (mounted) setState(() => _error = e.toString());
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
