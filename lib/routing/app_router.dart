import 'package:echo/features/authentication/authentication_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:echo/features/chat/chat_list_screen.dart';
import 'package:echo/features/profile/profile_screen.dart';
import 'package:echo/features/search/search_screen.dart';
import 'package:animations/animations.dart';

CustomTransitionPage<T> buildHorizontalPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        child: child,
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: state.uri.toString() == '/'
              ? SizedBox.shrink()
              : NavigationBar(
                  selectedIndex: _getIndexFromLocation(state.uri.toString()),
                  onDestinationSelected: (index) {
                    switch (index) {
                      case 0:
                        context.go('/chats');
                        break;
                      case 1:
                        context.go('/search');
                        break;
                      case 2:
                        context.go('/profile');
                        break;
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.chat), label: "Chats"),
                    NavigationDestination(
                        icon: Icon(Icons.search), label: "Search"),
                    NavigationDestination(
                        icon: Icon(Icons.person), label: "Profile"),
                  ],
                ),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => buildHorizontalPage(
              state: state, child: const AuthenticationScreen()),
        ),
        GoRoute(
          path: '/chats',
          pageBuilder: (context, state) =>
              buildHorizontalPage(state: state, child: const ChatListScreen()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) =>
              buildHorizontalPage(state: state, child: const SearchScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              buildHorizontalPage(state: state, child: const ProfileScreen()),
        ),
      ],
    ),
  ],
);

int _getIndexFromLocation(String location) {
  if (location.startsWith('/search')) return 1;
  if (location.startsWith('/profile')) return 2;
  return 0; // default = chats
}
