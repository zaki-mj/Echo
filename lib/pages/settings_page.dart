import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/gothic_theme.dart';
import '../utils/data_export.dart';
import '../models/settings_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _maleNicknameController;
  late TextEditingController _femaleNicknameController;
  DateTime? _maleBirthdate;
  DateTime? _femaleBirthdate;
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
    final currentUserId = appProvider.currentUserId;

    if (settings != null && currentUserId != null) {
      _maleNicknameController = TextEditingController(text: settings.maleNickname);
      _femaleNicknameController = TextEditingController(text: settings.femaleNickname);
      _maleBirthdate = settings.maleBirthdate;
      _femaleBirthdate = settings.femaleBirthdate;
      _meetingDate = settings.meetingDate;
      _accentColorIndex = settings.accentColorIndex;
      _isDarkMode = settings.isDarkMode;
      _touchOfNightEnabled = settings.touchOfNightEnabled;
      _sealedLettersEnabled = settings.sealedLettersEnabled;
    } else {
      _maleNicknameController = TextEditingController();
      _femaleNicknameController = TextEditingController();
      _meetingDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _maleNicknameController.dispose();
    _femaleNicknameController.dispose();
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

    final newSettings = currentSettings.copyWith(
      maleNickname: _maleNicknameController.text.trim(),
      femaleNickname: _femaleNicknameController.text.trim(),
      maleBirthdate: _maleBirthdate,
      femaleBirthdate: _femaleBirthdate,
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
                // Pair Code Display
                if (settings.pairId.isNotEmpty)
                  Card(
                    color: accentColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.vpn_key, color: accentColor),
                              const SizedBox(width: 8),
                              Text(
                                'Pair Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            settings.pairId.replaceFirst('pair_', '').toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share this code with your partner to connect',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Nicknames (Gender-based)
                TextFormField(
                  controller: _maleNicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Male Nickname',
                    hintText: 'e.g., Dracula',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.male),
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
                  controller: _femaleNicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Female Nickname',
                    hintText: 'e.g., Mina',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.female),
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
                  title: const Text('Male Birthdate'),
                  subtitle: Text(
                    _maleBirthdate != null ? DateFormat('MMMM d, y').format(_maleBirthdate!) : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(
                    context,
                    (date) => setState(() => _maleBirthdate = date),
                  ),
                ),
                ListTile(
                  title: const Text('Female Birthdate'),
                  subtitle: Text(
                    _femaleBirthdate != null ? DateFormat('MMMM d, y').format(_femaleBirthdate!) : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(
                    context,
                    (date) => setState(() => _femaleBirthdate = date),
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
