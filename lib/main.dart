import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_provider.dart';
import 'theme/gothic_theme.dart';
import 'pages/home_page.dart';
import 'pages/chat_page.dart';
import 'pages/calendar_page.dart';
import 'pages/gallery_page.dart';
import 'pages/settings_page.dart';
import 'pages/sealed_letters_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase, but don't fail if it's not configured
  try {
    // Check if Firebase is already initialized
    Firebase.app();
  } catch (e) {
    // Firebase not initialized, try to initialize it
    try {
      await Firebase.initializeApp();
    } catch (initError) {
      // Firebase not configured - app will work in offline mode
      debugPrint('Firebase not configured: $initError');
      debugPrint('App will run in offline/demo mode');
    }
  }

  runApp(const RavenApp());
}

class RavenApp extends StatelessWidget {
  const RavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = AppProvider();
        provider.initialize().catchError((e) {
          debugPrint('Error initializing app: $e');
        });
        return provider;
      },
      child: Builder(
        builder: (context) {
          return Consumer<AppProvider>(
            builder: (context, appProvider, _) {
              // Use a default theme if appProvider isn't ready
              final theme = appProvider.isInitialized ? appProvider.theme : GothicTheme.getDarkTheme(0);

              return MaterialApp(
                title: 'Raven - Eternal Bond',
                theme: theme,
                debugShowCheckedModeBanner: false,
                home: const MainScreen(),
                routes: {
                  '/home': (context) => const HomePage(),
                  '/chat': (context) => const ChatPage(),
                  '/calendar': (context) => const CalendarPage(),
                  '/gallery': (context) => const GalleryPage(),
                  '/settings': (context) => const SettingsPage(),
                  '/sealed-letters': (context) => const SealedLettersPage(),
                },
              );
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        // Check if user is signed in
        if (appProvider.currentUserId == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Raven',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Eternal Bond',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await appProvider.signIn();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sign in error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Begin'),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if settings are initialized
        if (appProvider.settings == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Initializing...',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.pushNamed(context, '/settings');
                      }
                    },
                    child: const Text('Configure Settings'),
                  ),
                ],
              ),
            ),
          );
        }

        final pages = [
          const HomePage(),
          const ChatPage(),
          const CalendarPage(),
          const GalleryPage(),
        ];

        return Scaffold(
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: appProvider.accentColor,
                  ),
                  child: const Text(
                    'Raven',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.mail),
                  title: const Text('Sealed Letters'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/sealed-letters');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () async {
                    await appProvider.signOut();
                  },
                ),
              ],
            ),
          ),
          body: pages[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.photo_library_outlined),
                selectedIcon: Icon(Icons.photo_library),
                label: 'Gallery',
              ),
            ],
          ),
        );
      },
    );
  }
}
