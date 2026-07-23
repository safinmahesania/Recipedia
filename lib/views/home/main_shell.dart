import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../favorites/favorites_view.dart';
import '../profile/profile_view.dart';
import '../recipes/recipe_list_view.dart';
import '../scan/scan_view.dart';
import 'home_view.dart';

/// Single bottom-nav shell. Tabs swap the body — no full-screen re-navigation.
/// (The old code rebuilt the nav bar in every screen; this replaces all of that.)
class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

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
        indicatorColor: AppColors.primaryTint,
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.primary), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book, color: AppColors.primary), label: 'Recipes'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), selectedIcon: Icon(Icons.qr_code_scanner, color: AppColors.primary), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite, color: AppColors.primary), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.primary), label: 'Profile'),
        ],
      ),
    );
  }
}
