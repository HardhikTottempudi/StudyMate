import 'package:flutter/material.dart';
import '../../../shared/widgets/soft_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/study_video.dart';
import '../widgets/study_video_player.dart';
import '../services/studytok_service.dart';

final studyVideosProvider =
    FutureProvider.autoDispose.family<List<StudyVideo>, String>((ref, hashtag) {
  final service = StudyTokService();
  ref.onDispose(service.dispose);
  return service.load(hashtag);
});

class StudyTokScreen extends ConsumerStatefulWidget {
  const StudyTokScreen({super.key, this.active = true});
  final bool active;
  @override
  ConsumerState<StudyTokScreen> createState() => _StudyTokScreenState();
}

class _StudyTokScreenState extends ConsumerState<StudyTokScreen>
    with WidgetsBindingObserver {
  String _subject = 'All';
  String? _playingId;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant StudyTokScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _playingId = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _foreground = state == AppLifecycleState.resumed;
      if (!_foreground) _playingId = null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _retry() {
    setState(() {
      _playingId = null;
    });
    ref.invalidate(studyVideosProvider(_subject));
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(studyVideosProvider(_subject));
    return Scaffold(
      backgroundColor: const Color(0xFFE8E7E6),
      body: SoftBackdrop(
          child: SafeArea(
              bottom: false,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(children: [
                    const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('StudyTok',
                              style: TextStyle(
                                  color: studyInk,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800)),
                          Text('A little learning. Every day.',
                              style: TextStyle(color: Color(0xFF68666C))),
                        ])),
                    IconButton(
                        onPressed: _retry,
                        tooltip: 'Refresh library',
                        icon: const Icon(Icons.refresh, color: studyInk)),
                  ]),
                ),
                SizedBox(
                    height: 58,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: StudyVideo.discoveryHashtags.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final label = index == 0
                            ? 'All'
                            : StudyVideo.discoveryHashtags[index - 1];
                        return ChoiceChip(
                            label: Text(label),
                            selected: _subject == label,
                            onSelected: (_) => setState(() {
                                  _subject = label;
                                  _playingId = null;
                                }));
                      },
                    )),
                Expanded(
                    child: videos.when(
                  skipLoadingOnRefresh: false,
                  skipError: false,
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          semanticsLabel: 'Finding study videos')),
                  error: (error, _) => _catalogError(error),
                  data: (all) {
                    final items = all
                        .where((v) =>
                            _subject == 'All' || v.hashtags.contains(_subject))
                        .toList();
                    if (items.isEmpty)
                      return _message('Room for a new discovery',
                          'No matching videos found. Try another study hashtag.');
                    return PageView.builder(
                      key: ValueKey(
                          '$_subject:${items.map((v) => '${v.id}:${v.youtubeId}').join(',')}'),
                      scrollDirection: Axis.vertical,
                      itemCount: items.length,
                      onPageChanged: (_) => setState(() => _playingId = null),
                      itemBuilder: (context, index) {
                        final video = items[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: _playingId == video.id &&
                                              widget.active &&
                                              _foreground
                                          ? StudyVideoPlayer(
                                              key: ValueKey(video.youtubeId),
                                              video: video,
                                              onFinished: () {
                                                if (mounted)
                                                  setState(
                                                      () => _playingId = null);
                                              })
                                          : _videoCover(video),
                                    )),
                                const SizedBox(height: 24),
                                Text(
                                    '${video.subject.toUpperCase()}  ·  ${index + 1} OF ${items.length}',
                                    style: const TextStyle(
                                        color: Color(0xFFAC482C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1)),
                                const SizedBox(height: 12),
                                Text(video.title,
                                    style: const TextStyle(
                                        color: studyInk,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2)),
                                const SizedBox(height: 12),
                                Text(
                                    '${video.creator}  ·  ${video.hashtags.join(' ')}',
                                    style: const TextStyle(
                                        color: Color(0xFF68666C))),
                                const SizedBox(height: 24),
                                Container(
                                    padding: const EdgeInsets.all(20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: const Color(0x99FFFFFF),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('ABOUT THIS VIDEO',
                                              style: TextStyle(
                                                  color: Color(0xFFAC482C),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 8),
                                          Text(
                                              video.description.isEmpty
                                                  ? 'Matched ${video.hashtags.join(', ')} on YouTube.'
                                                  : video.description,
                                              style: const TextStyle(
                                                  color: studyInk,
                                                  fontSize: 17,
                                                  height: 1.5)),
                                        ])),
                                const SizedBox(height: 20),
                                Text(
                                    index == items.length - 1
                                        ? 'You’re all caught up. Take a moment to reflect.'
                                        : 'Swipe up for the next lesson',
                                    style: const TextStyle(
                                        color: Color(0xFF68666C))),
                              ]),
                        );
                      },
                    );
                  },
                )),
              ]))),
    );
  }

  Widget _videoCover(StudyVideo video) => Material(
        color: Colors.transparent,
        child: Stack(children: [
          const Positioned.fill(
              child: DreamArtwork(palette: DreamPalette.lilac)),
          Positioned.fill(
              child: InkWell(
            onTap: () => setState(() => _playingId = video.id),
            child: const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.play_arrow_rounded,
                      size: 32, color: studyAccent)),
              SizedBox(height: 10),
              Text('Play lesson', style: TextStyle(color: studyInk)),
            ])),
          )),
        ]),
      );

  Widget _catalogError(Object error) {
    final code = error is StudyTokException ? error.code : 'unavailable';
    if (code == 'youtube_setup_required') {
      return _message('StudyTok is being set up',
          'Video search isn’t available yet. Please check back soon.',
          retry: true);
    }
    if (code == 'unauthenticated') {
      return _message('Please sign in again',
          'Your session has expired. Sign in again to load study videos.');
    }
    if (code == 'youtube_quota_exceeded') {
      return _message('Video search is taking a break',
          'We’ve reached today’s search limit. Please try again later.',
          retry: true);
    }
    return _message('Couldn’t load videos',
        'Please check your connection and try again in a moment.',
        retry: true);
  }

  Widget _message(String title, String detail, {bool retry = false}) => Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const StudyOrb(size: 56),
              const SizedBox(height: 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: studyInk,
                      fontSize: 23,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(detail,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xFF68666C), height: 1.5)),
              if (retry)
                Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: FilledButton(
                        onPressed: _retry, child: const Text('Try again'))),
            ])),
      );
}
