import 'package:flutter_test/flutter_test.dart';
import 'package:studymate/features/studytok/models/study_video.dart';

void main() {
  final matched = <String, dynamic>{
    'youtubeId': 'abcdefghijk',
    'title': 'Fractions',
    'creator': 'Math teacher',
    'subject': 'Maths',
    'description': 'Add fractions. #Maths',
    'hashtags': ['#Maths'],
  };
  test('only valid hashtag matches can enter the feed', () {
    expect(StudyVideo.parse('one', matched), isNotNull);
    for (final patch in [
      {
        'hashtags': ['#Comedy']
      },
      {'hashtags': 'study'},
      {'youtubeId': 'https://youtube.com'},
      {'title': ''},
      {'subject': 'Comedy'},
      {'creator': 42},
      {'hashtags': []},
    ]) {
      expect(StudyVideo.parse('one', {...matched, ...patch}), isNull);
    }
  });
  test(
      'navigation cannot escape to searches, other videos, schemes or spoofed hosts',
      () {
    expect(
        allowsStudyVideoNavigation(
            'https://www.youtube-nocookie.com/embed/abcdefghijk?rel=0',
            'abcdefghijk'),
        isTrue);
    for (final url in [
      'https://www.youtube.com/watch?v=abcdefghijk',
      'https://www.youtube.com/results?search_query=study+funny',
      'https://www.youtube.com/shorts/abcdefghijk',
      'https://www.youtube.com/embed/otherVideo1',
      'https://www.youtube.com.evil.test/embed/abcdefghijk',
      'https://www.youtube.com@evil.test/embed/abcdefghijk',
      'http://www.youtube.com/embed/abcdefghijk',
      'javascript:alert(1)',
      'youtube://watch?v=abcdefghijk',
      'https://www.youtube.com/embed/abcdefghijk?list=arbitrary',
    ]) {
      expect(allowsStudyVideoNavigation(url, 'abcdefghijk'), isFalse,
          reason: url);
    }
  });
}
