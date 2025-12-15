import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/app_provider.dart';
import 'theme/gothic_theme.dart';
import 'pages/home_page.dart';
import 'pages/chat_page.dart';
import 'pages/calendar_page.dart';
import 'pages/settings_page.dart';
import 'pages/sealed_letters_page.dart';
import 'pages/pairing_page.dart';

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
                title: 'Raven',
                theme: theme,
                debugShowCheckedModeBanner: false,
                home: const MainScreen(),
                routes: {
                  '/home': (context) => const HomePage(),
                  '/chat': (context) => const ChatPage(),
                  '/calendar': (context) => const CalendarPage(),
                  '/settings': (context) => const SettingsPage(),
                  '/sealed-letters': (context) => const SealedLettersPage(),
                  '/pairing': (context) => const PairingPage(),
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

  Future<void> _initFcm() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions (especially important on iOS / Android 13+)
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('FCM registration token: $token');
        // Copy this token into Firebase Console -> Cloud Messaging -> Test device
      } else {
        debugPrint('FCM token is null (permission not granted or error).');
      }
    } catch (e, st) {
      debugPrint('Error initializing FCM: $e');
      debugPrint('$st');
    }
  }

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
                        await _initFcm();
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

        // Check if settings are initialized or if pairing is needed
        if (appProvider.settings == null || appProvider.needsPairing) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (appProvider.settings == null)
                    const CircularProgressIndicator()
                  else
                    Icon(
                      Icons.link_off,
                      size: 64,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  const SizedBox(height: 24),
                  Text(
                    appProvider.settings == null ? 'Initializing...' : 'Pairing Required',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.pushNamed(context, '/pairing');
                      }
                    },
                    child: const Text('Pair Device'),
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
        ];

        // Get the current page's title for the AppBar
        final pageTitles = [
          'Home',
          'Whispers',
          'Calendar',
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(pageTitles[_currentIndex]),
            // Drawer icon will automatically appear when drawer is set
            automaticallyImplyLeading: true,
          ),
          drawer: _buildGothicDrawer(context, appProvider),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildGothicDrawer(BuildContext context, AppProvider appProvider) {
    final settings = appProvider.settings;
    final accentColor = appProvider.accentColor;

    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Beautiful Header with gradient
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor,
                  accentColor.withOpacity(0.7),
                  accentColor.withOpacity(0.5),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Decorative moon/bat icon
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.nightlight_round,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Raven',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Eternal Bond',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      if (settings != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${settings.user1Nickname} & ${settings.user2Nickname}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          const SizedBox(height: 8),

          // Settings - Prominent
          _buildDrawerTile(
            context: context,
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Configure your eternal bond',
            accentColor: accentColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
            isHighlighted: true,
          ),

          const Divider(height: 1),

          // Sealed Letters
          _buildDrawerTile(
            context: context,
            icon: Icons.mail_outline,
            title: 'Sealed Letters',
            subtitle: 'Time-locked messages',
            accentColor: accentColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/sealed-letters');
            },
          ),

          // Home
          _buildDrawerTile(
            context: context,
            icon: Icons.home_outlined,
            title: 'Home',
            subtitle: 'Return to home',
            accentColor: accentColor,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
              });
            },
          ),

          const Divider(height: 1),

          // Sign Out
          _buildDrawerTile(
            context: context,
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'End this session',
            accentColor: accentColor,
            onTap: () async {
              Navigator.pop(context);
              await appProvider.signOut();
            },
            isDestructive: true,
          ),

          const SizedBox(height: 16),

          // Footer info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    bool isHighlighted = false,
    bool isDestructive = false,
  }) {
    final tileColor = isHighlighted ? accentColor.withOpacity(0.1) : Colors.transparent;
    final iconColor = isDestructive
        ? Colors.redAccent
        : isHighlighted
            ? accentColor
            : Theme.of(context).iconTheme.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighlighted ? accentColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isDestructive ? Colors.redAccent : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
