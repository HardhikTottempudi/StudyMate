import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studymate/features/studytok/models/study_video.dart';
import 'package:studymate/features/studytok/screens/studytok_screen.dart';
import 'package:studymate/features/studytok/services/studytok_service.dart';
import 'package:studymate/shared/theme/app_theme.dart';

void main() {
  const lesson = StudyVideo(
      id: 'abcdefghijk',
      youtubeId: 'abcdefghijk',
      title: 'Adding fractions',
      subject: 'Maths',
      creator: 'Teacher',
      description: 'Find a common denominator. #Maths',
      tags: ['#Maths']);
  Future<void> showFeed(WidgetTester tester,
      Future<List<StudyVideo>> Function(String) load) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          studyVideosProvider.overrideWith((ref, tag) => load(tag)),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme, home: const StudyTokScreen())));
    await tester.pump();
  }

  testWidgets('empty search has an honest empty state', (tester) async {
    await showFeed(tester, (_) async => []);
    expect(find.textContaining('No matching videos'), findsOneWidget);
    expect(find.text('Play lesson'), findsNothing);
  });
  testWidgets('network failure offers retry', (tester) async {
    await showFeed(
        tester, (_) async => throw const StudyTokException('unavailable'));
    expect(find.text('Try again'), findsOneWidget);
  });
  testWidgets('missing API setup is not presented as a connection issue',
      (tester) async {
    await showFeed(tester,
        (_) async => throw const StudyTokException('youtube_setup_required'));
    expect(find.text('StudyTok is being set up'), findsOneWidget);
    expect(find.textContaining('connection'), findsNothing);
  });
  testWidgets('quota failure has a distinct message', (tester) async {
    await showFeed(tester,
        (_) async => throw const StudyTokException('youtube_quota_exceeded'));
    expect(find.text('Video search is taking a break'), findsOneWidget);
  });
  testWidgets('selecting a hashtag requests its own results', (tester) async {
    final requested = <String>[];
    await showFeed(tester, (tag) async {
      requested.add(tag);
      return tag == '#Science' ? [] : [lesson];
    });
    expect(find.text('Adding fractions'), findsOneWidget);
    await tester.tap(find.text('#Science'));
    await tester.pumpAndSettle();
    expect(requested, ['All', '#Science']);
    expect(find.text('Adding fractions'), findsNothing);
    expect(find.textContaining('No matching videos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty state fits a small iPhone with large text',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          studyVideosProvider.overrideWith((ref, tag) async => []),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: const StudyTokScreen())));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
