import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:echo/features/chat/chat_list_screen.dart';
import 'package:echo/features/profile/profile_screen.dart';
import 'package:echo/features/search/search_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _getIndexFromLocation(state.uri.toString()),
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/');
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
              NavigationDestination(icon: Icon(Icons.chat), label: "Chats"),
              NavigationDestination(icon: Icon(Icons.search), label: "Search"),
              NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        );
      },
      routes: [
        
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const ChatListScreen();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'search',
              builder: (BuildContext context, GoRouterState state) {
                return const SearchScreen();
              },
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
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

