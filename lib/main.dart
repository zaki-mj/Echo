import 'package:echo/app.dart';
import 'package:echo/features/authentication/authentication_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ShadcnApp(
      title: 'My App',
      theme: ShadThemeData(
        colorScheme: ShadColorSchemes.zincDark, // or ShadColorSchemes.zincLight
        radius: 0.5,
      ),
      home: const AuthenticationScreen(),
    ),
  );
}


  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  // print('firebase initialized');
  // SystemChrome.setSystemUIOverlayStyle(
  // const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent));
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // runApp(const MyApp());
