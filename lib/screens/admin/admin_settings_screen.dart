import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api.dart';
import '../login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _systemAlerts = true;
  bool _smsNotifications = false;
  bool _darkMode = false;
  bool _biometricLogin = false;
  String _language = 'English';
  String _currency = 'LKR (₹)';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailNotifications = prefs.getBool('emailNotifications') ?? true;
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _systemAlerts = prefs.getBool('systemAlerts') ?? true;
      _smsNotifications = prefs.getBool('smsNotifications') ?? false;
      _darkMode = prefs.getBool('darkMode') ?? false;
      _biometricLogin = prefs.getBool('biometricLogin') ?? false;
      _language = prefs.getString('language') ?? 'English';
      _currency = prefs.getString('currency') ?? 'LKR (₹)';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    await showDialog(
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
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
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text) {
                Navigator.pop(context);
                _showSnackBar('Password changed successfully');
              } else {
                _showSnackBar('Passwords do not match');
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Api.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            children: [
              _buildSwitchTile(
                'Enable Notifications',
                'Receive push notifications',
                _pushNotifications,
                (value) {
                  setState(() => _pushNotifications = value);
                  _saveSetting('pushNotifications', value);
                },
              ),
              _buildSwitchTile(
                'System Alerts',
                'Critical system notifications',
                _systemAlerts,
                (value) {
                  setState(() => _systemAlerts = value);
                  _saveSetting('systemAlerts', value);
                },
              ),
              _buildSwitchTile(
                'Email Notifications',
                'Receive email updates',
                _emailNotifications,
                (value) {
                  setState(() => _emailNotifications = value);
                  _saveSetting('emailNotifications', value);
                },
              ),
              _buildSwitchTile(
                'SMS Notifications',
                'Receive SMS updates',
                _smsNotifications,
                (value) {
                  setState(() => _smsNotifications = value);
                  _saveSetting('smsNotifications', value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            children: [
              _buildSwitchTile(
                'Dark Mode',
                'Enable dark theme',
                _darkMode,
                (value) {
                  setState(() => _darkMode = value);
                  _saveSetting('darkMode', value);
                },
              ),
              _buildSelectTile(
                'Language',
                'App language',
                _language,
                () => _showLanguageDialog(),
              ),
              _buildSelectTile(
                'Currency',
                'Display currency',
                _currency,
                () => _showCurrencyDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.security_outlined,
            title: 'Security & Privacy',
            children: [
              _buildSwitchTile(
                'Biometric Login',
                'Use fingerprint or face ID',
                _biometricLogin,
                (value) {
                  setState(() => _biometricLogin = value);
                  _saveSetting('biometricLogin', value);
                },
              ),
              _buildActionTile(
                'Change Password',
                'Update your password',
                Icons.chevron_right,
                _changePassword,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.admin_panel_settings_outlined,
            title: 'System Management',
            children: [
              _buildActionTile(
                'Database Backup',
                'Backup system data',
                Icons.chevron_right,
                () => _showSnackBar('Database Backup'),
              ),
              _buildActionTile(
                'System Logs',
                'View system activity logs',
                Icons.chevron_right,
                () => _showSnackBar('System Logs'),
              ),
              _buildActionTile(
                'User Management',
                'Manage user accounts',
                Icons.chevron_right,
                () => _showSnackBar('User Management'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.info_outline,
            title: 'About',
            children: [
              _buildActionTile(
                'Terms of Service',
                '',
                Icons.chevron_right,
                () => _showSnackBar('Terms of Service'),
              ),
              _buildActionTile(
                'Privacy Policy',
                '',
                Icons.chevron_right,
                () => _showSnackBar('Privacy Policy'),
              ),
              _buildActionTile(
                'Help & Support',
                '',
                Icons.chevron_right,
                () => _showSnackBar('Help & Support'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildSelectTile(
    String title,
    String subtitle,
    String value,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData trailingIcon,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
          : null,
      trailing: Icon(trailingIcon, size: 20, color: Colors.grey[600]),
      onTap: onTap,
    );
  }

  Future<void> _showLanguageDialog() async {
    final languages = ['English', 'Sinhala', 'Tamil'];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return ListTile(
              title: Text(lang),
              leading: Radio<String>(
                value: lang,
                groupValue: _language,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              onTap: () => Navigator.pop(context, lang),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() => _language = selected);
      _saveSetting('language', selected);
    }
  }

  Future<void> _showCurrencyDialog() async {
    final currencies = ['LKR (₹)', 'USD (\$)', 'EUR (€)'];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((curr) {
            return ListTile(
              title: Text(curr),
              leading: Radio<String>(
                value: curr,
                groupValue: _currency,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              onTap: () => Navigator.pop(context, curr),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() => _currency = selected);
      _saveSetting('currency', selected);
    }
  }
}
