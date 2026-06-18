import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ── Category definitions ─────────────────────────────────────────────────────

class _Category {
  final String label;
  final String emoji;
  final String query;
  const _Category(this.label, this.emoji, this.query);
}

const _kCategories = [
  _Category('For You', '🔥', 'study tips explained short'),
  _Category('Maths', '➗', 'mathematics explained short'),
  _Category('Science', '🔬', 'science explained short'),
  _Category('Physics', '⚡', 'physics explained short'),
  _Category('Chemistry', '🧪', 'chemistry explained short'),
  _Category('Biology', '🧬', 'biology explained short'),
  _Category('History', '📜', 'history explained short'),
  _Category('Programming', '💻', 'coding tutorial short'),
  _Category('Languages', '🌍', 'language learning short'),
  _Category('Psychology', '🧠', 'psychology facts short'),
];

/// Keywords that must appear in a YouTube search URL for it to be allowed.
const _kAllowedSearchTerms = [
  'study', 'math', 'mathematics', 'science', 'physics', 'chemistry',
  'biology', 'history', 'coding', 'programming', 'language', 'learn',
  'education', 'psychology', 'explained', 'tutorial', 'short',
];

// JS injected after every page load:
// 1. Hides the YouTube search bar so users cannot type new queries
// 2. Hides the YouTube header logo link so they can't navigate home freely
const _kHideSearchJs = '''
(function() {
  function hideSearch() {
    // Mobile YouTube search form / input
    var selectors = [
      'ytm-searchbox',
      'form[action="/results"]',
      '.mobile-topbar-header-search-button',
      '#search-form',
      'button[aria-label="Search YouTube"]',
      '.searchbox',
      'ytd-searchbox',
      '#search',
      '.ytSearchboxComponentInputBox',
    ];
    selectors.forEach(function(sel) {
      var el = document.querySelector(sel);
      if (el) el.style.setProperty('display', 'none', 'important');
    });
  }
  hideSearch();
  // Re-run after dynamic content loads
  var observer = new MutationObserver(hideSearch);
  observer.observe(document.body || document.documentElement, { childList: true, subtree: true });
})();
''';

// ── Screen ────────────────────────────────────────────────────────────────────

class StudyTokScreen extends StatefulWidget {
  const StudyTokScreen({super.key});

  @override
  State<StudyTokScreen> createState() => _StudyTokScreenState();
}

class _StudyTokScreenState extends State<StudyTokScreen> {
  int _selectedIndex = 0;
  late WebViewController _controller;
  bool _isLoading = true;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNavigationRequest,
        onPageStarted: (_) {
          if (mounted) setState(() { _isLoading = true; _blocked = false; });
        },
        onPageFinished: (_) {
          // Inject JS to remove search bar
          _controller.runJavaScript(_kHideSearchJs);
          if (mounted) setState(() => _isLoading = false);
        },
      ))
      ..loadRequest(Uri.parse(_buildUrl(_kCategories[0].query)));
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url.toLowerCase();

    // Always allow: video watch pages and shorts
    if (url.contains('/watch?') || url.contains('/shorts/') ||
        url.contains('youtube.com/embed') || url.contains('googlevideo.com')) {
      return NavigationDecision.navigate;
    }

    // Allow: our study search results
    if (url.contains('/results') || url.contains('search_query')) {
      final hasStudyTerm = _kAllowedSearchTerms.any((term) => url.contains(term));
      if (hasStudyTerm) return NavigationDecision.navigate;

      // Block non-study search — show warning
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _blocked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚫 StudyTok only allows study-related content.'),
              backgroundColor: Color(0xFFC7664F),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
      return NavigationDecision.prevent;
    }

    // Allow general YouTube navigation (channel pages, etc.) but not search
    return NavigationDecision.navigate;
  }

  String _buildUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://m.youtube.com/results?search_query=$encoded&sp=EgIYAQ%253D%253D';
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedIndex = index;
      _isLoading = true;
      _blocked = false;
    });
    _controller.loadRequest(Uri.parse(_buildUrl(_kCategories[index].query)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Study',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: 'Tok',
                          style: TextStyle(
                            color: Color(0xFFF2A9AE),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    onPressed: () {
                      setState(() => _blocked = false);
                      _controller.reload();
                    },
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            // ── Category chips ───────────────────────────────────────────────
            Container(
              color: Colors.black,
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _kCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _kCategories[i];
                  final selected = i == _selectedIndex;
                  return GestureDetector(
                    onTap: () => _selectCategory(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF2A9AE)
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFF2A9AE)
                              : const Color(0xFF333333),
                        ),
                      ),
                      child: Text(
                        '${cat.emoji}  ${cat.label}',
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            // ── WebView ──────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFF2A9AE)),
                          SizedBox(height: 12),
                          Text(
                            'Loading study videos...',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  if (_blocked)
                    Container(
                      color: Colors.black87,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🚫', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            const Text(
                              'Study topics only!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'StudyTok only shows educational content.\nPick a topic from the categories above.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white60, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => _selectCategory(_selectedIndex),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF2A9AE),
                              ),
                              child: const Text('Go back to studying'),
                            ),
                          ],
                        ),
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
