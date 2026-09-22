import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../firebase_options.dart';
import '../models/study_video.dart';

/// A single hashtag-matched YouTube embed, never a YouTube browsing page.
/// YouTube-owned player UI is not a strict content-isolation boundary.
class StudyVideoPlayer extends StatefulWidget {
  const StudyVideoPlayer(
      {super.key, required this.video, required this.onFinished});
  final StudyVideo video;
  final VoidCallback onFinished;
  @override
  State<StudyVideoPlayer> createState() => _StudyVideoPlayerState();
}

class _StudyVideoPlayerState extends State<StudyVideoPlayer> {
  late final WebViewController _controller;
  Timer? _timeout;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setBackgroundColor(const Color(0xFF151724))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('StudyPlayer', onMessageReceived: (message) {
        if (!mounted || _failed) return;
        if (message.message == 'ready') {
          _timeout?.cancel();
          setState(() => _ready = true);
        } else if (message.message == 'finished' ||
            message.message == 'blocked') {
          widget.onFinished();
        } else if (message.message == 'error') {
          _fail();
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          // The wrapper is supplied as HTML. No top-level browsing is allowed.
          if (request.url == 'about:blank') return NavigationDecision.navigate;
          if (!request.isMainFrame &&
              allowsStudyVideoNavigation(request.url, widget.video.youtubeId)) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true) _fail();
        },
      ));
    _load();
  }

  Future<void> _load() async {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 25), _fail);
    final origin =
        'https://${DefaultFirebaseOptions.currentPlatform.projectId}.web.app';
    final id = jsonEncode(widget.video.youtubeId);
    try {
      await _controller.loadHtmlString('''
<!doctype html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>html,body,#player{margin:0;width:100%;height:100%;background:#151724;overflow:hidden}</style>
</head><body><div id="player"></div>
<script>
var player;
function report(value) { StudyPlayer.postMessage(value); }
function onYouTubeIframeAPIReady() {
  player = new YT.Player('player', {
    host: 'https://www.youtube-nocookie.com', videoId: $id,
    playerVars: {playsinline:1, autoplay:0, rel:0, origin:${jsonEncode(origin)}},
    events: {
      onReady:function(){report('ready');},
      onError:function(){report('error');},
      onStateChange:function(event){
        // Defense in depth; iframe-internal navigation is not fully observable.
        var current = new URL(player.getVideoUrl()).searchParams.get('v');
        if(current && current !== $id) { player.stopVideo(); report('blocked'); return; }
        if(event.data === YT.PlayerState.ENDED) { player.stopVideo(); report('finished'); }
      }
    }
  });
}
</script><script src="https://www.youtube.com/iframe_api"></script></body></html>
''', baseUrl: origin);
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    if (!mounted || _failed) return;
    _timeout?.cancel();
    setState(() => _failed = true);
    unawaited(
        _controller.loadRequest(Uri.parse('about:blank')).catchError((_) {}));
  }

  @override
  void dispose() {
    _timeout?.cancel();
    // Also stop playback when leaving the tab, swiping or backgrounding iOS.
    unawaited(
        _controller.loadRequest(Uri.parse('about:blank')).catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed)
      return ColoredBox(
          color: const Color(0xFF242637),
          child: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text(
                      'This lesson couldn’t play. It may be unavailable or your connection was interrupted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white)),
                  TextButton(
                      onPressed: widget.onFinished,
                      child: const Text('Back to lesson')),
                ])),
          ));
    return Stack(children: [
      WebViewWidget(controller: _controller),
      if (!_ready)
        const Positioned.fill(
            child: ColoredBox(
                color: Color(0xFF242637),
                child: Center(
                    child: CircularProgressIndicator(
                        semanticsLabel: 'Loading lesson')))),
    ]);
  }
}
