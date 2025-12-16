import 'dart:async';
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

// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (initError) {
    debugPrint('Firebase not configured: $initError');
    debugPrint('App will run in offline/demo mode');
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // We call _initFcm here after the first frame is built.
        // It's also called after successful sign-in.
      }
    });
  }

  // --- START: CORRECTED FCM INITIALIZATION LOGIC ---
  Future<void> _initFcm() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    try {
      final messaging = FirebaseMessaging.instance;
      final permissionSettings = await messaging.requestPermission();

      if (permissionSettings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission.');

        // Get the token and pass it to the provider immediately.
        final fcmToken = await messaging.getToken();
        appProvider.scheduleFcmTokenSave(fcmToken);

        // Set up a listener for any future token refreshes.
        messaging.onTokenRefresh.listen((refreshedToken) {
          debugPrint('FCM Token refreshed. Scheduling save.');
          appProvider.scheduleFcmTokenSave(refreshedToken);
        }, onError: (err) {
          debugPrint('Error on FCM token refresh: $err');
        });
      } else {
        debugPrint('User declined or has not accepted notification permission.');
      }

      // --- These listeners handle what happens when a message arrives ---

      // When the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        if (message.notification != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${message.notification!.title}\n${message.notification!.body}'),
            ),
          );
        }
      });

      // When the user taps a notification and opens the app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        // Navigate to the chat page when a notification is tapped.
        setState(() {
          _currentIndex = 1;
        });
      });
    } catch (e, st) {
      debugPrint('Error initializing FCM: $e');
      debugPrint('$st');
    }
  }
  // --- END: CORRECTED FCM INITIALIZATION LOGIC ---

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        // --- ANONYMOUS SIGN-IN SCREEN ---
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
                        // IMPORTANT: After sign-in, we immediately try to initialize FCM.
                        if (mounted) {
                          _initFcm();
                        }
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

        // --- PAIRING SCREEN ---
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

        // --- MAIN APP INTERFACE ---
        final pages = [
          const HomePage(),
          const ChatPage(),
          const CalendarPage(),
        ];

        final pageTitles = [
          'Home',
          'Whispers',
          'Calendar',
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(pageTitles[_currentIndex]),
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
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.nightlight_round,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
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
                                '${settings.maleNickname} & ${settings.femaleNickname}',
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
          const SizedBox(height: 8),
          _buildDrawerTile(
            context: context,
            icon: Icons.settings_rounded,
            title: 'Settings',
            accentColor: accentColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
            isHighlighted: false,
          ),
          const Divider(height: 1),
          _buildDrawerTile(
            context: context,
            icon: Icons.mail_outline,
            title: 'Sealed Letters',
            accentColor: accentColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/sealed-letters');
            },
          ),
          const Divider(
            height: 1,
          ),
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
