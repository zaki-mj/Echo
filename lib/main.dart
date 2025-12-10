import 'package:echo/providers/theme_provider.dart';
import 'package:echo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/chat_page.dart';
import 'pages/calendar_page.dart';
import 'pages/gallery_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, theme, child) {
          return MaterialApp(
            title: 'Raven',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomePage(),
            routes: {
              '/chat': (context) => const ChatPage(),
              '/calendar': (context) => const CalendarPage(),
              '/gallery': (context) => const GalleryPage(),
            },
          );
        },
      ),
    );
  }
}
