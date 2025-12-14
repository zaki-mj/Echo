import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/settings_model.dart';
import '../services/firebase_service.dart';

class PairingPage extends StatefulWidget {
  const PairingPage({super.key});

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  Gender? _selectedGender;
  final TextEditingController _pairCodeController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isCreatingPair = false;
  bool _isJoiningPair = false;

  @override
  void dispose() {
    _pairCodeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _createPair() async {
    if (_selectedGender == null || _nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select gender and enter nickname')),
      );
      return;
    }

    setState(() => _isCreatingPair = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUserId = appProvider.currentUserId;
      final firebaseService = FirebaseService();

      if (currentUserId == null || currentUserId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not signed in. Please try again.')),
          );
        }
        return;
      }

      // Generate a simple pair code (last 6 chars of user ID, or pad if shorter)
      String pairCode;
      if (currentUserId.length >= 6) {
        pairCode = currentUserId.substring(currentUserId.length - 6).toUpperCase();
      } else {
        // If user ID is shorter, pad it or use the full ID
        pairCode = currentUserId.toUpperCase().padRight(6, 'X');
      }
      final pairId = 'pair_$pairCode';

      // Create settings based on gender
      final settings = SettingsModel(
        pairId: pairId,
        maleUserId: _selectedGender == Gender.male ? currentUserId : '',
        femaleUserId: _selectedGender == Gender.female ? currentUserId : '',
        maleNickname: _selectedGender == Gender.male
            ? _nicknameController.text.trim()
            : 'Partner',
        femaleNickname: _selectedGender == Gender.female
            ? _nicknameController.text.trim()
            : 'Partner',
        meetingDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      debugPrint('Creating pair with ID: $pairId');
      debugPrint('Settings: ${settings.toMap()}');
      
      try {
        await firebaseService.saveSettings(settings);
        debugPrint('Settings saved to Firebase');
        
        // Wait a bit for Firestore to propagate and retry loading if needed
        SettingsModel? loadedSettings;
        for (int i = 0; i < 3; i++) {
          await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
          loadedSettings = await firebaseService.getSettings(pairId);
          if (loadedSettings != null) {
            debugPrint('Settings loaded successfully on attempt ${i + 1}');
            break;
          }
        }
        
        if (loadedSettings == null) {
          throw Exception('Failed to load settings after saving');
        }
        
        await appProvider.setPairId(pairId);
        debugPrint('Pair ID set in app provider');
      } catch (e, stackTrace) {
        debugPrint('Error during pair creation: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pair created! Share this code: $pairCode'),
            duration: const Duration(seconds: 5),
          ),
        );
        // Small delay to ensure settings are loaded
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingPair = false);
      }
    }
  }

  Future<void> _joinPair() async {
    if (_selectedGender == null ||
        _pairCodeController.text.trim().isEmpty ||
        _nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isJoiningPair = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUserId = appProvider.currentUserId;
      final firebaseService = FirebaseService();

      if (currentUserId == null) return;

      final pairCode = _pairCodeController.text.trim().toUpperCase();
      final pairId = 'pair_$pairCode';

      // Load existing settings
      final existingSettings = await firebaseService.getSettings(pairId);

      if (existingSettings == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pair code not found')),
          );
        }
        return;
      }

      // Check if opposite gender slot is available
      final isMale = _selectedGender == Gender.male;
      if (isMale && existingSettings.maleUserId.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Male slot already taken')),
          );
        }
        return;
      }
      if (!isMale && existingSettings.femaleUserId.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Female slot already taken')),
          );
        }
        return;
      }

      // Update settings with new user
      final updatedSettings = existingSettings.copyWith(
        maleUserId: isMale ? currentUserId : existingSettings.maleUserId,
        femaleUserId: !isMale ? currentUserId : existingSettings.femaleUserId,
        maleNickname: isMale
            ? _nicknameController.text.trim()
            : existingSettings.maleNickname,
        femaleNickname: !isMale
            ? _nicknameController.text.trim()
            : existingSettings.femaleNickname,
      );

      await firebaseService.saveSettings(updatedSettings);
      await appProvider.setPairId(pairId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully paired!')),
        );
        // Small delay to ensure settings are loaded
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoiningPair = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final accentColor = appProvider.accentColor;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pair Devices'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Connect Your Eternal Bond',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your gender and connect with your partner',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Gender Selection
                Text(
                  'Your Gender',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderCard(
                        context: context,
                        gender: Gender.male,
                        label: 'Male',
                        icon: Icons.male,
                        accentColor: accentColor,
                        isSelected: _selectedGender == Gender.male,
                        onTap: () => setState(() => _selectedGender = Gender.male),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGenderCard(
                        context: context,
                        gender: Gender.female,
                        label: 'Female',
                        icon: Icons.female,
                        accentColor: accentColor,
                        isSelected: _selectedGender == Gender.female,
                        onTap: () => setState(() => _selectedGender = Gender.female),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nickname
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Nickname',
                    hintText: 'e.g., Dracula or Mina',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Join Existing Pair
                Text(
                  'Join Existing Pair',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pairCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pair Code',
                    hintText: 'Enter 6-digit code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),

                // Join Button
                ElevatedButton.icon(
                  onPressed: _isJoiningPair ? null : _joinPair,
                  icon: _isJoiningPair
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: Text(_isJoiningPair ? 'Joining...' : 'Join Pair'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Create New Pair Button
                OutlinedButton.icon(
                  onPressed: _isCreatingPair ? null : _createPair,
                  icon: _isCreatingPair
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(_isCreatingPair ? 'Creating...' : 'Create New Pair'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor),
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

  Widget _buildGenderCard({
    required BuildContext context,
    required Gender gender,
    required String label,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.2)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? accentColor : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accentColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

