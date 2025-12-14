import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/gothic_theme.dart';
import '../utils/data_export.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _user1NicknameController;
  late TextEditingController _user2NicknameController;
  DateTime? _user1Birthdate;
  DateTime? _user2Birthdate;
  DateTime? _meetingDate;
  int _accentColorIndex = 0;
  bool _isDarkMode = true;
  bool _touchOfNightEnabled = true;
  bool _sealedLettersEnabled = true;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final settings = appProvider.settings;

    if (settings != null) {
      _user1NicknameController = TextEditingController(text: settings.user1Nickname);
      _user2NicknameController = TextEditingController(text: settings.user2Nickname);
      _user1Birthdate = settings.user1Birthdate;
      _user2Birthdate = settings.user2Birthdate;
      _meetingDate = settings.meetingDate;
      _accentColorIndex = settings.accentColorIndex;
      _isDarkMode = settings.isDarkMode;
      _touchOfNightEnabled = settings.touchOfNightEnabled;
      _sealedLettersEnabled = settings.sealedLettersEnabled;
    } else {
      _user1NicknameController = TextEditingController();
      _user2NicknameController = TextEditingController();
      _meetingDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _user1NicknameController.dispose();
    _user2NicknameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime) onDateSelected,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_meetingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meeting date')),
      );
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentSettings = appProvider.settings;
    final currentUserId = appProvider.currentUserId;

    if (currentSettings == null || currentUserId == null) return;

    // Determine if current user is user1 or user2
    String? user2Id = currentSettings.user2Id;
    if (currentSettings.user1Id != currentUserId && user2Id.isEmpty) {
      // Current user is joining as user2
      user2Id = currentUserId;
    }

    final newSettings = currentSettings.copyWith(
      user2Id: user2Id,
      user1Nickname: _user1NicknameController.text.trim(),
      user2Nickname: _user2NicknameController.text.trim(),
      user1Birthdate: _user1Birthdate,
      user2Birthdate: _user2Birthdate,
      meetingDate: _meetingDate!,
      accentColorIndex: _accentColorIndex,
      isDarkMode: _isDarkMode,
      touchOfNightEnabled: _touchOfNightEnabled,
      sealedLettersEnabled: _sealedLettersEnabled,
    );

    await appProvider.updateSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSettings,
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Nicknames
                TextFormField(
                  controller: _user1NicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Nickname',
                    hintText: 'e.g., Dracula',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a nickname';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _user2NicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Partner\'s Nickname',
                    hintText: 'e.g., Mina',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a nickname';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Birthdates
                ListTile(
                  title: const Text('Your Birthdate'),
                  subtitle: Text(
                    _user1Birthdate != null ? DateFormat('MMMM d, y').format(_user1Birthdate!) : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(
                    context,
                    (date) => setState(() => _user1Birthdate = date),
                  ),
                ),
                ListTile(
                  title: const Text('Partner\'s Birthdate'),
                  subtitle: Text(
                    _user2Birthdate != null ? DateFormat('MMMM d, y').format(_user2Birthdate!) : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(
                    context,
                    (date) => setState(() => _user2Birthdate = date),
                  ),
                ),
                const SizedBox(height: 16),

                // Meeting Date
                ListTile(
                  title: const Text('Meeting Date'),
                  subtitle: Text(
                    _meetingDate != null ? DateFormat('MMMM d, y').format(_meetingDate!) : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(
                    context,
                    (date) => setState(() => _meetingDate = date),
                  ),
                ),
                const SizedBox(height: 24),

                // Accent Color
                const Text(
                  'Accent Color',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(8, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _accentColorIndex = index),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: GothicTheme.accentColors[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _accentColorIndex == index ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Dark Mode Toggle
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: _isDarkMode,
                  onChanged: (value) => setState(() => _isDarkMode = value),
                ),

                // Touch of Night
                SwitchListTile(
                  title: const Text('Touch of Night (Haptics)'),
                  value: _touchOfNightEnabled,
                  onChanged: (value) => setState(() => _touchOfNightEnabled = value),
                ),

                // Sealed Letters
                SwitchListTile(
                  title: const Text('Sealed Letters'),
                  value: _sealedLettersEnabled,
                  onChanged: (value) => setState(() => _sealedLettersEnabled = value),
                ),

                const SizedBox(height: 32),

                // Export Data
                ElevatedButton.icon(
                  onPressed: () async {
                    await DataExport.exportAllData(context, appProvider);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export Crypt (JSON/TXT)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
