import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:studymate/shared/widgets/study_tab_bar.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studymate/features/dashboard/widgets/study_dashboard_view.dart';
import 'package:studymate/shared/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final config =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString());
    final package =
        (config['packages'] as List).firstWhere((p) => p['name'] == 'flutter');
    final root = Uri.base
        .resolve('.dart_tool/package_config.json')
        .resolve(package['rootUri'] as String);
    final fonts =
        Uri.parse(root.toString().endsWith('/') ? root.toString() : '$root/')
            .resolve('../../bin/cache/artifacts/material_fonts/');
    for (final family in ['Roboto', 'MaterialIcons']) {
      final loader = FontLoader(family);
      final names = family != 'MaterialIcons'
          ? ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']
          : ['MaterialIcons-Regular.otf'];
      for (final name in names) {
        loader.addFont(File.fromUri(fonts.resolve(name))
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)));
      }
      await loader.load();
    }
  });
  Widget dashboard({VoidCallback? focus}) => StudyDashboardView(
        name: 'Taisha',
        greeting: 'Good morning',
        studyMinutes: 45,
        sessionCount: 2,
        breakMinutes: 10,
        quote: 'Strive for progress, not perfection.',
        quoteAuthor: 'A reminder for today',
        onFocus: focus ?? () {},
        onLearn: () {},
        onStudyTok: () {},
        onSignOut: () {},
        onRetry: () {},
        onFocusCheck: () {},
        onSound: (_) {},
      );
  Future<void> phone(WidgetTester tester, Widget child,
      {double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('preview'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme.copyWith(
            chipTheme: AppTheme.lightTheme.chipTheme.copyWith(
              labelStyle: AppTheme.lightTheme.chipTheme.labelStyle?.copyWith(fontFamily: 'Roboto')),
          ),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 44, bottom: 20)),
              child: child!),
          home: Scaffold(
              body: child,
              bottomNavigationBar:
                  StudyTabBar(selectedIndex: 0, onSelected: (_) {})),
        )));
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard renders and the focus card opens focus',
      (tester) async {
    var opened = false;
    await phone(tester, dashboard(focus: () => opened = true));
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('UPDATE_PREVIEWS')) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('preview')));
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('docs/previews').create(recursive: true);
        await File('docs/previews/dashboard.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.ensureVisible(find.text('Find your focus'));
    await tester.tap(find.text('Find your focus'));
    expect(opened, isTrue);
  });
  testWidgets('large text and Unwind filter keep audio controls accessible',
      (tester) async {
    await phone(tester, dashboard(), scale: 2);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Unwind'));
    await tester.pumpAndSettle();
    expect(find.text('Find your focus'), findsNothing);
    await tester.scrollUntilVisible(find.byTooltip('Play Rain'), 200);
    expect(find.byTooltip('Play Rain'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
