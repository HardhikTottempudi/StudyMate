class StudyVideo {
  const StudyVideo(
      {required this.id,
      required this.youtubeId,
      required this.title,
      required this.subject,
      required this.creator,
      required this.description,
      this.tags = const []});
  final String id, youtubeId, title, subject, creator, description;

  final List<String> tags;
  List<String> get hashtags => tags;
  static const discoveryHashtags = [
    '#Maths',
    '#Science',
    '#StudyTips',
    '#Study',
    '#StudyTok',
    '#StudyWithMe',
    '#ActiveRecall',
    '#SpacedRepetition',
    '#ExamPrep',
    '#Revision',
    '#Flashcards',
    '#NoteTaking',
    '#Pomodoro',
    '#Physics',
    '#Chemistry',
    '#Biology',
    '#History',
    '#Coding',
    '#LanguageLearning',
    '#Algebra',
    '#Calculus',
    '#ComputerScience',
  ];

  static const subjects = [
    'Maths',
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Programming',
    'Languages',
    'Study skills'
  ];

  // Accept only well-formed hashtag matches returned by the backend.
  static StudyVideo? parse(String id, Map<String, dynamic> data) {
    String value(String key) =>
        data[key] is String ? (data[key] as String).trim() : '';
    final videoId = value('youtubeId');
    final rawTags = data['hashtags'];
    if (rawTags is! List ||
        rawTags.isEmpty ||
        rawTags.length > discoveryHashtags.length ||
        rawTags
            .any((tag) => tag is! String || !discoveryHashtags.contains(tag))) {
      return null;
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(videoId) ||
        !subjects.contains(value('subject')) ||
        ['title', 'creator']
            .any((key) => value(key).isEmpty || value(key).length > 300) ||
        value('description').length > 500) {
      return null;
    }
    return StudyVideo(
        id: id,
        youtubeId: videoId,
        title: value('title'),
        subject: value('subject'),
        creator: value('creator'),
        description: value('description'),
        tags: List<String>.from(rawTags).toSet().toList());
  }
}

bool allowsStudyVideoNavigation(String url, String youtubeId) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443)) return false;
  return const {'www.youtube.com', 'www.youtube-nocookie.com'}
          .contains(uri.host) &&
      uri.path == '/embed/$youtubeId' &&
      !uri.queryParameters.keys.any(const {'list', 'playlist'}.contains);
}
