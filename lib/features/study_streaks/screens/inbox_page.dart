import 'package:flutter/material.dart';
import '../models/streak_models.dart';
import '../services/study_streaks_service.dart';
import 'snap_view_page.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({
    super.key,
    required this.snaps,
    required this.service,
  });

  final List<StudySnap> snaps;
  final StudyStreaksService service;

  @override
  Widget build(BuildContext context) {
    if (snaps.isEmpty) {
      return const Center(
        child: Text('No new snaps.\nYou are all caught up.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: snaps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final snap = snaps[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SnapViewPage(
                  snap: snap,
                  onViewed: () => service.markSnapViewed(snap),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: snap.imageUrl.isEmpty
                      ? Container(
                          color: const Color(0xFFE8EAF2),
                          child: const Icon(Icons.image_not_supported_rounded),
                        )
                      : Image.network(
                          snap.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator()),
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE8EAF2),
                            child:
                                const Icon(Icons.image_not_supported_rounded),
                          ),
                        ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.24)),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${snap.senderName} sent a study moment',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Tap to view',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
