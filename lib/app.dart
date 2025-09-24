import 'package:echo/core/theme/app_theme.dart';
import 'package:echo/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return MaterialApp.router(
      theme: AppTheme.darkTheme,
      title: 'Echo',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter as RouterConfig<Object>,
    );
  }
}
