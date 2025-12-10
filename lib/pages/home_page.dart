import 'package:echo/widget/side_drawer.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: const SideDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMoodsSection(context),
          const SizedBox(height: 20),
          _buildWhisperSection(context),
          const SizedBox(height: 20),
          _buildEternalCounters(context),
          const SizedBox(height: 20),
          _buildChatTeaser(context),
        ],
      ),
    );
  }

  Widget _buildMoodsSection(BuildContext context) {
    // Placeholder for side-by-side moods
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Icon(Icons.person, size: 50),
            Text("Your Mood"),
          ],
        ),
        Column(
          children: [
            Icon(Icons.favorite, size: 50),
            Text("Partner's Mood"),
          ],
        ),
      ],
    );
  }

  Widget _buildWhisperSection(BuildContext context) {
    // Placeholder for Send Whisper
    return ElevatedButton(
      onPressed: () {},
      child: const Text("Send Whisper"),
    );
  }

  Widget _buildEternalCounters(BuildContext context) {
    // Placeholder for eternal counters
    return const Column(
      children: [
        Text("Nights since our blood crossed: 1,247"),
        Text("Unbroken flame: 312 days"),
      ],
    );
  }

  Widget _buildChatTeaser(BuildContext context) {
    // Placeholder for chat teaser
    return const Card(
      child: ListTile(
        title: Text("Today's Whispers"),
        subtitle: Text("Your love whispered sweet nothings..."),
        trailing: Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
