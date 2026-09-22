import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../../../shared/widgets/study_tab_bar.dart';
import '../../timer/screens/timer_screen.dart';
import '../../ai_flashcards/screens/flashcards_screen.dart';
import '../../ai_mindmap/screens/mindmaps_screen.dart';
import '../../study_streaks/screens/study_streaks_page.dart';
import '../../studytok/screens/studytok_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final _visited = <int>{0};

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _visited.add(index);
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigate: _selectTab),
      const TimerScreen(),
      const _LearningTools(),
      StudyTokScreen(active: _currentIndex == 3),
      const StudyStreaksPage(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
            screens.length,
            (index) => _visited.contains(index)
                ? TickerMode(
                    enabled: _currentIndex == index, child: screens[index])
                : const SizedBox.shrink()),
      ),
      bottomNavigationBar:
          StudyTabBar(selectedIndex: _currentIndex, onSelected: _selectTab),
    );
  }
}

class _LearningTools extends StatefulWidget {
  const _LearningTools();
  @override
  State<_LearningTools> createState() => _LearningToolsState();
}

class _LearningToolsState extends State<_LearningTools> {
  int _selected = 0;
  bool _openedMindmaps = false;
  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                    value: 0,
                    label: Text('Flashcards'),
                    icon: Icon(Icons.quiz_outlined)),
                ButtonSegment(
                    value: 1,
                    label: Text('Mindmaps'),
                    icon: Icon(Icons.account_tree_outlined)),
              ],
              selected: {_selected},
              onSelectionChanged: (value) => setState(() {
                _selected = value.first;
                _openedMindmaps |= _selected == 1;
              }),
            ),
          ),
          Expanded(
              child: IndexedStack(index: _selected, children: [
            const FlashcardsScreen(),
            if (_openedMindmaps)
              const MindmapsScreen()
            else
              const SizedBox.shrink(),
          ])),
        ]),
      );
}
