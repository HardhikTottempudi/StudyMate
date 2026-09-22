import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studymate/features/studytok/services/studytok_service.dart';

void main() {
  test(
      'uses server authentication and filters malformed, duplicate and wrong-tag responses',
      () async {
    final video = {
      'youtubeId': 'abcdefghijk',
      'title': 'Fractions',
      'creator': 'Teacher',
      'subject': 'Maths',
      'description': '#Maths',
      'hashtags': ['#Maths']
    };
    final service = StudyTokService(
        token: () async => 'test-token',
        baseUrl: 'https://backend.example',
        client: MockClient((request) async {
          expect(request.url.path, '/studytok/videos');
          expect(request.url.queryParameters['hashtag'], '#Maths');
          expect(request.headers['Authorization'], 'Bearer test-token');
          return http.Response(
              jsonEncode({
                'videos': [
                  video,
                  video,
                  {},
                  {
                    ...video,
                    'youtubeId': 'lmnopqrstuv',
                    'hashtags': ['#Science']
                  }
                ]
              }),
              200);
        }));
    addTearDown(service.dispose);
    final videos = await service.load('#Maths');
    expect(videos.length, 1);
    expect(videos.single.youtubeId, 'abcdefghijk');
  });
  test('missing endpoint is a setup error', () async {
    final service = StudyTokService(
        token: () async => 'token',
        client: MockClient((_) async => http.Response('Not found', 404)));
    addTearDown(service.dispose);
    await expectLater(
        service.load('All'),
        throwsA(isA<StudyTokException>()
            .having((e) => e.code, 'code', 'youtube_setup_required')));
  });
  test('unsupported hashtags never make a request', () async {
    final service = StudyTokService(
        token: () async => 'token',
        client: MockClient((_) async => throw StateError('Must not request')));
    addTearDown(service.dispose);
    await expectLater(
        service.load('#Funny'), throwsA(isA<StudyTokException>()));
  });
  test('signed-out users never make a request', () async {
    final service = StudyTokService(
        token: () async => null,
        client: MockClient((_) async => throw StateError('Must not request')));
    addTearDown(service.dispose);
    await expectLater(
        service.load('All'),
        throwsA(isA<StudyTokException>()
            .having((e) => e.code, 'code', 'unauthenticated')));
  });
}
