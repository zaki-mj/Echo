import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("My Profile")),
      appBar: AppBar(
        actions: [],
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("My profile"),
      ),
    );
  }
}
