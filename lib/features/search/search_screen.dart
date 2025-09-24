import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Search")),
      appBar: AppBar(
        actions: [],
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("Search"),
      ),
    );
  }
}
