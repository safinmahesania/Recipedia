import 'package:flutter/material.dart';
import '../favorites/favorites_view.dart';
import '../profile/profile_view.dart';
import '../recipes/recipe_list_view.dart';
import '../scan/scan_view.dart';
import 'home_view.dart';
import '../../shared/widgets/app_icon.dart';

/// Single bottom-nav shell. Tabs swap the body — no full-screen re-navigation.
///
/// All nav colours now come from navigationBarTheme; nothing is set here, so
/// the bar follows light/dark automatically. The "Favorites" label became
/// "Saved" to match the screen it opens.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _tabs = [
    const HomeView(),
    RecipeListView(showAppBar: false),
    const ScanView(),
    const FavoritesView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: AppIcon('home_outlined'),
              selectedIcon: AppIcon('home', filled: true),
              label: 'Home'),
          NavigationDestination(
              icon: AppIcon('menu_book_outlined'),
              selectedIcon: AppIcon('menu_book', filled: true),
              label: 'Recipes'),
          NavigationDestination(
              icon: AppIcon('document_scanner_outlined'),
              selectedIcon: AppIcon('document_scanner', filled: true),
              label: 'Scan'),
          NavigationDestination(
              icon: AppIcon('bookmark_border'),
              selectedIcon: AppIcon('bookmark', filled: true),
              label: 'Saved'),
          NavigationDestination(
              icon: AppIcon('person_outline'),
              selectedIcon: AppIcon('person', filled: true),
              label: 'Profile'),
        ],
      ),
    );
  }
}
