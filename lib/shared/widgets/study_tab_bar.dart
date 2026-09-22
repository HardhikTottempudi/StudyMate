import 'package:flutter/material.dart';
import 'soft_surface.dart';

class StudyTabBar extends StatelessWidget {
  const StudyTabBar(
      {super.key, required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => SoftBackdrop(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: NavigationBar(
            height: 70,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.timelapse_outlined),
                  selectedIcon: Icon(Icons.timelapse_rounded),
                  label: 'Focus'),
              NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories_rounded),
                  label: 'Learn'),
              NavigationDestination(
                  icon: Icon(Icons.play_circle_outline),
                  selectedIcon: Icon(Icons.play_circle),
                  label: 'StudyTok'),
              NavigationDestination(
                  icon: Icon(Icons.local_fire_department_outlined),
                  selectedIcon: Icon(Icons.local_fire_department),
                  label: 'Streaks'),
            ],
          ),
        ),
      ));
}
