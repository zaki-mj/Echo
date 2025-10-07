import 'package:echo/features/authentication/authentication_screen.dart';
import 'package:echo/routing/app_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return ShadcnApp.router(
      routerConfig: appRouter as RouterConfig<Object>,
      debugShowCheckedModeBanner: false, theme:ThemeData(
        colorScheme: ColorSchemes.darkZinc(),
        radius: 0.5,
      ), 
    );
  }
}
