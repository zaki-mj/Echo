import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../models/mood_model.dart';
import '../models/settings_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _selectedMonth = DateTime.now();
  Map<DateTime, DayData> _dayDataMap = {};

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  void _loadMonthData() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final settings = appProvider.settings;
    final currentUserId = appProvider.currentUserId;

    if (settings == null || currentUserId == null) return;

    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    _firebaseService
        .watchMoodsForDateRange(startOfMonth, endOfMonth)
        .listen((moods) {
      // Group moods by date
      final Map<DateTime, DayData> newMap = {};
      
      for (final mood in moods) {
        final date = DateTime(
          mood.timestamp.year,
          mood.timestamp.month,
          mood.timestamp.day,
        );
        
        if (!newMap.containsKey(date)) {
          newMap[date] = DayData(
            date: date,
            user1Mood: null,
            user2Mood: null,
            whisperCount: 0,
          );
        }
        
        final dayData = newMap[date]!;
        final partnerId = settings.getPartnerId(currentUserId);
        if (mood.userId == currentUserId) {
          newMap[date] = dayData.copyWith(user1Mood: mood);
        } else if (partnerId != null && mood.userId == partnerId) {
          newMap[date] = dayData.copyWith(user2Mood: mood);
        }
      }

      // Load whisper counts
      final partnerId = settings.getPartnerId(currentUserId) ?? '';
      _firebaseService
          .watchWhispers(currentUserId, partnerId)
          .listen((whispers) {
        final Map<DateTime, int> whisperCounts = {};
        
        for (final whisper in whispers) {
          final date = DateTime(
            whisper.timestamp.year,
            whisper.timestamp.month,
            whisper.timestamp.day,
          );
          whisperCounts[date] = (whisperCounts[date] ?? 0) + 1;
        }

        for (final entry in newMap.entries) {
          final count = whisperCounts[entry.key] ?? 0;
          newMap[entry.key] = entry.value.copyWith(whisperCount: count);
        }

        setState(() {
          _dayDataMap = newMap;
        });
      });
    });
  }

  bool _isBirthday(DateTime date, SettingsModel settings) {
    if (settings.user1Birthdate != null) {
      if (date.month == settings.user1Birthdate!.month &&
          date.day == settings.user1Birthdate!.day) {
        return true;
      }
    }
    if (settings.user2Birthdate != null) {
      if (date.month == settings.user2Birthdate!.month &&
          date.day == settings.user2Birthdate!.day) {
        return true;
      }
    }
    return false;
  }

  void _showDayDetails(DateTime date) {
    final dayData = _dayDataMap[date];
    if (dayData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MMMM d, y').format(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dayData.user1Mood != null)
              Text('Mood: ${dayData.user1Mood!.mood}'),
            if (dayData.user2Mood != null)
              Text('Partner Mood: ${dayData.user2Mood!.mood}'),
            const SizedBox(height: 8),
            Text('Whispers: ${dayData.whisperCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final settings = appProvider.settings;
        final accentColor = appProvider.accentColor;

        if (settings == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
        final firstDayWeekday = firstDayOfMonth.weekday;
        final daysInMonth = lastDayOfMonth.day;

        return Column(
          children: [
            // Month Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                      _loadMonthData();
                    },
                  ),
                  Text(
                    DateFormat('MMMM y').format(_selectedMonth),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                      _loadMonthData();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: firstDayWeekday - 1 + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayWeekday - 1) {
                return const SizedBox.shrink();
              }

              final day = index - (firstDayWeekday - 1) + 1;
              final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
              final dayData = _dayDataMap[date];
              final isBirthday = _isBirthday(date, settings);
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () => _showDayDetails(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? accentColor.withOpacity(0.3)
                        : Theme.of(context).cardColor,
                    border: Border.all(
                      color: isBirthday
                          ? accentColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isBirthday ? accentColor : null,
                        ),
                      ),
                      if (dayData != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (dayData.user1Mood != null)
                              Icon(Icons.bathtub, size: 12, color: accentColor),
                            if (dayData.user2Mood != null)
                              Icon(Icons.bathtub, size: 12, color: Colors.purple),
                          ],
                        ),
                        if (dayData.whisperCount > 0)
                          Text(
                            '${dayData.whisperCount}',
                            style: const TextStyle(fontSize: 10),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
              ),
            ),
          ],
        );
      },
    );
  }
}

class DayData {
  final DateTime date;
  final MoodModel? user1Mood;
  final MoodModel? user2Mood;
  final int whisperCount;

  DayData({
    required this.date,
    this.user1Mood,
    this.user2Mood,
    this.whisperCount = 0,
  });

  DayData copyWith({
    MoodModel? user1Mood,
    MoodModel? user2Mood,
    int? whisperCount,
  }) {
    return DayData(
      date: date,
      user1Mood: user1Mood ?? this.user1Mood,
      user2Mood: user2Mood ?? this.user2Mood,
      whisperCount: whisperCount ?? this.whisperCount,
    );
  }
}

