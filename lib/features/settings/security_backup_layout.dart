import 'package:flutter/material.dart';
import 'package:glow/widgets/back_button.dart';

/// Lock interval options for the dropdown
const List<({int value, String label})> _lockIntervalOptions = <({int value, String label})>[
  (value: 0, label: 'Immediate'),
  (value: 30, label: '30 seconds'),
  (value: 120, label: '2 minutes'),
  (value: 300, label: '5 minutes'),
  (value: 600, label: '10 minutes'),
  (value: 1800, label: '30 minutes'),
  (value: 3600, label: '1 hour'),
];

/// Pure presentation widget for Security & Backup screen
class SecurityBackupLayout extends StatelessWidget {
  final bool isPinEnabled;
  final bool isBiometricsEnabled;
  final bool isBiometricsAvailable;
  final String biometricType;
  final bool isWalletVerified;
  final ValueChanged<bool> onTogglePin;
  final VoidCallback onChangePin;
  final ValueChanged<bool> onToggleBiometrics;
  final VoidCallback onBackupPhrase;
  final int lockInterval;
  final ValueChanged<double> onLockIntervalChanged;

  const SecurityBackupLayout({
    required this.isPinEnabled,
    required this.isBiometricsEnabled,
    required this.isBiometricsAvailable,
    required this.biometricType,
    required this.isWalletVerified,
    required this.onTogglePin,
    required this.onChangePin,
    required this.onToggleBiometrics,
    required this.onBackupPhrase,
    required this.lockInterval,
    required this.onLockIntervalChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Security & Backup')),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            if (isPinEnabled) ...<Widget>[
              SwitchListTile(
                title: const Text('Deactivate PIN'),
                value: true,
                onChanged: onTogglePin,
              ),
              const Divider(),
              ListTile(
                title: const Text('Change PIN'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: onChangePin,
              ),
              if (isPinEnabled) ...<Widget>[
                const Divider(),
                ListTile(
                  title: const Text('Lock Automatically'),
                  trailing: DropdownButton<int>(
                    isDense: true,
                    value: lockInterval,
                    underline: const SizedBox.shrink(),
                    dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                    iconEnabledColor: Colors.white,
                    onChanged: (int? value) {
                      if (value != null) {
                        onLockIntervalChanged(value.toDouble());
                      }
                    },
                    items: _lockIntervalOptions.map((({int value, String label}) option) {
                      return DropdownMenuItem<int>(value: option.value, child: Text(option.label));
                    }).toList(),
                  ),
                ),
              ],
              if (isBiometricsAvailable) ...<Widget>[
                const Divider(),
                SwitchListTile(
                  title: Text('Enable $biometricType'),
                  value: isBiometricsEnabled,
                  onChanged: onToggleBiometrics,
                ),
              ],
            ] else
              ListTile(
                title: const Text('Create PIN'),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => onTogglePin(true),
              ),
            const Divider(),
            ListTile(
              title: Text(isWalletVerified ? 'Display Backup Phrase' : 'Verify Backup Phrase'),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: onBackupPhrase,
            ),
          ],
        ),
      ),
    );
  }
}
