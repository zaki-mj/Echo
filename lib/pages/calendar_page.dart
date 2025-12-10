import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final weekdayOfFirstDay = firstDayOfMonth.weekday;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMM().format(now)),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
        ),
        itemCount: daysInMonth + weekdayOfFirstDay - 1,
        itemBuilder: (context, index) {
          if (index < weekdayOfFirstDay - 1) {
            return const SizedBox.shrink(); // Empty space before the 1st day
          }
          final day = index - weekdayOfFirstDay + 2;
          return Card(
            color: Theme.of(context).colorScheme.surface,
            child: InkWell(
              onTap: () {
                // Show summary for the day
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(day.toString()),
                  // Placeholders for mood, whisper, and photo count
                  const Icon(Icons.favorite_border, size: 12),
                  const Icon(Icons.chat_bubble_outline, size: 12),
                  const Icon(Icons.photo_camera, size: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
