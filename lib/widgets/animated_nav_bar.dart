// lib/widgets/animated_nav_bar.dart

import 'package:charmy_craft_studio/screens/buy_the_vibe/buy_the_vibe_screen.dart'; // Import the new screen
import 'package:charmy_craft_studio/screens/creator_profile/creator_profile_screen.dart';
import 'package:charmy_craft_studio/screens/discover/discover_screen.dart';
import 'package:charmy_craft_studio/screens/favorites/favorites_screen.dart';
import 'package:charmy_craft_studio/screens/profile/profile_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnimatedNavBar extends StatefulWidget {
  const AnimatedNavBar({super.key});

  @override
  State<AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar> {
  int _pageIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  final List<Widget> _pages = [
    const DiscoverScreen(),
    const FavoritesScreen(),
    const CreatorProfileScreen(),
    const BuyTheVibeScreen(), // USE THE NEW SCREEN
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final Color navBarColor = Theme.of(context).colorScheme.surface;
    final Color navBarButtonBgColor =
    Theme.of(context).colorScheme.secondary.withOpacity(0.9);
    final IconThemeData iconTheme = Theme.of(context).iconTheme;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _pageIndex,
        height: 60.0,
        items: <Widget>[
          Icon(Icons.home_outlined,
              size: 30,
              color: _pageIndex == 0 ? Colors.white : iconTheme.color),
          Icon(Icons.favorite_outline,
              size: 30,
              color: _pageIndex == 1 ? Colors.white : iconTheme.color),
          FaIcon(FontAwesomeIcons.palette,
              size: 26,
              color: _pageIndex == 2 ? Colors.white : iconTheme.color),
          Icon(Icons.shopping_bag_outlined,
              size: 30,
              color: _pageIndex == 3 ? Colors.white : iconTheme.color),
          Icon(Icons.person_outline,
              size: 30,
              color: _pageIndex == 4 ? Colors.white : iconTheme.color),
        ],
        color: navBarColor,
        buttonBackgroundColor: navBarButtonBgColor,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
      body: _pages[_pageIndex],
    );
  }
}