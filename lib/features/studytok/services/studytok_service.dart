import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/study_video.dart';

class StudyTokException implements Exception {
  const StudyTokException(this.code);
  final String code;
}

class StudyTokService {
  StudyTokService(
      {http.Client? client, Future<String?> Function()? token, String? baseUrl})
      : _client = client ?? http.Client(),
        _token = token ??
            (() async => FirebaseAuth.instance.currentUser?.getIdToken()),
        _baseUrl = baseUrl ??
            const String.fromEnvironment('AI_BACKEND_BASE_URL',
                defaultValue: 'https://fetchdata-jx72.onrender.com');
  final http.Client _client;
  final Future<String?> Function() _token;
  final String _baseUrl;

  Future<List<StudyVideo>> load(String hashtag) async {
    if (hashtag != 'All' && !StudyVideo.discoveryHashtags.contains(hashtag)) {
      throw const StudyTokException('invalid_hashtag');
    }
    try {
      final token = await _token().timeout(const Duration(seconds: 10));
      if (token == null) throw const StudyTokException('unauthenticated');
      final base = Uri.parse(_baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/');
      final response = await _client.get(
          base
              .resolve('studytok/videos')
              .replace(queryParameters: {'hashtag': hashtag}),
          headers: {
            'Authorization': 'Bearer $token'
          }).timeout(const Duration(seconds: 30));
      if (response.statusCode == 401)
        throw const StudyTokException('unauthenticated');
      if (response.statusCode == 404)
        throw const StudyTokException('youtube_setup_required');
      final body = jsonDecode(response.body);
      if (response.statusCode != 200) {
        final code = body is Map ? body['detail'] : null;
        throw StudyTokException(code is String ? code : 'unavailable');
      }
      if (body is! Map || body['videos'] is! List) {
        throw const StudyTokException('unavailable');
      }
      final videos = <String, StudyVideo>{};
      for (final entry in body['videos'] as List) {
        if (entry is! Map<String, dynamic>) continue;
        final video = StudyVideo.parse(
            entry['youtubeId'] is String ? entry['youtubeId'] as String : '',
            entry);
        if (video != null &&
            (hashtag == 'All' || video.hashtags.contains(hashtag))) {
          videos[video.id] = video;
        }
      }
      return videos.values.toList();
    } on StudyTokException {
      rethrow;
    } on FirebaseAuthException {
      throw const StudyTokException('unauthenticated');
    } on TimeoutException {
      throw const StudyTokException('unavailable');
    } on FormatException {
      throw const StudyTokException('unavailable');
    } on http.ClientException {
      throw const StudyTokException('unavailable');
    }
  }

  void dispose() => _client.close();
}
