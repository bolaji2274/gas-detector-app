// ==================== SETTINGS_SCREEN.DART ====================
// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionTitle(context, 'Account'),
          _buildAccountSection(context, authService),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionTitle(context, 'Notifications'),
          _buildNotificationSettings(context),

          const SizedBox(height: 24),

          // Device Settings
          _buildSectionTitle(context, 'Device Settings'),
          _buildDeviceSettings(context),

          const SizedBox(height: 24),

          // About Section
          _buildSectionTitle(context, 'About'),
          _buildAboutSection(context),

          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionTitle(context, 'Danger Zone',
              color: AppTheme.errorColor),
          _buildDangerZone(context, authService),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color ?? AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AuthService authService) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            subtitle: Text(authService.user?.displayName ?? 'User'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to profile editing
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(authService.user?.email ?? ''),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showChangePasswordDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts on your device'),
            value: true,
            onChanged: (value) {
              // Update notification settings
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Email Alerts'),
            subtitle: const Text('Receive alerts via email'),
            value: true,
            onChanged: (value) {
              // Update email settings
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Alert Preferences'),
            subtitle: const Text('Customize when to receive alerts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to alert preferences
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Manage Devices'),
            subtitle: const Text('Add or remove devices'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to device management
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Thresholds'),
            subtitle: const Text('Configure gas detection thresholds'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThresholdsDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Gas Detector',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.science,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, AuthService authService) {
    return Card(
      color: AppTheme.errorColor.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.delete, color: AppTheme.errorColor),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        subtitle: const Text('Permanently delete your account and all data'),
        onTap: () async {
          final confirm = await Helpers.showConfirmDialog(
            context,
            title: 'Delete Account',
            message:
                'This action cannot be undone. All your data will be permanently deleted.',
            confirmText: 'Delete',
          );

          if (confirm && context.mounted) {
            // Show password dialog for confirmation
            Helpers.showSnackBar(
              context,
              'Account deletion requires password confirmation',
            );
          }
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                Helpers.showSnackBar(
                  context,
                  'Passwords do not match',
                  isError: true,
                );
                return;
              }

              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final success = await authService.changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                Helpers.showSnackBar(
                  context,
                  success
                      ? 'Password changed successfully'
                      : 'Failed to change password',
                  isError: !success,
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showThresholdsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gas Thresholds'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LPG Thresholds (PPM)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Warning'),
                keyboardType: TextInputType.number,
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Danger'),
                keyboardType: TextInputType.number,
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Critical'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Text(
                'CO Thresholds (PPM)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Warning'),
                keyboardType: TextInputType.number,
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Danger'),
                keyboardType: TextInputType.number,
              ),
              const TextField(
                decoration: InputDecoration(labelText: 'Critical'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save thresholds
              Navigator.pop(context);
              Helpers.showSnackBar(context, 'Thresholds updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
