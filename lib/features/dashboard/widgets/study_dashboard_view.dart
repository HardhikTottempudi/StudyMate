import 'package:flutter/material.dart';
import '../../../services/audio_service.dart';
import '../../../shared/widgets/soft_surface.dart';

/// Presentation separated from Firebase so phone layouts can be previewed offline.
class StudyDashboardView extends StatefulWidget {
  const StudyDashboardView(
      {super.key,
      required this.name,
      required this.greeting,
      required this.studyMinutes,
      required this.sessionCount,
      required this.breakMinutes,
      required this.quote,
      required this.quoteAuthor,
      required this.onFocus,
      required this.onLearn,
      required this.onStudyTok,
      required this.onSignOut,
      required this.onRetry,
      required this.onFocusCheck,
      required this.onSound,
      this.playingId,
      this.soundBusy = false,
      this.loading = false,
      this.hasError = false});
  final String name, greeting, quote, quoteAuthor;
  final int studyMinutes, sessionCount, breakMinutes;
  final VoidCallback onFocus,
      onLearn,
      onStudyTok,
      onSignOut,
      onRetry,
      onFocusCheck;
  final ValueChanged<AmbientSound> onSound;
  final String? playingId;
  final bool soundBusy, loading, hasError;
  @override
  State<StudyDashboardView> createState() => _StudyDashboardViewState();
}

class _StudyDashboardViewState extends State<StudyDashboardView> {
  String _mode = 'Today';

  @override
  Widget build(BuildContext context) => SoftBackdrop(
          child: SafeArea(
        bottom: false,
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(children: [
                const StudyOrb(size: 34),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('StudyMate',
                        style: TextStyle(
                            color: studyInk,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.9))),
                IconButton.filledTonal(
                    onPressed: widget.onSignOut,
                    tooltip: 'Sign out',
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xAAFFFFFF)),
                    icon: const Icon(Icons.logout_rounded,
                        size: 20, color: studyInk)),
              ]),
              const SizedBox(height: 24),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Today', 'Focus', 'Unwind']
                      .map((mode) => ChoiceChip(
                          label: Text(mode),
                          selected: _mode == mode,
                          onSelected: (_) => setState(() => _mode = mode)))
                      .toList()),
              const SizedBox(height: 22),
              SoftSurface(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  child: Column(children: [
                    const StudyOrb(size: 48),
                    const SizedBox(height: 18),
                    Text(widget.greeting,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 15, color: studyMuted)),
                    const SizedBox(height: 6),
                    Text('${widget.name}, make room\nfor a little progress.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 28,
                            height: 1.14,
                            color: studyInk,
                            letterSpacing: -.9,
                            fontWeight: FontWeight.w500)),
                  ])),
              const SizedBox(height: 18),
              if (_mode != 'Unwind') ...[
                DreamTile(
                    title: 'Find your focus',
                    subtitle: 'One session. One step closer.',
                    large: true,
                    onTap: widget.onFocus),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                  final learn = DreamTile(
                      title: 'Learn',
                      subtitle: 'Flashcards & mindmaps',
                      palette: DreamPalette.meadow,
                      onTap: widget.onLearn);
                  final videos = DreamTile(
                      title: 'StudyTok',
                      subtitle: 'A fresh perspective',
                      palette: DreamPalette.lilac,
                      onTap: widget.onStudyTok);
                  if (constraints.maxWidth < 320 ||
                      MediaQuery.textScalerOf(context).scale(14) > 21) {
                    return Column(
                        children: [learn, const SizedBox(height: 16), videos]);
                  }
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: learn),
                        const SizedBox(width: 14),
                        Expanded(child: videos),
                      ]);
                }),
                const SizedBox(height: 26),
                _heading('Small steps add up', 'YOUR DAY'),
                const SizedBox(height: 12),
                SoftSurface(
                    child: widget.loading
                        ? const LinearProgressIndicator(
                            semanticsLabel: 'Loading today’s progress')
                        : widget.hasError
                            ? Column(children: [
                                const Text(
                                    'Your progress is temporarily unavailable.',
                                    textAlign: TextAlign.center),
                                TextButton(
                                    onPressed: widget.onRetry,
                                    child: const Text('Try again'))
                              ])
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    _metric('${widget.studyMinutes}',
                                        'Focus minutes'),
                                    _metric(
                                        '${widget.sessionCount}', 'Sessions'),
                                    _metric('${widget.breakMinutes}',
                                        'Break minutes'),
                                  ])),
                const SizedBox(height: 12),
                SoftSurface(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.center_focus_strong_outlined,
                          color: studyAccent),
                      title: const Text('Focus check-in'),
                      subtitle: const Text('Check your attention'),
                      trailing: const Icon(Icons.north_east_rounded, size: 20),
                      onTap: widget.onFocusCheck,
                    )),
                const SizedBox(height: 26),
              ],
              if (_mode != 'Focus') ...[
                _heading('Set the mood', 'A SOFTER BACKGROUND'),
                const SizedBox(height: 12),
                ...kAmbientSounds.map((sound) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftSurface(
                          radius: 32,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(children: [
                            ClipOval(
                                child: SizedBox(
                                    width: 46,
                                    height: 46,
                                    child: DreamArtwork(
                                        palette: DreamPalette.values[
                                            kAmbientSounds.indexOf(sound) %
                                                3]))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(sound.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: studyInk)),
                                  const SizedBox(height: 3),
                                  Text(
                                      widget.playingId == sound.id
                                          ? 'Now playing'
                                          : sound.description,
                                      style: const TextStyle(
                                          color: studyMuted, fontSize: 12)),
                                ])),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: widget.playingId == sound.id
                                  ? 'Stop ${sound.name}'
                                  : 'Play ${sound.name}',
                              style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: studyAccent),
                              onPressed: widget.soundBusy
                                  ? null
                                  : () => widget.onSound(sound),
                              icon: Icon(widget.playingId == sound.id
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded),
                            ),
                          ])),
                    )),
                const SizedBox(height: 16),
              ],
              SoftSurface(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('A MOMENT OF PERSPECTIVE',
                        style: TextStyle(
                            color: studyMuted,
                            fontSize: 10,
                            letterSpacing: 1.3)),
                    const SizedBox(height: 12),
                    Text(widget.quote,
                        style: const TextStyle(
                            color: studyInk, fontSize: 18, height: 1.45)),
                    const SizedBox(height: 10),
                    Text(widget.quoteAuthor,
                        style:
                            const TextStyle(color: studyMuted, fontSize: 12)),
                  ])),
            ],
          ),
        )),
      ));

  Widget _metric(String value, String label) => Expanded(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w500, color: studyInk)),
          const SizedBox(height: 5),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: studyMuted)),
        ]),
      ));
  Widget _heading(String title, String label) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: studyMuted, fontSize: 10, letterSpacing: 1.4)),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(
                color: studyInk,
                fontSize: 23,
                letterSpacing: -.5,
                fontWeight: FontWeight.w500)),
      ]);
}
