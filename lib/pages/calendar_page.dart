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

  bool _isMeetingDate(DateTime date, SettingsModel settings) {
    return date.month == settings.meetingDate.month &&
        date.day == settings.meetingDate.day;
  }

  // Convert weekday to Sunday-first (7 = Sunday, 1 = Monday, etc.)
  int _getSundayFirstWeekday(DateTime date) {
    int weekday = date.weekday;
    // Convert: Mon=1, Tue=2, ..., Sun=7 to Sun=0, Mon=1, ..., Sat=6
    return weekday == 7 ? 0 : weekday;
  }

  void _showDayDetails(DateTime date) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final settings = appProvider.settings;
    if (settings == null) return;
    
    final dayData = _dayDataMap[date];
    final isBirthday = _isBirthday(date, settings);
    final isMeetingDate = _isMeetingDate(date, settings);
    final accentColor = appProvider.accentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (isMeetingDate)
              Icon(Icons.favorite, color: accentColor, size: 20),
            if (isBirthday)
              Icon(Icons.cake, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(DateFormat('MMMM d, y').format(date)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMeetingDate)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: accentColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Night Bloods Crossed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            if (isBirthday)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake, color: accentColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Birthday',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            if (dayData != null) ...[
              if (dayData.user1Mood != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${settings.user1Nickname} Mood: ${dayData.user1Mood!.mood}'),
                ),
              if (dayData.user2Mood != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${settings.user2Nickname} Mood: ${dayData.user2Mood!.mood}'),
                ),
              if (dayData.whisperCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Whispers: ${dayData.whisperCount}'),
                ),
            ] else
              const Text('No data for this day'),
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
        final firstDayWeekday = _getSundayFirstWeekday(firstDayOfMonth);
        final daysInMonth = lastDayOfMonth.day;

        // Generate year and month lists
        final currentYear = DateTime.now().year;
        final years = List.generate(50, (index) => currentYear - 25 + index);
        final months = List.generate(12, (index) => index + 1);
        final monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];

        return Column(
          children: [
            // Month/Year Selection Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous month button
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
                  
                  // Month dropdown
                  DropdownButton<int>(
                    value: _selectedMonth.month,
                    items: months.map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(monthNames[month - 1]),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            value,
                          );
                        });
                        _loadMonthData();
                      }
                    },
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  
                  // Year dropdown
                  DropdownButton<int>(
                    value: _selectedMonth.year,
                    items: years.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = DateTime(
                            value,
                            _selectedMonth.month,
                          );
                        });
                        _loadMonthData();
                      }
                    },
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  
                  // Next month button
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
            
            // Weekday headers (Sunday first)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
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
                itemCount: firstDayWeekday + daysInMonth,
                itemBuilder: (context, index) {
                  // Empty cells for days before the first day of month
                  if (index < firstDayWeekday) {
                    return const SizedBox.shrink();
                  }

                  final day = index - firstDayWeekday + 1;
                  final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                  final dayData = _dayDataMap[date];
                  final isBirthday = _isBirthday(date, settings);
                  final isMeetingDate = _isMeetingDate(date, settings);
                  final isToday = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;

                  // Determine background color based on priority
                  Color? backgroundColor;
                  Color borderColor = Colors.transparent;
                  double borderWidth = 1;
                  
                  if (isMeetingDate) {
                    // Meeting date gets special highlight
                    backgroundColor = accentColor.withOpacity(0.4);
                    borderColor = accentColor;
                    borderWidth = 3;
                  } else if (isBirthday) {
                    // Birthday gets accent border
                    backgroundColor = accentColor.withOpacity(0.2);
                    borderColor = accentColor;
                    borderWidth = 2;
                  } else if (isToday) {
                    // Today gets subtle highlight
                    backgroundColor = accentColor.withOpacity(0.15);
                  } else {
                    backgroundColor = Theme.of(context).cardColor;
                  }

                  return GestureDetector(
                    onTap: () => _showDayDetails(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: Border.all(
                          color: borderColor,
                          width: borderWidth,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Day number with special indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isMeetingDate)
                                Icon(
                                  Icons.favorite,
                                  size: 10,
                                  color: accentColor,
                                ),
                              if (isBirthday)
                                Icon(
                                  Icons.cake,
                                  size: 10,
                                  color: accentColor,
                                ),
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontWeight: isToday || isMeetingDate || isBirthday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isMeetingDate || isBirthday
                                      ? accentColor
                                      : (isToday
                                          ? accentColor
                                          : null),
                                  fontSize: isMeetingDate || isBirthday ? 16 : 14,
                                ),
                              ),
                            ],
                          ),
                          if (dayData != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (dayData.user1Mood != null)
                                  Icon(Icons.mood, size: 10, color: accentColor),
                                if (dayData.user2Mood != null)
                                  Icon(Icons.mood, size: 10, color: Colors.purple),
                              ],
                            ),
                            if (dayData.whisperCount > 0)
                              Text(
                                '${dayData.whisperCount}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: accentColor.withOpacity(0.8),
                                ),
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

